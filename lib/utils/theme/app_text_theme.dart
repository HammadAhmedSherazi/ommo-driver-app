part of 'theme.dart';

class AppTextTheme {
  AppTextTheme._internal({this.fontFamily = "Archivo"})
    : _baseTextStyle = TextStyle(
        fontFamily: fontFamily,
        fontWeight: AppFontWeight.medium,
        height: 1.2,
      );

  static final AppTextTheme _instance = AppTextTheme._internal();

  factory AppTextTheme() {
    return _instance;
  }

  final String fontFamily;
  final TextStyle _baseTextStyle;

  TextStyle get headingText => _baseTextStyle.copyWith(
    fontSize: 24,
    fontWeight: AppFontWeight.extraBold,
  );

  TextStyle get subHeadingText =>
      _baseTextStyle.copyWith(fontSize: 18, fontWeight: AppFontWeight.bold);

  TextStyle get bodyText =>
      _baseTextStyle.copyWith(fontSize: 14, fontWeight: AppFontWeight.medium);

  TextStyle get lightText =>
      _baseTextStyle.copyWith(fontSize: 14, fontWeight: AppFontWeight.regular);
}
