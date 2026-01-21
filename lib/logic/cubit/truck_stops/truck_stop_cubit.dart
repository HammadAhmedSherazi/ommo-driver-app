import 'dart:async';
import 'dart:developer' show log;
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/services.dart';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:here_sdk/core.dart';
import 'package:here_sdk/mapview.dart'
    show
        MapMeasureKind,
        MapMeasure,
        MapImage,
        ImageFormat,
        MapMarker,
        MapCameraListener,
        MapCameraState;
import 'package:here_sdk/search.dart'
    show
        PlaceCategory,
        Place,
        CategoryQueryArea,
        CategoryQuery,
        SearchOptions,
        SearchEngine,
        SearchError;
import 'package:ommo/app/views/app_view.dart';
import 'package:ommo/data/response/get_data.dart';
import 'package:ommo/logic/cubit/truck_navigation/truck_navigation_cubit.dart';
import 'package:ommo/logic/cubit/truck_stops/truck_stops_state.dart';

class TruckStopCubit extends Cubit<TruckStopsState> {
  TruckStopCubit() : super(TruckStopsState());

  final _searchEngine = SearchEngine();
  Map<String, MapMarker> _placeMarkersMap = {}; // place.id -> marker
  Map<String, String> _markerBrandMap = {}; // place.id -> brand
  Map<String, Place> placeDataMap = {}; // place.id -> Place
  Map<String, String> placesLogoMap = {}; // place.id -> Image
  bool _isFirstTimeMarkersLoaded = true;
  MapCameraListener? _cameraListener;
  Timer? _cameraDebounceTimer;
  static const double _coordinatePrecision =
      0.01; // ~1km precision for duplicate detection

  static const List<Map<String, String?>> defaultBrands = [
    {'name': "Love's", 'icon': 'assets/images/image 2.png'},
    {'name': "Pilot/Flying J", 'icon': 'assets/images/Circle.png'},
    {'name': "TA Petro", 'icon': 'assets/images/ta_petro_icon.png'},
    {'name': "KwikTrip", 'icon': 'assets/images/kwik_trip_icon.png'},
    {'name': "Other", 'icon': 'assets/images/Icon (27).png'},
  ];

  /// Get default brand names (excluding "Other")
  List<String> get _defaultBrandNames => defaultBrands
      .where((brand) => brand['name'] != 'Other')
      .map((brand) => brand['name']!)
      .toList();

  // final List <>
  void searchByCategory(String placeTypeName) {
    final mapController = navigatorKey.currentContext
        ?.read<TruckNavigationCubit>()
        .state
        .mapController;

    if (mapController == null) {
      emit(
        state.copyWith(
          categorySearchResults: FutureData.error(
            "Unable to search: map controller not available",
          ),
          availableBrands: [], // Clear brands on error
          selectedBrands: [], // Clear selected brands
        ),
      );
      return;
    }

    // Get map camera's target coordinates (focused location)
    final cameraState = mapController.camera.state;
    final centerCoordinates = cameraState.targetCoordinates;

    // Clear previous search results and reset searched coordinates if it's a new category
    if (state.currentPlaceType != placeTypeName) {
      emit(
        state.copyWith(
          categorySearchResults: FutureData<List<Place>>.loading(),
          availableBrands: [],
          selectedBrands: [],
          searchedCoordinates: {},
          currentPlaceType: placeTypeName,
        ),
      );
      _clearPlaceMarkers();
      _isFirstTimeMarkersLoaded = true;
    }

    // Setup camera listener if not already active
    if (!state.isCameraListenerActive) {
      _setupCameraListener(placeTypeName);
    }

    // Perform search with map-focused location
    _performSearch(placeTypeName, centerCoordinates, isAppending: false);
  }

