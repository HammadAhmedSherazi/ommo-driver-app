part of 'validators.dart';

enum InvalidIdenticalValidationError { empty, invalid, identical }

class InvalidIdenticalValidationInput
    extends FormzInput<String, InvalidIdenticalValidationError> {
  const InvalidIdenticalValidationInput.pure(this.pattern, this.currentValue) : super.pure('');

  const InvalidIdenticalValidationInput.dirty(this.pattern, this.currentValue, [String value = ''])
      : super.dirty(value);

  final String pattern;
  final String currentValue;

  @override
  InvalidIdenticalValidationError? validator(String value) {
    if (value.isEmpty) {
      return InvalidIdenticalValidationError.empty;
    } else if (!RegExp(pattern).hasMatch(value)) {
      return InvalidIdenticalValidationError.invalid;
    } else if (value == currentValue) {
      return InvalidIdenticalValidationError.identical;
    }
    return null;
  }
}
