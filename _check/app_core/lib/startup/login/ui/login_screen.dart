import 'package:flutter/material.dart';

class LoginScreen extends StatelessWidget {
  final Future<bool> Function() onSignIn;
  final VoidCallback onExit;

  const LoginScreen({super.key, required this.onSignIn, required this.onExit});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ElevatedButton(
              onPressed: () async {
                final ok = await onSignIn();
                if (context.mounted) Navigator.of(context).pop(ok);
              },
              child: const Text('Sign in'),
            ),
            const SizedBox(height: 12),
            TextButton(onPressed: onExit, child: const Text('Exit')),
          ],
        ),
      ),
    );
  }
}
