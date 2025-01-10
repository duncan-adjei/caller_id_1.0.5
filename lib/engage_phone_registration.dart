part of engage;

class _EngagePhoneRegistration {
  @visibleForTesting
  final methodChannel = const MethodChannel('flutter_engage_plugin');

  static const EventChannel _eventChannel =
      EventChannel('engage_registration_events');

  void Function(String?)? _onInitializationSuccess;
  void Function(String?)? _onRegistrationSuccess;
  void Function(String?, EngageRegistrationError?)? _onRegistrationFailure;
  void Function(String?)? _onChallengeSuccess;
  bool registrationCompleted = false;
  _EngagePhoneRegistration() {
    _eventChannel.receiveBroadcastStream('registration').listen((event) {
      if (event['eventName'] == 'onInitializationSuccess') {
        if (!registrationCompleted) {
          _onInitializationSuccess?.call(event['userNumber']);
        } else {
          registrationCompleted = false;
        }
      } else if (event['eventName'] == 'onRegistrationSuccess') {
        registrationCompleted = true;
        _onRegistrationSuccess?.call(event['userNumber']);
        _onChallengeSuccess?.call(event['userNumber']);
      } else if (event['eventName'] == 'onRegistrationFailure') {
        _onRegistrationFailure?.call(event['phoneNumber'],
            getRegistrationErrorFromString(event['error'].toString()));
      }
    });
  }

  _EngagePhoneRegistration onChallengeSuccessCallback(
      FutureOr<void>? Function(dynamic)? callback) {
    _onChallengeSuccess = callback;
    return this;
  }

  void register(String phoneNumber, EngageRegistrationHandler handler) {
    _onInitializationSuccess = handler.onInitializationSuccess;
    _onRegistrationSuccess = handler.onRegistrationSuccess;
    _onRegistrationFailure = handler.onRegistrationFailure;
    methodChannel.invokeMethod("register", {'phoneNumber': phoneNumber});
  }

  void completeChallengeWithCode(String userInput) {
    methodChannel
        .invokeMethod("completeChallengeWithCode", {'userInput': userInput});
  }
}
