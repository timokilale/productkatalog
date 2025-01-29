import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    return FirebaseOptions(
      apiKey: '',
      authDomain: 'farmarket-1c7df.firebaseapp.com',
      projectId: 'farmarket-1c7df',
      storageBucket: 'farmarket-1c7df.appspot.com',
      messagingSenderId: '295579599282',
      appId: '1:295579599282:android:02d7ec5a596b0f2638e4ab',
    );
  }
}