  /// Setup camera listener to track map movements
  void _setupCameraListener(String placeTypeName) {
    final mapController = navigatorKey.currentContext
        ?.read<TruckNavigationCubit>()
        .state
        .mapController;

    if (mapController == null) return;

    // Remove existing listener if any
    _removeCameraListener();

    // Create new listener
    _cameraListener = MapCameraListener((MapCameraState mapState) {
      final targetCoords = mapState.targetCoordinates;

      // Debounce camera changes to avoid too many API calls
      _cameraDebounceTimer?.cancel();
      _cameraDebounceTimer = Timer(const Duration(milliseconds: 800), () {
        // Check if this area has already been searched
        final coordKey = _getCoordinateKey(targetCoords);
        if (state.searchedCoordinates.contains(coordKey)) {
          log("Area already searched, skipping: $coordKey");
          return;
        }

        // Append new results for this location
        _performSearch(placeTypeName, targetCoords, isAppending: true);
      });
    });

    // Add listener to camera
    mapController.camera.addListener(_cameraListener!);

    emit(state.copyWith(isCameraListenerActive: true));
  }

  /// Remove camera listener
  void _removeCameraListener() {
    _cameraDebounceTimer?.cancel();
    _cameraDebounceTimer = null;

    final mapController = navigatorKey.currentContext
        ?.read<TruckNavigationCubit>()
        .state
        .mapController;

    if (mapController != null && _cameraListener != null) {
      mapController.camera.removeListener(_cameraListener!);
      _cameraListener = null;
    }
  }

  /// Generate a coordinate key for duplicate detection (rounded to ~1km precision)
  String _getCoordinateKey(GeoCoordinates coords) {
    final roundedLat =
        (coords.latitude / _coordinatePrecision).round() * _coordinatePrecision;
    final roundedLng =
        (coords.longitude / _coordinatePrecision).round() *
        _coordinatePrecision;
    return '${roundedLat.toStringAsFixed(4)}_${roundedLng.toStringAsFixed(4)}';
  }

