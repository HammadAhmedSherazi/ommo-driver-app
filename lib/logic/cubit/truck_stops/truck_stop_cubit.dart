import 'dart:async';
import 'dart:developer' show log;
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
import 'package:ommo/home/view/truck_navigation/truck_navigation_static_details.dart';
import 'package:ommo/logic/cubit/truck_navigation/truck_navigation_cubit.dart';
import 'package:ommo/logic/cubit/truck_stops/truck_stops_state.dart';
import 'package:ommo/utils/extension/place_extension.dart';

/// Tabs that use HERE category search; used to drop POIs whose title clearly
/// belongs on another tab (e.g. "…Wash" miscategorized as truck stop plaza).
enum _PlaceTabKind {
  truckStop,
  weightStation,
  parking,
  restArea,
  fuel,
  truckWash,
  restaurant,
  hotel,
  gym,
  store,
}

class TruckStopCubit extends Cubit<TruckStopsState> {
  TruckStopCubit()
    : super(
        TruckStopsState(
          categoriesSearchState: List.generate(
            TruckNavigationStaticDetails.placeTypes.length,
            (i) => PlaceCategoryTruckStopsState(
              categorySearchResults: FutureData.loading(),
              availableBrands: [],
              selectedBrands: [],
              placeCategory: TruckNavigationStaticDetails.placeTypes[i]['name'],
            ),
          ),
        ),
      );

  final _searchEngine = SearchEngine();

  Map<String, MapMarker> _placeMarkersMap = {}; // place.id -> marker
  Map<String, String> _markerBrandMap = {}; // place.id -> brand
  Map<String, Place> placeDataMap = {}; // place.id -> Place
  Map<String, String> placesLogoMap = {}; // place.id -> Image
  String? _selectedPlaceId;
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

  /// Map pin / list row logo for Pilot-branded stops (title says Pilot, not Flying J).
  static const String pilotTruckStopLogoAsset = 'assets/images/pilot_logo1.png';

  /// Map pin / list row logo for Flying J–branded stops. Replace asset with official artwork if needed.
  static const String flyingJTruckStopLogoAsset =
      'assets/images/flying_j_logo.png';

  /// Get default brand names (excluding "Other")
  List<String> get _defaultBrandNames => defaultBrands
      .where((brand) => brand['name'] != 'Other')
      .map((brand) => brand['name']!)
      .toList();

  /// Get category state for a specific place type
  PlaceCategoryTruckStopsState? _getCategoryState(String placeTypeName) {
    try {
      return state.categoriesSearchState.firstWhere(
        (category) => category.placeCategory == placeTypeName,
      );
    } catch (e) {
      return null;
    }
  }

  /// Get index of category state for a specific place type
  int? _getCategoryIndex(String placeTypeName) {
    try {
      return state.categoriesSearchState.indexWhere(
        (category) => category.placeCategory == placeTypeName,
      );
    } catch (e) {
      return null;
    }
  }

  /// Update category state for a specific place type
  void _updateCategoryState(
    String placeTypeName,
    PlaceCategoryTruckStopsState Function(PlaceCategoryTruckStopsState) update,
  ) {
    final categoryIndex = _getCategoryIndex(placeTypeName);
    if (categoryIndex == null || categoryIndex < 0) return;

    final updatedCategories = List<PlaceCategoryTruckStopsState>.from(
      state.categoriesSearchState,
    );
    updatedCategories[categoryIndex] = update(updatedCategories[categoryIndex]);

    emit(state.copyWith(categoriesSearchState: updatedCategories));
  }

  /// Get current category state (for the currently selected place type)
  PlaceCategoryTruckStopsState? get _currentCategoryState {
    if (state.currentPlaceType == null) return null;
    return _getCategoryState(state.currentPlaceType!);
  }

