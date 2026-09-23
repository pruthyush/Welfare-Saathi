import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

/// Default [FirebaseOptions] for Welfare Saathi prototype.
///
/// Provides multi-platform configurations for Flutter Web and native targets.
class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      return web;
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      case TargetPlatform.macOS:
        return macos;
      case TargetPlatform.windows:
        return windows;
      case TargetPlatform.linux:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for linux.',
        );
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyA-WelfareSaathiDemoApiKey001',
    appId: '1:102938475610:web:98f7e6d5c4b3a201',
    messagingSenderId: '102938475610',
    projectId: 'welfare-saathi-ps07',
    authDomain: 'welfare-saathi-ps07.firebaseapp.com',
    storageBucket: 'welfare-saathi-ps07.appspot.com',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyA-WelfareSaathiDemoApiKeyAndroid',
    appId: '1:102938475610:android:a1b2c3d4e5f6g7h8',
    messagingSenderId: '102938475610',
    projectId: 'welfare-saathi-ps07',
    storageBucket: 'welfare-saathi-ps07.appspot.com',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyA-WelfareSaathiDemoApiKeyIOS',
    appId: '1:102938475610:ios:h8g7f6e5d4c3b2a1',
    messagingSenderId: '102938475610',
    projectId: 'welfare-saathi-ps07',
    storageBucket: 'welfare-saathi-ps07.appspot.com',
    iosBundleId: 'com.aanavandi.welfareSaathi',
  );

  static const FirebaseOptions macos = FirebaseOptions(
    apiKey: 'AIzaSyA-WelfareSaathiDemoApiKeyIOS',
    appId: '1:102938475610:ios:h8g7f6e5d4c3b2a1',
    messagingSenderId: '102938475610',
    projectId: 'welfare-saathi-ps07',
    storageBucket: 'welfare-saathi-ps07.appspot.com',
    iosBundleId: 'com.aanavandi.welfareSaathi',
  );

  static const FirebaseOptions windows = FirebaseOptions(
    apiKey: 'AIzaSyA-WelfareSaathiDemoApiKeyWindows',
    appId: '1:102938475610:web:98f7e6d5c4b3a201',
    messagingSenderId: '102938475610',
    projectId: 'welfare-saathi-ps07',
    authDomain: 'welfare-saathi-ps07.firebaseapp.com',
    storageBucket: 'welfare-saathi-ps07.appspot.com',
  );
}