  /// Perform search at given coordinates (can append to existing results)
  void _performSearch(
    String placeTypeName,
    GeoCoordinates centerCoordinates, {
    required bool isAppending,
  }) {
    // Get category codes for the place type
    List<String> categoryCodes = _getCategoryCodesForPlaceType(placeTypeName);
    if (categoryCodes.isEmpty) {
      if (!isAppending) {
        emit(
          state.copyWith(
            categorySearchResults: FutureData.error(
              "No category found for: $placeTypeName",
            ),
            availableBrands: [],
            selectedBrands: [],
          ),
        );
      }
      return;
    }

    // Mark this coordinate as searched
    final coordKey = _getCoordinateKey(centerCoordinates);
    final updatedSearchedCoords = Set<String>.from(state.searchedCoordinates)
      ..add(coordKey);

    // Emit loading state only if not appending
    if (!isAppending) {
      emit(
        state.copyWith(
          categorySearchResults: FutureData<List<Place>>.loading(),
          searchedCoordinates: updatedSearchedCoords,
        ),
      );
    }

    // Create category list
    List<PlaceCategory> placeCategoryList = categoryCodes
        .map((code) => PlaceCategory(code))
        .toList();

    // Create search area around map-focused location
    const int halfWidthInMeters = 50000; // 50km radius

    // Create a small line segment near the center to form a valid polyline
    const double offsetInDegrees = 0.01; // Small offset (~1km)
    final GeoCoordinates secondPoint = GeoCoordinates(
      centerCoordinates.latitude + offsetInDegrees,
      centerCoordinates.longitude,
    );

    // Create corridor with at least 2 points
    final List<GeoCoordinates> routeVertices = [centerCoordinates, secondPoint];
    final GeoCorridor routeCorridor = GeoCorridor(
      routeVertices,
      halfWidthInMeters,
    );

    CategoryQueryArea categoryQueryArea =
        CategoryQueryArea.withCorridorAndCenter(
          routeCorridor,
          centerCoordinates,
        );

    // Create category query
    CategoryQuery categoryQuery = CategoryQuery.withCategoriesInArea(
      placeCategoryList,
      categoryQueryArea,
    );

    // Set search options
    SearchOptions searchOptions = SearchOptions();
    searchOptions.languageCode = LanguageCode.enUs;
    searchOptions.maxItems = 50;

    // For truck-related categories, set custom option
    if (placeTypeName.toLowerCase().contains('truck') ||
        placeTypeName.toLowerCase().contains('weight') ||
        placeTypeName.toLowerCase().contains('rest area')) {
      _searchEngine.setCustomOption("show", "truck");
    }

    // Perform search
    _searchEngine.searchByCategory(categoryQuery, searchOptions, (
      SearchError? searchError,
      List<Place>? places,
    ) {
      if (searchError != null) {
        log("Category search error: $searchError");
        if (!isAppending) {
          emit(
            state.copyWith(
              categorySearchResults: FutureData.error(searchError.toString()),
            ),
          );
        }
        return;
      }

      if (places != null && places.isNotEmpty) {
        // Get existing places if appending
        final existingPlaces =
            isAppending && state.categorySearchResults?.data != null
            ? List<Place>.from(state.categorySearchResults!.data!)
            : <Place>[];

        // Filter out duplicates by place ID
        final existingPlaceIds = existingPlaces.map((p) => p.id).toSet();
        final newPlaces = places
            .where((p) => !existingPlaceIds.contains(p.id))
            .toList();

        // Combine existing and new places
        final allPlaces = [...existingPlaces, ...newPlaces];

        // Determine which brands have results
        final Set<String> brandsWithResults = {};
        bool hasOtherResults = false;

        for (final place in allPlaces) {
          final brand = getBrandFromPlace(place);
          if (brand != null) {
            if (_defaultBrandNames.contains(brand)) {
              brandsWithResults.add(brand);
            } else {
              hasOtherResults = true;
            }
          }
        }

        // Always show all default brands + "Other" if there are non-matching places
        final List<String> availableBrands = List<String>.from(
          _defaultBrandNames,
        );
        if (hasOtherResults) {
          availableBrands.add("Other");
        }

        // Auto-select brands that have results, including "Other" if it has results
        // Only update selected brands if not appending (to preserve user selection)
        final selectedBrands = isAppending
            ? (state.selectedBrands ?? [])
            : List<String>.from(brandsWithResults);
        if (!isAppending && hasOtherResults) {
          selectedBrands.add("Other");
        }

        emit(
          state.copyWith(
            categorySearchResults: FutureData.completed(allPlaces),
            availableBrands: availableBrands,
            selectedBrands: selectedBrands,
            searchedCoordinates: updatedSearchedCoords,
          ),
        );

        // Add markers to map (only new places if appending)
        final placesToAdd = isAppending ? newPlaces : allPlaces;
        if (placesToAdd.isNotEmpty) {
          _addPlaceMarkersToMap(placesToAdd).catchError((error) {
            log("Error adding place markers: $error");
          });
        }
      } else {
        // Update searched coordinates even if no results
        emit(state.copyWith(searchedCoordinates: updatedSearchedCoords));

        // Only show empty state if not appending
        if (!isAppending) {
          emit(
            state.copyWith(
              categorySearchResults: FutureData.completed([]),
              availableBrands: List<String>.from(_defaultBrandNames),
              selectedBrands: [],
            ),
          );
          _clearPlaceMarkers();
        }
      }
    });
  }

  /// Toggle brand selection (add/remove from selected brands list)
  void toggleBrand(String brand) {
    final currentSelected = state.selectedBrands ?? [];
    final List<String> newSelected;

    if (currentSelected.contains(brand)) {
      // Remove brand from selection
      newSelected = List<String>.from(currentSelected)..remove(brand);
    } else {
      // Add brand to selection
      newSelected = List<String>.from(currentSelected)..add(brand);
    }

    emit(state.copyWith(selectedBrands: newSelected));

    // Update markers based on new selection
    final places = state.categorySearchResults?.data;
    if (places != null && places.isNotEmpty) {
      _addPlaceMarkersToMap(places).catchError((error) {
        log("Error updating place markers: $error");
      });
    }
  }

  /// Clear brand filter and available brands
  void clearBrandFilter() {
    _removeCameraListener();
    emit(
      state.copyWith(
        availableBrands: [],
        selectedBrands: [],
        isCameraListenerActive: false,
        searchedCoordinates: {},
        currentPlaceType: null,
      ),
    );
    _clearPlaceMarkers();
  }