  // final List <>
  void searchByCategory(String placeTypeName) {
    final mapController = navigatorKey.currentContext
        ?.read<TruckNavigationCubit>()
        .state
        .mapController;

    if (mapController == null) {
      _updateCategoryState(
        placeTypeName,
        (category) => category.copyWith(
          categorySearchResults: FutureData.error(
            "Unable to search: map controller not available",
          ),
          availableBrands: [],
          selectedBrands: [],
        ),
      );
      return;
    }

    // Get map camera's target coordinates (focused location)
    final cameraState = mapController.camera.state;
    final centerCoordinates = cameraState.targetCoordinates;

    // Get cached category state
    final categoryState = _getCategoryState(placeTypeName);
    final hasCachedResults =
        categoryState != null &&
        categoryState.categorySearchResults != null &&
        categoryState.categorySearchResults!.status == Status.success;

    // If switching to a new place type, clear markers and reset zoom flag
    final isSwitchingCategory = state.currentPlaceType != placeTypeName;
    if (isSwitchingCategory) {
      _clearPlaceMarkers();
      _isFirstTimeMarkersLoaded = true;
    }

    // Update current place type
    emit(state.copyWith(currentPlaceType: placeTypeName));

    // If we have cached results, show them immediately
    if (hasCachedResults) {
      final cachedPlaces = categoryState.categorySearchResults!.data;
      if (cachedPlaces != null && cachedPlaces.isNotEmpty) {
        // Load markers for cached results based on current category's selected brands
        _addPlaceMarkersToMap(cachedPlaces).catchError((error) {
          log("Error adding cached place markers: $error");
        });
      }
    } else {
      // No cached results, show loading state
      _updateCategoryState(
        placeTypeName,
        (category) => category.copyWith(
          categorySearchResults: FutureData<List<Place>>.loading(),
        ),
      );
    }

    // Setup camera listener if not already active
    if (!state.isCameraListenerActive) {
      _setupCameraListener(placeTypeName);
    }

    // Perform fresh search in background (will update cache and state)
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
        final currentPlaceType = state.currentPlaceType ?? placeTypeName;
        _performSearch(currentPlaceType, targetCoords, isAppending: true);
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
        _updateCategoryState(
          placeTypeName,
          (category) => category.copyWith(
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
      emit(state.copyWith(searchedCoordinates: updatedSearchedCoords));
      _updateCategoryState(
        placeTypeName,
        (category) => category.copyWith(
          categorySearchResults: FutureData<List<Place>>.loading(),
        ),
      );
    } else {
      emit(state.copyWith(searchedCoordinates: updatedSearchedCoords));
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
          _updateCategoryState(
            placeTypeName,
            (category) => category.copyWith(
              categorySearchResults: FutureData.error(
                searchError == SearchError.noResultsFound
                    ? "No results found"
                    : searchError.toString(),
              ),
            ),
          );
        }
        return;
      }

      // Get current category state
      final categoryState = _getCategoryState(placeTypeName);
      if (categoryState == null) return;

      if (places != null && places.isNotEmpty) {
        // When showing "Truck stops", exclude weigh station/scale-only places
        // (they have their own "Scales" category)
        List<Place> filteredPlaces = places;
        if (placeTypeName.toLowerCase().contains('truck stop')) {
          filteredPlaces = filteredPlaces
              .where((p) => !_isWeighStationOnly(p))
              .toList();
        }

        // filteredPlaces = _filterPlacesByPrimaryCategoryCode(
        //   placeTypeName,
        //   filteredPlaces,
        // );

        filteredPlaces = _filterPlacesByCrossCategoryTitle(
          placeTypeName,
          filteredPlaces,
        );

        // Get existing places if appending
        final existingPlaces =
            isAppending && categoryState.categorySearchResults?.data != null
            ? List<Place>.from(categoryState.categorySearchResults!.data!)
            : <Place>[];

        // Filter out duplicates by place ID
        final existingPlaceIds = existingPlaces.map((p) => p.id).toSet();
        final newPlaces = filteredPlaces
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
        // Preserve user's selected brands from cache if available, otherwise auto-select
        final List<String> selectedBrands = isAppending
            ? List<String>.from(categoryState.selectedBrands ?? [])
            : () {
                // Check if we have cached selected brands for this place type
                final cachedBrands = categoryState.selectedBrands;
                if (cachedBrands != null && cachedBrands.isNotEmpty) {
                  // Keep only cached brands that are available in new results
                  final filteredBrands = cachedBrands
                      .where(
                        (brand) =>
                            brandsWithResults.contains(brand) ||
                            (brand == "Other" && hasOtherResults),
                      )
                      .toList();
                  // If no cached brands match, fall back to auto-selecting all available brands
                  if (filteredBrands.isEmpty) {
                    final autoSelected = List<String>.from(brandsWithResults);
                    if (hasOtherResults) {
                      autoSelected.add("Other");
                    }
                    return autoSelected;
                  }
                  return filteredBrands;
                } else {
                  // No cached brands, auto-select all brands with results
                  final autoSelected = List<String>.from(brandsWithResults);
                  if (hasOtherResults) {
                    autoSelected.add("Other");
                  }
                  return autoSelected;
                }
              }();

        _updateCategoryState(
          placeTypeName,
          (category) => category.copyWith(
            categorySearchResults: FutureData.completed(allPlaces),
            availableBrands: availableBrands,
            selectedBrands: selectedBrands,
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
        // Only show empty state if not appending
        if (!isAppending) {
          _updateCategoryState(
            placeTypeName,
            (category) => category.copyWith(
              categorySearchResults: FutureData.completed(<Place>[]),
              availableBrands: List<String>.from(_defaultBrandNames),
              selectedBrands: category.selectedBrands ?? [],
            ),
          );
          _clearPlaceMarkers();
        }
      }
    });
  }

