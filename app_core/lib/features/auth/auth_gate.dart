import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:app_core/features/home/home_screen.dart';
import 'package:app_core/features/login/login_screen.dart';

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  Future<Widget> _checkAuthAndAuthorization(User? user) async {
    if (user == null) return const LoginScreen();

    try {
      // Ensure the token is fresh and the auth context is valid
      await user.getIdTokenResult(true); // Refreshes the token

      final doc = await FirebaseFirestore.instance
          .collection('authorized_users')
          .doc(user.email)
          .get();

      final level = doc.data()?['auth_level'];
      if (['Admin', 'Master', 'Standard'].contains(level)) {
        return const HomeScreen();
      } else {
        return const LoginScreen(); // Not authorized
      }
    } catch (e) {
      // Consider logging this in production
      return const LoginScreen();
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        return FutureBuilder<Widget>(
          future: _checkAuthAndAuthorization(snapshot.data),
          builder: (context, authSnapshot) {
            if (authSnapshot.connectionState == ConnectionState.waiting) {
              return const Scaffold(
                body: Center(child: CircularProgressIndicator()),
              );
            }

            return authSnapshot.data ?? const LoginScreen();
          },
        );
      },
    );
  }
}
