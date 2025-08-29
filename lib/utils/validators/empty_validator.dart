part of 'validators.dart';

enum EmptyValidationError { empty }

class EmptyValidationInput extends FormzInput<String, EmptyValidationError> {
  const EmptyValidationInput.pure() : super.pure('');

  const EmptyValidationInput.dirty([super.value = '']) : super.dirty();

  @override
  EmptyValidationError? validator(String value) {
    return value.isEmpty ? EmptyValidationError.empty : null;
  }
}
