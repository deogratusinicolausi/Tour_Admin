import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

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
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyDDKlIwhqR51p9Vb0tnwlbWJnpgV0MUcXk',
    appId: '1:749360118137:android:98df8d13a36bed732497a8',
    messagingSenderId: '749360118137',
    projectId: 'turiva',
    storageBucket: 'turiva.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyDDKlIwhqR51p9Vb0tnwlbWJnpgV0MUcXk',
    appId: '1:749360118137:android:98df8d13a36bed732497a8',
    messagingSenderId: '749360118137',
    projectId: 'turiva',
    storageBucket: 'turiva.firebasestorage.app',
    iosBundleId: 'com.example.turivaAdmin',
  );

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyDDKlIwhqR51p9Vb0tnwlbWJnpgV0MUcXk',
    appId: '1:749360118137:android:98df8d13a36bed732497a8',
    messagingSenderId: '749360118137',
    projectId: 'turiva',
    authDomain: 'turiva.firebaseapp.com',
    storageBucket: 'turiva.firebasestorage.app',
  );
}