part of 'validators.dart';

enum MismatchValidationError { empty, mismatch }

class MismatchValidationInput
    extends FormzInput<String, MismatchValidationError> {
  const MismatchValidationInput.pure(this.matchValue) : super.pure('');

  const MismatchValidationInput.dirty(this.matchValue, [String value = ''])
      : super.dirty(value);

  final String matchValue;

  @override
  MismatchValidationError? validator(String value) {
    if (value.isEmpty) {
      return MismatchValidationError.empty;
    } else if (value != matchValue) {
      return MismatchValidationError.mismatch;
    }
    return null;
  }
}
