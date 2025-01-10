// ignore_for_file: file_names

import 'package:flutter_engage_plugin/utils/const.dart';

abstract class EngageRegistrationHandler {
  /// Called when challenge is initialized successfully
  void onInitializationSuccess(String? userNumber);

  /// Called when number is registered successfully
  void onRegistrationSuccess(String? userNumber);

  /// Called when registration fails
  /// @param phoneNumber Phone number that failed to register
  /// @param error The reason of the error
  void onRegistrationFailure(
      String? phoneNumber, EngageRegistrationError? error);
}
