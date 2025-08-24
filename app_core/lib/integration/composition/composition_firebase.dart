import 'package:core_contracts/core_contracts.dart';
import 'package:firebase_auth_impl/firebase_auth_impl.dart';

AuthRepository makeAuthRepository() => FirebaseAuthRepository();
