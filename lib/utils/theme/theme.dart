import 'package:flutter/material.dart';
import '../utils.dart';

part 'app_color_theme.dart';
part 'app_text_theme.dart';

class AppTheme {
  AppTheme._internal({AppColorTheme? appColorTheme, AppTextTheme? appTextTheme})
    : _appColorTheme = appColorTheme ?? AppColorTheme(),
      _appTextTheme = appTextTheme ?? AppTextTheme();

  static final AppTheme _instance = AppTheme._internal();

  factory AppTheme() {
    return _instance;
  }

  final AppColorTheme _appColorTheme;
  final AppTextTheme _appTextTheme;

  ThemeData get themeData => ThemeData(
    useMaterial3: true,
    colorScheme: colorScheme,
    brightness: Brightness.light,
    primaryColor: _appColorTheme.primary,
    fontFamily: _appTextTheme.fontFamily,
    inputDecorationTheme: inputDecorationThemeData,
    iconTheme: iconThemeData,
    listTileTheme: listTileThemeData,
    appBarTheme: appBarTheme,
    scaffoldBackgroundColor: _appColorTheme.white,
    elevatedButtonTheme: elevatedButtonThemeData,
    outlinedButtonTheme: outlinedButtonThemeData,
    dividerTheme: dividerTheme,
    datePickerTheme: datePickerTheme,
  );

  ColorScheme get colorScheme => const ColorScheme.light().copyWith(
    primary: _appColorTheme.primary,
    secondary: _appColorTheme.secondary,
    surfaceTint: Colors.transparent,
  );

  IconThemeData get iconThemeData =>
      IconThemeData(color: _appColorTheme.primary);

  ElevatedButtonThemeData get elevatedButtonThemeData =>
      ElevatedButtonThemeData(
        style: ButtonStyle(
          shape: WidgetStateProperty.all(
            const RoundedRectangleBorder(
              borderRadius: BorderRadius.all(Radius.circular(8)),
            ),
          ),
        ),
      );

  OutlinedButtonThemeData get outlinedButtonThemeData =>
      OutlinedButtonThemeData(
        style: ButtonStyle(
          shape: WidgetStateProperty.all(
            const RoundedRectangleBorder(
              borderRadius: BorderRadius.all(Radius.circular(8)),
            ),
          ),
        ),
      );

  ListTileThemeData get listTileThemeData =>
      ListTileThemeData(iconColor: _appColorTheme.primary);

  InputDecorationThemeData get inputDecorationThemeData => InputDecorationThemeData(
    iconColor: _appColorTheme.primary,
    hintStyle: TextStyle(
      fontFamily: "Archivo",
      fontSize: 16,
      fontWeight: AppFontWeight.medium,
      height: 1.2,
      color: _appColorTheme.grey,
    ),
    labelStyle: TextStyle(
      fontFamily: "Archivo",
      fontSize: 16,
      fontWeight: AppFontWeight.medium,
      height: 1.2,
      color: _appColorTheme.black,
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.horizontal(
        left: Radius.circular(30),
        right: Radius.circular(30)
      ),
      borderSide: BorderSide(
        
        color: Colors.transparent,
        
      )
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.horizontal(
        left: Radius.circular(30),
        right: Radius.circular(30)
      ),
      borderSide: BorderSide(
        
        color: Colors.transparent,
        
      )
    ),
    errorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.horizontal(
        left: Radius.circular(30),
        right: Radius.circular(30)
      ),
      borderSide: BorderSide(
        
        color: Colors.transparent,
        
      )
    ),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.horizontal(
        left: Radius.circular(30),
        right: Radius.circular(30)
      ),
      borderSide: BorderSide(
        
        color: Colors.transparent,
        
      )
    )
  );

  AppBarTheme get appBarTheme => AppBarTheme(
    backgroundColor: Colors.transparent,
    surfaceTintColor: Colors.transparent,
    foregroundColor: _appColorTheme.primary,
    elevation: 0,
  );

  DividerThemeData get dividerTheme => DividerThemeData(
    color: _appColorTheme.lightGrey.withValues(alpha: 0.2),
    space: 0,
    thickness: 1,
  );

  DatePickerThemeData get datePickerTheme =>
      DatePickerThemeData(backgroundColor: _appColorTheme.white);

  static double get horizontalPadding => 15.0;
  static double get bottomPadding => 32;

  EdgeInsets get pagePadding=> EdgeInsets.fromLTRB(horizontalPadding, horizontalPadding, horizontalPadding, bottomPadding);
}
