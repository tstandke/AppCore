import 'package:flutter/material.dart';

class SplashScreen extends StatelessWidget {
  final bool error;
  const SplashScreen({super.key, this.error = false});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: error
            ? const Text('Something went wrong…')
            : const CircularProgressIndicator(),
      ),
    );
  }
}