  /// Get categorized brand name from place title - returns default brand name or "Other"
  /// Made public so UI can use it for filtering
  String? getBrandFromPlace(Place place) {
    final title = place.title.trim();
    if (title.isEmpty) return "Other";

    final titleLower = title.toLowerCase();

    // Check against default brands (check longer/more specific brands first)
    // Love's
    if (titleLower.contains("love's") || titleLower.contains("loves")) {
      return "Love's";
    }

    // Pilot/Flying J (check both variations)
    if (titleLower.contains("pilot") ||
        titleLower.contains("flying j") ||
        titleLower.contains("flyingj") ||
        titleLower.contains("pilot travel center") ||
        titleLower.contains("flying j travel plaza")) {
      return "Pilot/Flying J";
    }

    // TA Petro (check both TA and Petro)
    if (titleLower.contains("ta petro") ||
        titleLower.contains("ta/petro") ||
        titleLower.contains("travelcenters of america") ||
        (titleLower.contains("ta") && titleLower.contains("petro")) ||
        titleLower.contains("petro") ||
        (titleLower.contains("travel") &&
            titleLower.contains("center") &&
            (titleLower.contains("ta") || titleLower.contains("america")))) {
      return "TA Petro";
    }

    // KwikTrip
    if (titleLower.contains("kwiktrip") ||
        titleLower.contains("kwik trip") ||
        titleLower.contains("kwiktrip")) {
      return "KwikTrip";
    }

    // If no match found, return "Other"
    return "Other";
  }

  /// Get brand icon path for a brand name
  String? _getBrandIconPath(String brandName) {
    for (final brand in defaultBrands) {
      if (brand['name'] == brandName) {
        return brand['icon'];
      }
    }
    return null;
  }

  /// Get deterministic color for a brand from predefined brand colors
  ui.Color _getBrandColor(String brand) {
    // List of predefined brand colors from AppColorTheme
    final brandColors = [
      ui.Color(0xFFFF9029), // orange
      ui.Color(0xFF4676F6), // blue
      ui.Color(0xFFFFC300), // yellowLight
      ui.Color(0xFFD0082C), // red4
    ];

    // Use brand name hash to deterministically select a color
    final hash = brand.hashCode;
    final colorIndex = hash.abs() % brandColors.length;

    return brandColors[colorIndex];
  }

  /// Create a marker with brand image embedded in pin shape
  Future<MapImage> _createMarkerWithBrandImage(
    String assetPath, [
    double opacity = 1.0,
  ]) async {
    const double pinHeight = 140.0;
    const double pinWidth = 100.0;
    const double circleRadius = 42.0;
    const double circleCenterY = 42.0;
    const double circleCenterX = pinWidth / 2;
    const double imageSize = 60.0; // Size of brand image inside pin

    final ui.PictureRecorder recorder = ui.PictureRecorder();
    final ui.Canvas canvas = ui.Canvas(recorder);

    // Load brand image
    final ByteData? imageData = await rootBundle.load(assetPath);
    if (imageData == null) {
      throw Exception("Failed to load brand image");
    }

    final codec = await ui.instantiateImageCodec(
      imageData.buffer.asUint8List(),
    );
    final frame = await codec.getNextFrame();
    final brandImage = frame.image;

    // Draw white pin shape (outer circle + triangle) - always full opacity
    final ui.Paint whitePaint = ui.Paint()
      ..color = ui.Color(0xFFFFFFFF)
      ..style = ui.PaintingStyle.fill;

    // Draw outer white circle
    canvas.drawCircle(
      ui.Offset(circleCenterX, circleCenterY),
      circleRadius,
      whitePaint,
    );

    // Draw white triangle (pin point)
    final ui.Path trianglePath = ui.Path()
      ..moveTo(circleCenterX - 15, circleCenterY + circleRadius)
      ..lineTo(circleCenterX + 15, circleCenterY + circleRadius)
      ..lineTo(circleCenterX, pinHeight - 5)
      ..close();
    canvas.drawPath(trianglePath, whitePaint);

    // Draw brand image inside circle
    final srcRect = ui.Rect.fromLTWH(
      0,
      0,
      brandImage.width.toDouble(),
      brandImage.height.toDouble(),
    );
    final dstRect = ui.Rect.fromCenter(
      center: ui.Offset(circleCenterX, circleCenterY),
      width: imageSize,
      height: imageSize,
    );

    // Apply opacity to image
    final imagePaint = ui.Paint()
      ..colorFilter = ui.ColorFilter.mode(
        ui.Color.fromARGB((255 * opacity).toInt(), 255, 255, 255),
        ui.BlendMode.modulate,
      );

    canvas.drawImageRect(brandImage, srcRect, dstRect, imagePaint);

    // Draw small circle at pin tip
    final ui.Paint tipPaint = ui.Paint()
      ..color = ui.Color(0xFF000000).withOpacity(opacity)
      ..style = ui.PaintingStyle.fill;

    canvas.drawCircle(ui.Offset(circleCenterX, pinHeight - 7), 7, tipPaint);

    final ui.Picture picture = recorder.endRecording();
    final ui.Image image = await picture.toImage(
      pinWidth.toInt(),
      pinHeight.toInt(),
    );
    final ByteData? byteData = await image.toByteData(
      format: ui.ImageByteFormat.png,
    );

    return MapImage.withPixelDataAndImageFormat(
      byteData!.buffer.asUint8List(),
      ImageFormat.png,
    );
  }

