part of 'theme.dart';

class AppColorTheme {
  // Private constructor
  AppColorTheme._internal();

  // The single instance
  static final AppColorTheme _instance = AppColorTheme._internal();

  // Factory constructor to return the same instance
  factory AppColorTheme() {
    return _instance;
  }

  // Color definitions
  Color get primary => const Color(0xFF30B87A);
  Color get secondary => const Color(0xFF888BA1);
  Color get white => const Color(0xFFFFFFFF);
  Color get black => const Color(0xFF000000);
  Color get green => const Color(0xFF34C759);
  Color get cyan => const Color(0xFF32ADE6);
  Color get lightGrey => const Color(0xFF7E8492);
  Color get darkGrey => const Color(0xFF595959);
  Color get grey => const Color(0xFF747574);
  Color get lightestGrey => const Color(0xFFEAEAEA);
  Color get red => const Color(0xFFFF3333);
  Color get whiteRed => const Color(0xFFFFF0F0);
  Color get whiteShade => const Color(0xFFF3F3F3);
  Color get whiteShade1 => const Color(0xFFF8F8F8);
  Color get shimmerBaseColor => Colors.grey[300]!;
  Color get shimmerHighlightColor => Colors.grey[100]!;
  Color get secondarButtonColor => Color(0xffF0F2F5);
  Color get subTitleTextColor => Color(0xff61758A);
  Color get titleTextColor => Color(0xff121417);
  Color get cancelTextColor => Color(0xffE1243D);
  Color get approvedTextColor => Color(0xff12915C);
  Color get disableBoxColor => Color(0xffF2F2F5);
  // golden Gradient 1
  Color get goldenGradient1 => const Color(0xFFFED75C);
  // golden Gradient 2
  Color get goldenGradient2 => const Color(0xFFEAA800);
  // silver Gradient 1
  Color get silverGradient1 => const Color(0xFFB6B6B6);
  // silver Gradient 2
  Color get silverGradient2 => const Color(0xFFE0E0E0);
  // silver Gradient 3
  Color get silverGradient3 => const Color(0xFFC9C9C9);
  // bronze
  Color get bronze1 => const Color(0xFF8A5510);
  Color get bronze2 => const Color(0xFF5F3600);
  Color get bronze3 => const Color(0xFF8C5601);

  Color get yellowlight => const Color(0xFFFFF189);
  Color get dark1 => const Color(0xFF444444);
  Color get dark2 => const Color(0xFF828282);
  // transparent
  Color get transparent => const Color(0x00000000);
  Color get orange => const Color(0xFFFF9029);
}
