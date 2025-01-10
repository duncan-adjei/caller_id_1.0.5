// ignore_for_file: avoid_print

import 'dart:io';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_engage_plugin/Handler/engage_registration_handler.dart';
import 'package:flutter_engage_plugin/engage.dart';
import 'package:flutter_engage_plugin/utils/const.dart';
import 'package:flutter_engage_plugin_example/firebase_api.dart';

import 'package:flutter_engage_plugin_example/firebase_options.dart';
import 'package:permission_handler/permission_handler.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  if (Platform.isAndroid) {
    // For Android, the client must initialize their Firebase instance before
    // calling configureSDK on Engage.
    await Firebase.initializeApp(options: DefaultFirebaseOptions.android);

    // Initialize Firebase Notification handlers. These will handle logic to hand
    // off Engage pushes to the Engage SDK.
    FirebaseApi.initNotification();
  }

  // Initialize the Engage SDK.
  if(Platform.isIOS){
    await Engage.instance.configureEngageForIOS(EngageEnvironment.debug, null);
  }

  runApp(const EngageApp());
}

class EngageApp extends StatefulWidget {
  const EngageApp({super.key});

  @override
  State<EngageApp> createState() => _EngageAppState();
}

class _EngageAppState extends State<EngageApp> implements EngageRegistrationHandler {
  final _messangerKey = GlobalKey<ScaffoldMessengerState>();
  final TextEditingController _enterNumberController = TextEditingController();
  final FocusNode _enterNumberFocusNode = FocusNode();
  final TextEditingController _enterCodeController = TextEditingController();
  final FocusNode _enterCodeFocusNode = FocusNode();

  var isContactPermissionGranted = false;
  var isNotificationPermissionGranted = false;