  /// Create a parking pin style marker with brand first letter
  Future<MapImage> _createBrandMarkerImage(
    String brandLetter,
    ui.Color backgroundColor, [
    double opacity = 1.0,
  ]) async {
    const double pinHeight = 140.0; // Increased from 100.0
    const double pinWidth = 100.0; // Increased from 70.0
    const double circleRadius = 42.0; // Increased from 30.0
    const double circleCenterY = 42.0; // Increased from 30.0
    const double circleCenterX = pinWidth / 2;

    final ui.PictureRecorder recorder = ui.PictureRecorder();
    final ui.Canvas canvas = ui.Canvas(recorder);

    // Draw white pin shape (outer circle + triangle) - always full opacity
    final ui.Paint whitePaint = ui.Paint()
      ..color = ui.Color(0xFFFFFFFF)
      ..style = ui.PaintingStyle.fill;

    // Draw outer white circle
    canvas.drawCircle(
      ui.Offset(circleCenterX, circleCenterY),
      circleRadius,
      whitePaint,
    );

    // Draw white triangle (pin point)
    final ui.Path trianglePath = ui.Path()
      ..moveTo(circleCenterX - 15, circleCenterY + circleRadius)
      ..lineTo(circleCenterX + 15, circleCenterY + circleRadius)
      ..lineTo(circleCenterX, pinHeight - 5)
      ..close();
    canvas.drawPath(trianglePath, whitePaint);

    // Draw colored inner circle (brand background) with opacity
    final ui.Paint brandPaint = ui.Paint()
      ..color = ui.Color.fromARGB(
        (backgroundColor.alpha * opacity).toInt(),
        backgroundColor.red,
        backgroundColor.green,
        backgroundColor.blue,
      )
      ..style = ui.PaintingStyle.fill;

    canvas.drawCircle(
      ui.Offset(circleCenterX, circleCenterY),
      circleRadius - 5,
      brandPaint,
    );

    // Draw brand letter with opacity
    final ui.ParagraphBuilder paragraphBuilder = ui.ParagraphBuilder(
      ui.ParagraphStyle(
        textAlign: ui.TextAlign.center,
        fontSize: 40.0, // Increased from 28.0
        fontWeight: ui.FontWeight.bold,
      ),
    );

    paragraphBuilder.pushStyle(
      ui.TextStyle(
        color: ui.Color.fromARGB((255 * opacity).toInt(), 255, 255, 255),
      ),
    );
    paragraphBuilder.addText(brandLetter.toUpperCase());

    final ui.Paragraph paragraph = paragraphBuilder.build();
    paragraph.layout(ui.ParagraphConstraints(width: pinWidth));

    canvas.drawParagraph(
      paragraph,
      ui.Offset(0, circleCenterY - paragraph.height / 2),
    );

    // Draw small circle at pin tip - always full opacity
    final ui.Paint tipPaint = ui.Paint()
      ..color = backgroundColor
      ..style = ui.PaintingStyle.fill;

    canvas.drawCircle(ui.Offset(circleCenterX, pinHeight - 7), 7, tipPaint);

    final ui.Picture picture = recorder.endRecording();
    final ui.Image image = await picture.toImage(
      pinWidth.toInt(),
      pinHeight.toInt(),
    );
    final ByteData? byteData = await image.toByteData(
      format: ui.ImageByteFormat.png,
    );

    return MapImage.withPixelDataAndImageFormat(
      byteData!.buffer.asUint8List(),
      ImageFormat.png,
    );
  }

