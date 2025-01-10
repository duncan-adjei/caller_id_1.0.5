enum EngageEnvironment {
  debug,
  test,
  production;

  String get rawValue {
    return toString().split('.').last;
  }
}

enum EngageError { error }

enum EngageRegistrationError {
  invalidCode,

  invalidNumber,

  timeout,

  rateLimited,

  internalError,

  unknown,

  restricted,

  cannotInitChallengeNoPushToken,
}

enum EngageUnregistrationError {
  timeout,

  internalError,

  networkFailure,

  notRegistered,

  unknown,

  restricted,
}

enum EngageNumberChangeError {
  timeout,

  internalError,

  oldNumberNotRegistered,

  newNumberAlreadyRegistered,

  unknown
}