  var isNumberInit = false;
  String? selectedVerificationType = "Push/Pin";
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    checkPermission();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      scaffoldMessengerKey: _messangerKey,
      home: SafeArea(
        child: Scaffold(
          appBar: AppBar(title: const Text('Engage Plugin example')),
          body: SingleChildScrollView(
            child: Stack(
              alignment: Alignment.center,
              children: [
                Column(children: [
                  verificationSelection(),
                  permissionUi(),
                  if (isContactPermissionGranted && isNotificationPermissionGranted)
                    Visibility(
                      visible: true,
                      child: UserInputEnterField(
                        titleText: "Register Your Number with Engage",
                        buttonText: "Register",
                        hintText: "Enter phone number",
                        textEditingController: _enterNumberController,
                        focusNode: _enterNumberFocusNode,
                        onPressed: onNumberEntered,
                      ),
                    ),
                  if (isContactPermissionGranted && isNotificationPermissionGranted && isNumberInit && selectedVerificationType == "SMS")
                    Visibility(
                      visible: true,
                      child: UserInputEnterField(
                        titleText: "Verification Code",
                        buttonText: "Submit",
                        hintText: "Enter sms code",
                        textEditingController: _enterCodeController,
                        focusNode: _enterCodeFocusNode,
                        onPressed: onCodeEntered,
                      ),
                    ),
                ]),
                if (isLoading)
                  const Positioned.fill(
                    child: Center(child: CircularProgressIndicator()),
                  )
              ],
            ),
          ),
        ),
      ),
    );
  }

  Center verificationSelection() {
    return Center(
      child: Column(
        children: [
          const Text("Select engage verification type"),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: <Widget>[
                Expanded(
                  child: RadioListTile<String>(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Push/Pin'),
                    value: 'Push/Pin',
                    groupValue: selectedVerificationType,
                    onChanged: (value) {
                      setState(() {
                        selectedVerificationType = value;
                      });
                    },
                  ),
                ),
                Expanded(
                  child: RadioListTile<String>(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('SMS'),
                    value: 'SMS',
                    groupValue: selectedVerificationType,
                    onChanged: (value) {
                      setState(() {
                        selectedVerificationType = value;
                      });
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget permissionUi() {
    return Center(
      child: Wrap(
        alignment: WrapAlignment.center,
        children: [
          const Text(
            "Enable both permission required for engage service",
            style: TextStyle(fontSize: 14),
          ),
          ElevatedButton(
            onPressed: isContactPermissionGranted ? null : enableContactPermission,
            child: Wrap(
              children: [
                if (isContactPermissionGranted) const Icon(Icons.done),
                const Text('Enable Contact Permission'),
              ],
            ),
          ),
          const SizedBox(width: 16), // Add some spacing between buttons
          ElevatedButton(
            onPressed: isNotificationPermissionGranted ? null : enableNotificationPermission,
            child: Wrap(
              children: [
                if (isNotificationPermissionGranted) const Icon(Icons.done),
                const Text('Enable Notification permission'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void onNumberEntered() {
    // FirebaseCrashlytics.instance.crash();
    var number = _enterNumberController.text;
    setState(() {
      isNumberInit = false;
      isLoading = true;
    });
    Engage.instance.register(phoneNumber: number, engageRegistrationHandler: this);
  }

  void onCodeEntered() {
    var code = _enterCodeController.text;
    Engage.instance.completeChallengeWithCode(code, (usernumber) => {print('sms verify')});
  }

  void enableContactPermission() async {
    if (await Permission.contacts.isPermanentlyDenied) {
      openSetting();
    }
    if (!await Permission.contacts.isGranted) {
      Permission.contacts.onGrantedCallback(() {
        setState(() {
          isContactPermissionGranted = true;
        });
      }).onDeniedCallback(() {
        showSnakBarMessage('Contact Permission is required for using engage service');
        setState(() {
          isContactPermissionGranted = false;
        });
      }).request();
    }
  }

  void enableNotificationPermission() async {
    if (await Permission.notification.isPermanentlyDenied) {
      openSetting();
    }
    if (!await Permission.notification.isGranted) {
      Permission.notification.onGrantedCallback(() {
        setState(() {
          isNotificationPermissionGranted = true;
        });
      }).onDeniedCallback(() {
        showSnakBarMessage('Notification Permission is required for using engage service');
        setState(() {
          isNotificationPermissionGranted = false;
        });
      }).request();
    }
  }

  void openSetting() {
    openAppSettings().then((value) async {
      if (await Permission.contacts.isDenied || await Permission.notification.isDenied) {
        showSnakBarMessage('Both Permissions are required for using engage service');
      }
      checkPermission();
    });
  }

  void showSnakBarMessage(String msg) {
    _messangerKey.currentState
      ?..hideCurrentSnackBar
      ..showSnackBar(SnackBar(content: Text(msg)));
  }

  void checkPermission() async {
    if (await Permission.contacts.isGranted) {
      setState(() {
        isContactPermissionGranted = true;
      });
    }
    if (await Permission.notification.isGranted) {
      setState(() {
        isNotificationPermissionGranted = true;
      });
    }
  }

  @override
  void onInitializationSuccess(String? userNumber) {
    setState(() {
      if (selectedVerificationType == "SMS") {
        isNumberInit = true;
        isLoading = false;
      }
    });
    print("flutter on onInitializationSuccess $userNumber");
  }

  @override
  void onRegistrationFailure(String? phoneNumber, EngageRegistrationError? error) {
    setState(() {
      isLoading = false;
    });
    print('PhoneNumber $phoneNumber registeration fail ${error.toString()}');
    showSnakBarMessage('PhoneNumber $phoneNumber registeration fail ${error.toString()}');
  }

  @override
  void onRegistrationSuccess(String? userNumber) {
    setState(() {
      isLoading = false;
    });
    print("flutter on onRegistrationSuccess $userNumber");
    showSnakBarMessage('onRegistrationSuccess $userNumber');
  }
}

class UserInputEnterField extends StatelessWidget {
  const UserInputEnterField({
    super.key,
    required String titleText,
    required String buttonText,
    required String hintText,
    required TextEditingController textEditingController,
    required FocusNode focusNode,
    required Function() onPressed,
  })  : _titleText = titleText,
        _buttonText = buttonText,
        _hintText = hintText,
        _enterCodeController = textEditingController,
        _onPressed = onPressed;

  final String _titleText;
  final String _hintText;
  final String _buttonText;
  final TextEditingController _enterCodeController;
  final Function() _onPressed;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          FittedBox(
            child: Text(
              _titleText,
              style: const TextStyle(
                fontSize: 24,
              ),
            ),
          ),
          Container(
            margin: const EdgeInsets.all(24),
            decoration: BoxDecoration(border: Border.all(color: Colors.black)),
            width: double.infinity,
            height: 50,
            child: TextField(
              keyboardType: TextInputType.phone,
              controller: _enterCodeController,
              decoration: InputDecoration(
                contentPadding: const EdgeInsets.all(8),
                hintText: _hintText,
                hintStyle: const TextStyle(color: Colors.grey),
                border: InputBorder.none,
              ),
              style: Theme.of(context).textTheme.bodyMedium!,
              cursorColor: Colors.black,
            ),
          ),
          ElevatedButton(
            onPressed: _onPressed,
            child: Text(_buttonText),
          ),
        ],
      ),
    );
  }
}