  /// Toggle brand selection (add/remove from selected brands list)
  void toggleBrand(String brand) {
    if (state.currentPlaceType == null) return;

    final categoryState = _getCategoryState(state.currentPlaceType!);
    if (categoryState == null) return;

    final currentSelected = categoryState.selectedBrands ?? [];
    final List<String> newSelected;

    if (currentSelected.contains(brand)) {
      // Remove brand from selection
      newSelected = List<String>.from(currentSelected)..remove(brand);
    } else {
      // Add brand to selection
      newSelected = List<String>.from(currentSelected)..add(brand);
    }

    _updateCategoryState(
      state.currentPlaceType!,
      (category) => category.copyWith(selectedBrands: newSelected),
    );

    // Refresh all markers for current category based on new selection
    // This ensures markers are shown/hidden correctly when brands are toggled
    _refreshAllMarkers();
  }

  /// Clear brand filter and available brands
  // void clearBrandFilter() {
  //   _removeCameraListener();
  //   emit(
  //     state.copyWith(
  //       availableBrands: [],
  //       selectedBrands: [],
  //       isCameraListenerActive: false,
  //       searchedCoordinates: {},
  //       currentPlaceType: null,
  //     ),
  //   );
  //   _clearPlaceMarkers();
  // }

  void clearState() {
    _removeCameraListener();
    _clearAllPlaceData();
    emit(
      TruckStopsState(
        currentPlaceType: 'null', // Reset to null when clearing
        categoriesSearchState: List.generate(
          TruckNavigationStaticDetails.stationList.length,
          (i) => PlaceCategoryTruckStopsState(
            categorySearchResults: FutureData.loading(),
            availableBrands: [],
            selectedBrands:
                [], // Reset selectedBrands only when clearing state completely
            placeCategory: TruckNavigationStaticDetails.stationList[i]['name'],
          ),
        ),
      ),
    );
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

    // Pilot / Flying J (one filter key; marker icon picks Pilot vs Flying J from title)
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

  /// Logo asset for map markers and [placesLogoMap] — Pilot vs Flying J from [place.title].
  String? getBrandMarkerIconPath(Place place) {
    final brand = getBrandFromPlace(place);
    if (brand == null) return null;
    if (brand != 'Pilot/Flying J') {
      return _getBrandIconPath(brand);
    }
    final t = place.title.toLowerCase();
    if (t.contains('flying j') || t.contains('flyingj')) {
      return flyingJTruckStopLogoAsset;
    }
    return pilotTruckStopLogoAsset;
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
    double scale = 1.0,
  ]) async {
    final double pinHeight = 115.0 * scale;
    final double pinWidth = 100.0 * scale;
    final double circleRadius = 42.0 * scale;
    final double circleCenterY = 42.0 * scale;
    final double circleCenterX = pinWidth / 2;
    final double imageSize = 72.0 * scale; // Size of brand image inside pin

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

    // Draw white triangle (pin point) - overlapping into circle
    final double triangleStartY = circleCenterY + circleRadius - 8.0 * scale;
    final double triangleWidth = 20.0 * scale;
    final ui.Path trianglePath = ui.Path()
      ..moveTo(circleCenterX - triangleWidth, triangleStartY)
      ..lineTo(circleCenterX + triangleWidth, triangleStartY)
      ..lineTo(circleCenterX, pinHeight - 12)
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
        ui.Color.fromARGB(255, 255, 255, 255),
        ui.BlendMode.modulate,
      );

