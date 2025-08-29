import 'package:formz/formz.dart';

part 'empty_validator.dart';
part 'invalid_validator.dart';
part 'identical_validator.dart';
part 'invalid_identical_validator.dart';
part 'mismatch_validator.dart';

const String emailPattern = r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$';

const String passwordPattern = r'^(?=.*?[A-Z])(?=.*?[0-9]).{8,}$';

const String namePattern = r'^[a-zA-Z ]{1,20}$';

const String usernamePattern = r'^[^\s]{1,25}$';

const String fourLimitPattern = r'^.{4}$';

const String maxTwoHundredFiftyPattern = r'^.{1,250}$';
