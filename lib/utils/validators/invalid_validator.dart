part of 'validators.dart';

enum InvalidValidationError { empty, invalid }

class InvalidValidationInput
    extends FormzInput<String, InvalidValidationError> {
  const InvalidValidationInput.pure(this.pattern) : super.pure('');

  const InvalidValidationInput.dirty(this.pattern, [String value = ''])
      : super.dirty(value);

  final String pattern;

  @override
  InvalidValidationError? validator(String value) {
    if (value.isEmpty) {
      return InvalidValidationError.empty;
    } else if (!RegExp(pattern).hasMatch(value)) {
      return InvalidValidationError.invalid;
    }
    return null;
  }
}
