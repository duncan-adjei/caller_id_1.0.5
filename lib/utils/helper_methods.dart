import 'package:flutter_engage_plugin/utils/const.dart';

EngageRegistrationError getRegistrationErrorFromString(String errorString) {
  switch (errorString) {
    case 'INVALID_CODE':
      return EngageRegistrationError.invalidCode;
    case 'INVALID_NUMBER':
      return EngageRegistrationError.invalidNumber;
    case 'TIMEOUT':
      return EngageRegistrationError.timeout;
    case 'RATE_LIMITED':
      return EngageRegistrationError.rateLimited;
    case 'INTERNAL_ERROR':
      return EngageRegistrationError.internalError;
    case 'UNKNOWN':
      return EngageRegistrationError.unknown;
    case 'RESTRICTED':
      return EngageRegistrationError.restricted;
    case 'cannotInitChallengeNoPushToken':
      return EngageRegistrationError.cannotInitChallengeNoPushToken;
    default:
      throw ArgumentError(
          'Invalid EngageRegistrationError string: $errorString');
  }
}

EngageUnregistrationError getUnregistrationErrorFromString(String errorString) {
  switch (errorString) {
    case 'TIMEOUT':
      return EngageUnregistrationError.timeout;
    case 'INTERNAL_ERROR':
      return EngageUnregistrationError.internalError;
    case 'NETWORK_FAILURE':
      return EngageUnregistrationError.networkFailure;
    case 'NOT_REGISTERED':
      return EngageUnregistrationError.notRegistered;
    case 'UNKNOWN':
      return EngageUnregistrationError.unknown;
    case 'RESTRICTED':
      return EngageUnregistrationError.restricted;
    default:
      throw ArgumentError(
          'Invalid EngageUnregistrationError string: $errorString');
  }
}

EngageNumberChangeError getNumberChangeErrorFromString(String errorString) {
  switch (errorString) {
    case 'TIMEOUT':
      return EngageNumberChangeError.timeout;
    case 'INTERNAL_ERROR':
      return EngageNumberChangeError.internalError;
    case 'OLD_NUMBER_NOT_REGISTERED':
      return EngageNumberChangeError.oldNumberNotRegistered;
    case 'NEW_NUMBER_ALREADY_REGISTERED':
      return EngageNumberChangeError.newNumberAlreadyRegistered;
    case 'UNKNOWN':
      return EngageNumberChangeError.unknown;
    default:
      throw ArgumentError(
          'Invalid EngageNumberChangeError string: $errorString');
  }
}