  /// Add place markers to map based on selected brands
  Future<void> _addPlaceMarkersToMap(List<Place> places) async {
    final selectedBrands = state.selectedBrands ?? [];
    final mapController = navigatorKey.currentContext
        ?.read<TruckNavigationCubit>()
        .state
        .mapController;
    if (mapController == null) return;

    final List<GeoCoordinates> markerCoordinates = [];
    final bool shouldZoom = _isFirstTimeMarkersLoaded;

    // Update or create markers for all places
    for (final place in places) {
      final brand = getBrandFromPlace(place);
      if (brand == null) continue;

      final coordinates = place.geoCoordinates;
      if (coordinates == null) continue;

      final isSelected = selectedBrands.contains(brand);
      final opacity = isSelected ? 1.0 : 0.5;

      // Check if marker already exists
      if (_placeMarkersMap.containsKey(place.id)) {
        // Update existing marker by removing and recreating with new opacity
        final existingMarker = _placeMarkersMap[place.id]!;
        mapController.mapScene.removeMapMarker(existingMarker);
        _placeMarkersMap.remove(place.id);
      }

      if (isSelected) {
        MapImage markerImage;

        // Check if brand has an icon (default brands)
        final iconPath = _getBrandIconPath(brand);
        if (iconPath != null) {
          // Use brand image for default brands
          markerImage = await _createMarkerWithBrandImage(iconPath, opacity);
        } else {
          // Use first letter for "Other" or brands without icons
          final brandLetter = brand.isNotEmpty ? brand[0] : '?';
          final brandColor = _getBrandColor(brand);
          markerImage = await _createBrandMarkerImage(
            brandLetter,
            brandColor,
            opacity,
          );
        }

        final marker = MapMarker(coordinates, markerImage);

        // Set anchor point to bottom center of pin
        marker.anchor = Anchor2D.withHorizontalAndVertical(0.5, 1.0);

        // Add metadata for tap handling
        final metadata = Metadata();
        metadata.setString("place_id", place.id);
        metadata.setString("place_title", place.title);
        marker.metadata = metadata;

        mapController.mapScene.addMapMarker(marker);
        _placeMarkersMap[place.id] = marker;
        _markerBrandMap[place.id] = brand;
        placeDataMap[place.id] = place; // Store place data
        placesLogoMap[place.id] = iconPath ?? '';
        markerCoordinates.add(coordinates);
      }
    }

    // Zoom out to show all markers only on first load
    if (shouldZoom && markerCoordinates.isNotEmpty) {
      _zoomToShowAllMarkers(markerCoordinates);
      _isFirstTimeMarkersLoaded = false;
    }
  }

  /// Zoom map to show all markers
  void _zoomToShowAllMarkers(List<GeoCoordinates> coordinates) {
    final mapController = navigatorKey.currentContext
        ?.read<TruckNavigationCubit>()
        .state
        .mapController;
    if (mapController == null || coordinates.isEmpty) return;

    if (coordinates.length == 1) {
      // Single marker - zoom to it
      navigatorKey.currentContext
          ?.read<TruckNavigationCubit>()
          .focusOnCurrentLocation(distanceInMeters: 5000);
      return;
    }

    // Calculate bounding box
    double minLat = coordinates.first.latitude;
    double maxLat = coordinates.first.latitude;
    double minLng = coordinates.first.longitude;
    double maxLng = coordinates.first.longitude;

    for (final coord in coordinates) {
      if (coord.latitude < minLat) minLat = coord.latitude;
      if (coord.latitude > maxLat) maxLat = coord.latitude;
      if (coord.longitude < minLng) minLng = coord.longitude;
      if (coord.longitude > maxLng) maxLng = coord.longitude;
    }

    // Calculate center
    final centerLat = (minLat + maxLat) / 2;
    final centerLng = (minLng + maxLng) / 2;
    final center = GeoCoordinates(centerLat, centerLng);

    // Calculate distance to cover all markers with padding
    final latDistance = navigatorKey.currentContext
        ?.read<TruckNavigationCubit>()
        .calculateDistanceInMeters(minLat, centerLng, maxLat, centerLng);
    final lngDistance = navigatorKey.currentContext
        ?.read<TruckNavigationCubit>()
        .calculateDistanceInMeters(centerLat, minLng, centerLat, maxLng);

    // Use the larger distance and add more padding for better zoom out
    final maxDistance =
        (latDistance! > lngDistance! ? latDistance : lngDistance) * 10.0;

    // Zoom to show all markers with more zoom out
    final mapMeasure = MapMeasure(MapMeasureKind.distanceInMeters, maxDistance);
    mapController.camera.lookAtPointWithMeasure(center, mapMeasure);
  }