    canvas.drawImageRect(brandImage, srcRect, dstRect, imagePaint);

    // Draw small circle at pin tip
    final ui.Paint tipPaint = ui.Paint()
      ..color = ui.Color(0xFF000000)
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
    double scale = 1.0,
  ]) async {
    final double pinHeight = 115.0 * scale;
    final double pinWidth = 100.0 * scale;
    final double circleRadius = 42.0 * scale;
    final double circleCenterY = 42.0 * scale;
    final double circleCenterX = pinWidth / 2;

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

    // Draw white triangle (pin point) - overlapping into circle
    final double triangleStartY = circleCenterY + circleRadius - 8.0 * scale;
    final double triangleWidth = 20.0 * scale;
    final ui.Path trianglePath = ui.Path()
      ..moveTo(circleCenterX - triangleWidth, triangleStartY)
      ..lineTo(circleCenterX + triangleWidth, triangleStartY)
      ..lineTo(circleCenterX, pinHeight - 12)
      ..close();
    canvas.drawPath(trianglePath, whitePaint);

    // Draw colored inner circle (brand background) with opacity
    final ui.Paint brandPaint = ui.Paint()
      ..color = ui.Color.fromARGB(
        backgroundColor.alpha,
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
        fontSize: 40.0 * scale, // Increased from 28.0
        fontWeight: ui.FontWeight.bold,
      ),
    );

    paragraphBuilder.pushStyle(
      ui.TextStyle(color: ui.Color.fromARGB(255, 255, 255, 255)),
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
    final categoryState = _currentCategoryState;
    final selectedBrands = categoryState?.selectedBrands ?? [];
    final mapController = navigatorKey.currentContext
        ?.read<TruckNavigationCubit>()
        .state
        .mapController;
    if (mapController == null) return;

    final List<GeoCoordinates> markerCoordinates = [];
    final bool shouldZoom = _isFirstTimeMarkersLoaded;

    final imageFutures =
        <
          Future<
            ({
              Place place,
              GeoCoordinates coordinates,
              MapImage image,
              String brand,
              bool isPlaceSelected,
              String? iconPath,
            })
          >
        >[];

    // Remove stale markers synchronously; build marker images in parallel
    for (final place in places) {
      final brand = getBrandFromPlace(place);
      if (brand == null) continue;

      final coordinates = place.geoCoordinates;
      if (coordinates == null) continue;

      final isBrandSelected = selectedBrands.contains(brand);
      final isPlaceSelected = place.id == _selectedPlaceId;
      final scale = isPlaceSelected ? 1.3 : 1.0;

      if (_placeMarkersMap.containsKey(place.id)) {
        final existingMarker = _placeMarkersMap[place.id]!;
        mapController.mapScene.removeMapMarker(existingMarker);
        _placeMarkersMap.remove(place.id);
      }

      if (!isBrandSelected) continue;

      final iconPath = getBrandMarkerIconPath(place);
      imageFutures.add(() async {
        final MapImage markerImage;
        if (iconPath != null) {
          markerImage = await _createMarkerWithBrandImage(iconPath, scale);
        } else {
          final brandLetter = brand.isNotEmpty ? brand[0] : '?';
          final brandColor = _getBrandColor(brand);
          markerImage = await _createBrandMarkerImage(
            brandLetter,
            brandColor,
            scale,
          );
        }
        return (
          place: place,
          coordinates: coordinates,
          image: markerImage,
          brand: brand,
          isPlaceSelected: isPlaceSelected,
          iconPath: iconPath,
        );
      }());
    }

    final builtMarkers = await Future.wait(imageFutures);

    for (final item in builtMarkers) {
      final marker = MapMarker(item.coordinates, item.image);

      if (item.isPlaceSelected) {
        marker.drawOrder = 1000;
      }
      marker.anchor = Anchor2D.withHorizontalAndVertical(0.5, 1.0);

      final metadata = Metadata();
      metadata.setString("place_id", item.place.id);
      metadata.setString("place_title", item.place.title);
      marker.metadata = metadata;

      mapController.mapScene.addMapMarker(marker);
      _placeMarkersMap[item.place.id] = marker;
      _markerBrandMap[item.place.id] = item.brand;
      placeDataMap[item.place.id] = item.place;
      placesLogoMap[item.place.id] = item.iconPath ?? '';
      markerCoordinates.add(item.coordinates);
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

  /// Clear all place markers from map (but keep place data for business overview)
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
    // Note: We keep placeDataMap and placesLogoMap so business overview modals can still work
    // They will be updated when new places are added
    _isFirstTimeMarkersLoaded = true; // Reset flag when clearing
  }

  /// Clear all place data (used when completely clearing state)
  void _clearAllPlaceData() {
    _clearPlaceMarkers();
    placeDataMap.clear();
    placesLogoMap.clear();
  }

  /// Show business overview in modal bottom sheet
  void showBusinessOverviewModal(Place place, {bool fromMap = true}) {
    _selectedPlaceId = place.id;

    emit(
      state.copyWith(selectedTruckStop: place, showBusinessOverviewModal: true),
    );
    _refreshAllMarkers();

    if (!fromMap) {
      _focusOnPSelectedlace();
    }
  }

  /// Clear selected truck stop
  void clearSelectedTruckStop() {
    _selectedPlaceId = null;
    emit(
      state.copyWith(
        selectedTruckStop: 'null',
        showBusinessOverviewModal: false,
      ),
    );
    _refreshAllMarkers();
  }

  // focus on selected
  void _focusOnPSelectedlace() {
    final GeoCoordinates? coords = state.selectedTruckStop?.geoCoordinates;
    if (coords == null) return;
    final mapController = navigatorKey.currentContext
        ?.read<TruckNavigationCubit>()
        .state
        .mapController;

    if (mapController == null) return;

    // Nice close zoom level for POI focus
    final mapMeasure = MapMeasure(
      MapMeasureKind.distanceInMeters,
      3000, // 3km view radius (adjust if needed)
    );

    mapController.camera.lookAtPointWithMeasure(coords, mapMeasure);
  }

  void _refreshAllMarkers() {
    final categoryState = _currentCategoryState;
    final places = categoryState?.categorySearchResults?.data;
    final selectedBrands = categoryState?.selectedBrands ?? [];
    final mapController = navigatorKey.currentContext
        ?.read<TruckNavigationCubit>()
        .state
        .mapController;

    if (mapController == null) return;

    // Remove markers for places that are no longer selected
    final markersToRemove = <String>[];
    for (final entry in _placeMarkersMap.entries) {
      final placeId = entry.key;
      final place = placeDataMap[placeId];
      if (place != null) {
        final brand = getBrandFromPlace(place);
        if (brand == null || !selectedBrands.contains(brand)) {
          // This marker should be removed
          mapController.mapScene.removeMapMarker(entry.value);
          markersToRemove.add(placeId);
        }
      }
    }

    // Clean up removed markers
    for (final placeId in markersToRemove) {
      _placeMarkersMap.remove(placeId);
      _markerBrandMap.remove(placeId);
    }

    // Add/update markers for all places in current category
    if (places != null && places.isNotEmpty) {
      _addPlaceMarkersToMap(places);
    }
  }

  void clearAllTruckStops() {
    _removeCameraListener();
    _clearAllPlaceData();
    // Preserve brand filter and place type so they are restored when user returns.
    // Only clear search results and map state; keep selectedBrands and availableBrands per category.
    final resetCategories = state.categoriesSearchState.map((category) {
      return category.copyWith(
        categorySearchResults: FutureData<List<Place>>.initial(),
        // Keep selectedBrands and availableBrands unchanged
      );
    }).toList();
    emit(
      state.copyWith(
        categoriesSearchState: resetCategories,
        selectedTruckStop: 'null',
        showBusinessOverviewModal: false,
        isCameraListenerActive: false,
        searchedCoordinates: {},
        // Keep currentPlaceType so the same tab is restored when user returns
      ),
    );
  }

  void createTripWithBusinessOverview() {
    final Place? place = state.selectedTruckStop;
    if (place == null) return;
    navigatorKey.currentContext
        ?.read<TruckNavigationCubit>()
        .calculateRouteWithBusinessOverview(place.toPlaceDataModel);
    clearSelectedTruckStop();
  }

  /// Weigh station / scale category code (excluded from Truck stops)
  static const String _weighStationCategoryCode = '700-7900-0134';

  /// Truck stop plaza category code
  static const String _truckStopPlazaCategoryCode = '700-7900-0132';

  /// Returns true if this place should be excluded from "Truck stops" list
  /// (show only under Scales). Uses category when available, plus name-based detection.
  bool _isWeighStationOnly(Place place) {
    // Name-based: exclude "Cat Scale" and similar scale-only businesses
    final title = place.title.toLowerCase();
    if (title.contains('cat scale')) return true;
    if (title.contains('weigh station') && !_isKnownTruckStopBrand(place)) {
      return true;
    }

    // Category-based: exclude if place has weigh station category but not truck stop plaza
    try {
      final categories = place.details.categories;
      if (categories.isEmpty) return false;
      bool hasWeighStation = false;
      bool hasTruckStopPlaza = false;
      for (final c in categories) {
        final id = c.id;
        if (id == _weighStationCategoryCode) hasWeighStation = true;
        if (id == _truckStopPlazaCategoryCode) hasTruckStopPlaza = true;
      }
      return hasWeighStation && !hasTruckStopPlaza;
    } catch (_) {
      return false;
    }
  }

  /// True if place is a known truck stop brand (Love's, Pilot, TA, Kwik Trip, etc.)
  bool _isKnownTruckStopBrand(Place place) {
    final brand = getBrandFromPlace(place);
    return brand != null && _defaultBrandNames.contains(brand);
  }

  _PlaceTabKind? _placeTabKindForSearch(String placeTypeName) {
    final n = placeTypeName.toLowerCase();
    if (n.contains('truck stop')) return _PlaceTabKind.truckStop;
    if (n.contains('weight station') || n.contains('scale')) {
      return _PlaceTabKind.weightStation;
    }
    if (n.contains('parking')) return _PlaceTabKind.parking;
    if (n.contains('rest area')) return _PlaceTabKind.restArea;
    if (n.contains('fuel')) return _PlaceTabKind.fuel;
    if (n.contains('wash')) return _PlaceTabKind.truckWash;
    if (n.contains('restaurant')) return _PlaceTabKind.restaurant;
    if (n.contains('hotel')) return _PlaceTabKind.hotel;
    if (n.contains('gym')) return _PlaceTabKind.gym;
    if (n.contains('store')) return _PlaceTabKind.store;
    return null;
  }

  static final List<RegExp> _titleWeightStationPatterns = [
    RegExp(r'\bcat\s+scale\b', caseSensitive: false),
    RegExp(r'\bweigh\s+station\b', caseSensitive: false),
    RegExp(r'\bweight\s+station\b', caseSensitive: false),
    RegExp(r'\bscale\s+house\b', caseSensitive: false),
    RegExp(r'\bscales\b', caseSensitive: false),
  ];

  static final List<RegExp> _titleTruckWashPatterns = [
    RegExp(r'\bwash\b', caseSensitive: false),
    RegExp(r'\bwashing\b', caseSensitive: false),
  ];

  static final List<RegExp> _titleParkingPatterns = [
    RegExp(r'\bparking\b', caseSensitive: false),
    RegExp(r'\bpaddock\b', caseSensitive: false),
  ];

  static final List<RegExp> _titleRestAreaPatterns = [
    RegExp(r'\brest\s+area\b', caseSensitive: false),
    RegExp(r'\brest\s+stop\b', caseSensitive: false),
  ];

  static final List<RegExp> _titleRestaurantPatterns = [
    RegExp(r'\brestaurant\b', caseSensitive: false),
    RegExp(r'\bcafe\b', caseSensitive: false),
    RegExp(r'\bcafé\b', caseSensitive: false),
    RegExp(r'\bdiner\b', caseSensitive: false),
  ];

  static final List<RegExp> _titleHotelPatterns = [
    RegExp(r'\bhotel\b', caseSensitive: false),
    RegExp(r'\bmotel\b', caseSensitive: false),
    RegExp(r'\binns?\b', caseSensitive: false),
  ];

  static final List<RegExp> _titleGymPatterns = [
    RegExp(r'\bgym\b', caseSensitive: false),
    RegExp(r'\bfitness\b', caseSensitive: false),
  ];

  static final List<RegExp> _titleStorePatterns = [
    RegExp(r'\bgrocery\b', caseSensitive: false),
    RegExp(r'\bwalmart\b', caseSensitive: false),
    RegExp(r'\b7-eleven\b', caseSensitive: false),
  ];

  Set<_PlaceTabKind> _tabKindsMatchingTitle(String title) {
    final t = title;
    final kinds = <_PlaceTabKind>{};
    void addIfMatches(List<RegExp> patterns, _PlaceTabKind kind) {
      for (final p in patterns) {
        if (p.hasMatch(t)) {
          kinds.add(kind);
          return;
        }
      }
    }

    addIfMatches(_titleWeightStationPatterns, _PlaceTabKind.weightStation);
    addIfMatches(_titleTruckWashPatterns, _PlaceTabKind.truckWash);
    addIfMatches(_titleParkingPatterns, _PlaceTabKind.parking);
    addIfMatches(_titleRestAreaPatterns, _PlaceTabKind.restArea);
    addIfMatches(_titleRestaurantPatterns, _PlaceTabKind.restaurant);
    addIfMatches(_titleHotelPatterns, _PlaceTabKind.hotel);
    addIfMatches(_titleGymPatterns, _PlaceTabKind.gym);
    addIfMatches(_titleStorePatterns, _PlaceTabKind.store);
    return kinds;
  }

  /// Drops results whose title clearly signals a different browse tab than the
  /// one the user selected (name-based only; complements category codes).
  bool _titleImpliesOtherTabThan(_PlaceTabKind current, String title) {
    final kinds = _tabKindsMatchingTitle(title);
    if (kinds.isEmpty) return false;
    if (kinds.length == 1 && kinds.single == current) return false;
    return kinds.any((k) => k != current);
  }

  List<Place> _filterPlacesByCrossCategoryTitle(
    String placeTypeName,
    List<Place> places,
  ) {
    final current = _placeTabKindForSearch(placeTypeName);
    if (current == null) return places;
    return places
        .where((p) => !_titleImpliesOtherTabThan(current, p.title))
        .toList();
  }

  /// Keeps only places whose **first** HERE category id matches this tab's search
  /// codes (e.g. Shell with primary gas station is hidden under Truck stops).
  List<Place> _filterPlacesByPrimaryCategoryCode(
    String placeTypeName,
    List<Place> places,
  ) {
    final expectedCodes = _getCategoryCodesForPlaceType(placeTypeName);
    if (expectedCodes.isEmpty) return places;
    return places
        .where((p) => _placePrimaryCategoryMatchesSearchCodes(p, expectedCodes))
        .toList();
  }

  /// True when [place]'s primary category equals one of [expectedCodes] or is a
  /// more specific descendant (e.g. accommodation `500` matches `500-5000-…`).
  bool _placePrimaryCategoryMatchesSearchCodes(
    Place place,
    List<String> expectedCodes,
  ) {
    try {
      final categories = place.details.categories;
      if (categories.isEmpty) return false;
      final primaryId = categories.first.id;
      return _categoryIdMatchesSearchCodes(primaryId, expectedCodes);
    } catch (_) {
      return false;
    }
  }

  static bool _categoryIdMatchesSearchCodes(
    String primaryId,
    List<String> expectedCodes,
  ) {
    for (final code in expectedCodes) {
      if (primaryId == code) return true;
      if (primaryId.startsWith('$code-')) return true;
    }
    return false;
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
        '400-4300', // Rest area
        // '700-7900-0133', // Rest area
        '700-7900-0131', // Also include truck parking
      ];
    }

    // Weight stations / Scales
    if (name.contains('weight station') || name.contains('scales')) {
      return ['700-7900-0134', '400-4200-0048']; // Weigh station
    }

    // Fuel
    if (name.contains('fuel')) {
      return [
        // '700-7600-0323', // A charging station that provides recharging services for trucks and buses.
        // '700-7600-0000', // A business that sells fuel for vehicles. This is a base-level category that should be used for all places that do not fit other categories defined for Fueling Station (700-7600-xxxx).
        '700-7600-0116', // A business that sells fuel, oil, and other motoring supplies.
        // '700-7900-0132', // Also truck stops which have fuel
      ];
    }

    // Truck Washes
    if (name.contains('wash')) {
      return ['700-7900-0135', "700-7900-0323"]; // Truck wash
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
