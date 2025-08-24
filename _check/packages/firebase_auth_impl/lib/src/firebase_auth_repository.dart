import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:core_contracts/core_contracts.dart';
import 'firebase_initializer.dart';

class FirebaseAuthRepository implements AuthRepository {
  @override
  Future<void> init() => initFirebase();

  @override
  Stream<AuthUser?> authStateChanges() => FirebaseAuth.instance
      .authStateChanges()
      .map((u) => u == null ? null : AuthUser(uid: u.uid, email: u.email));

  @override
  Future<AuthUser?> signIn() async {
    try {
      if (kIsWeb) {
        // Web: use popup with Google provider
        final provider = GoogleAuthProvider();
        final cred = await FirebaseAuth.instance.signInWithPopup(provider);
        final u = cred.user;
        return u == null ? null : AuthUser(uid: u.uid, email: u.email);
      } else {
        // Android/iOS: use google_sign_in to get tokens, then Firebase credential
        final googleUser = await GoogleSignIn().signIn();
        if (googleUser == null) return null; // user cancelled

        final googleAuth = await googleUser.authentication;
        final credential = GoogleAuthProvider.credential(
          accessToken: googleAuth.accessToken,
          idToken: googleAuth.idToken,
        );
        final cred = await FirebaseAuth.instance.signInWithCredential(
          credential,
        );
        final u = cred.user;
        return u == null ? null : AuthUser(uid: u.uid, email: u.email);
      }
    } catch (e) {
      // Bubble up as null; UI will stay on login
      return null;
    }
  }

  @override
  Future<void> signOut() => FirebaseAuth.instance.signOut();
}
