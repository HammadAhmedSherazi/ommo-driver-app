class Validation {
  static String? validateFeet(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter feet';
    }
    final feet = int.tryParse(value);

    if (feet == null || feet < 1) {
      return 'Feet must be greater than 1';
    }

    return null;
  }

  static String? validateInches(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter inches';
    }
    final inches = int.tryParse(value);
    if (inches == null || inches < 0 || inches > 11) {
      return 'Inches must be between 0 and 11';
    }
    return null;
  }
}
