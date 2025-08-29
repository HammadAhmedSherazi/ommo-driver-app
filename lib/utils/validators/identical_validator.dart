part of 'validators.dart';

enum IdenticalValidationError { empty, identical }

class IdenticalValidationInput
    extends FormzInput<String, IdenticalValidationError> {
  const IdenticalValidationInput.pure(this.currentValue) : super.pure('');

  const IdenticalValidationInput.dirty(this.currentValue, [String value = ''])
      : super.dirty(value);

  final String currentValue;

  @override
  IdenticalValidationError? validator(String value) {
    if (value.isEmpty) {
      return IdenticalValidationError.empty;
    } else if (value == currentValue) {
      return IdenticalValidationError.identical;
    }
    return null;
  }
}