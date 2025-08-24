import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:core_contracts/core_contracts.dart';
import 'ui/login_screen.dart';
import '../splash/splash_screen.dart';

class LoginContainer extends StatefulWidget {
  final AuthRepository auth;
  final Widget child;
  const LoginContainer({super.key, required this.auth, required this.child});

  @override
  State<LoginContainer> createState() => _LoginContainerState();
}

class _LoginContainerState extends State<LoginContainer> {
  bool _ready = false;
  bool _authed = false;
  StreamSubscription<AuthUser?>? _sub;

  @override
  void initState() {
    super.initState();
    _boot();
  }

  Future<void> _boot() async {
    await widget.auth.init();

    _sub = widget.auth.authStateChanges().listen((user) async {
      if (!mounted) return;

      if (user != null) {
        setState(() {
          _ready = true;
          _authed = true;
        });
      } else {
        final ok = await Navigator.of(context).push<bool>(
          MaterialPageRoute(
            builder: (_) => LoginScreen(
              onSignIn: () async => (await widget.auth.signIn()) != null,
              onExit: () => SystemNavigator.pop(),
            ),
          ),
        );
        if (!mounted) return;
        setState(() {
          _ready = true;
          _authed = ok == true;
        });
        if (ok != true) SystemNavigator.pop();
      }
    });
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_ready) return const SplashScreen();
    if (_authed) return widget.child;
    return const Scaffold(body: Center(child: Text('Something went wrong…')));
  }
}