  /// Clear all place markers from map
  void _clearPlaceMarkers() {
    final mapController = navigatorKey.currentContext
        ?.read<TruckNavigationCubit>()
        .state
        .mapController;
    if (mapController == null) return;

    for (final marker in _placeMarkersMap.values) {
      mapController.mapScene.removeMapMarker(marker);
    }
    _placeMarkersMap.clear();
    _markerBrandMap.clear();
    placeDataMap.clear();
    placesLogoMap.clear();
    _isFirstTimeMarkersLoaded = true; // Reset flag when clearing
  }

  /// Show business overview in modal bottom sheet
  void showBusinessOverviewModal(Place place) {
    emit(
      state.copyWith(selectedTruckStop: place, showBusinessOverviewModal: true),
    );
  }

  /// Clear selected truck stop
  void clearSelectedTruckStop() {
    emit(
      state.copyWith(
        selectedTruckStop: 'null',
        showBusinessOverviewModal: false,
      ),
    );
  }

  void clearAllTruckStops() {
    _removeCameraListener();
    _clearPlaceMarkers();
    emit(
      state.copyWith(
        selectedBrands: [],
        categorySearchResults: FutureData<List<Place>>.initial(),
        selectedTruckStop: 'null',
        showBusinessOverviewModal: false,
        isCameraListenerActive: false,
        searchedCoordinates: {},
        currentPlaceType: null,
      ),
    );
  }

  void createTripWithBusinessOverview() {
    final Place? place = state.selectedTruckStop;
    if (place == null) return;
    navigatorKey.currentContext
        ?.read<TruckNavigationCubit>()
        .calculateRouteWithBusinessOverview(place);
    clearSelectedTruckStop();
  }

  /// Map place type names to HERE SDK category codes
  List<String> _getCategoryCodesForPlaceType(String placeTypeName) {
    final name = placeTypeName.toLowerCase();

    // Truck stops - use truck stop plaza category
    if (name.contains('truck stop')) {
      return ['700-7900-0132']; // Truck stop plaza
    }

    // Parking - use truck parking category
    if (name.contains('parking')) {
      return ['700-7900-0131']; // Truck parking
    }

    // Rest areas
    if (name.contains('rest area')) {
      return [
        '700-7900-0133', // Rest area
        '700-7900-0131', // Also include truck parking
      ];
    }

    // Weight stations / Scales
    if (name.contains('weight station') || name.contains('scales')) {
      return ['700-7900-0134']; // Weigh station
    }

    // Fuel
    if (name.contains('fuel')) {
      return [
        '700-7600-0000', // Gas station / Fuel
        '700-7900-0132', // Also truck stops which have fuel
      ];
    }

    // Truck Washes
    if (name.contains('wash')) {
      return ['700-7900-0135']; // Truck wash
    }

    // Restaurant
    if (name.contains('restaurant')) {
      return ['100-1000-0000']; // Restaurant
    }

    // Hotel
    if (name.contains('hotel')) {
      return [PlaceCategory.accommodation];
    }

    // Store
    if (name.contains('store')) {
      return [PlaceCategory.shopping];
    }

    // Return empty list if no match
    return [];
  }
}
