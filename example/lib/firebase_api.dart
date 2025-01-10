import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_engage_plugin/engage.dart';
import 'package:flutter_engage_plugin_example/firebase_options.dart';

// this must be top level function otherwise it not executed
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // If you're going to use other Firebase services in the background, such as Firestore,
  // make sure you call `initializeApp` before using other Firebase services.
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  if (await Engage.instance.isEngagePush(message.data)) {
    Engage.instance.handlePushNotification(message.data);
  }
}

class FirebaseApi {
  static void initNotification() {
    // Setup Firebase foreground and background listeners.
    FirebaseMessaging.onMessage.listen(_firebaseMessagingBackgroundHandler);
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
  }
}
