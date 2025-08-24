import 'auth_models.dart';

/// Abstraction the UI talks to. No vendor details here.
abstract class AuthRepository {
  /// e.g., initialize SDKs, read cached session, etc.
  Future<void> init();

  /// Emits the current user when signed in, or null otherwise.
  Stream<AuthUser?> authStateChanges();

  /// Perform the sign-in flow (Google/email/etc.). Returns user on success.
  Future<AuthUser?> signIn();

  /// Sign out current user.
  Future<void> signOut();
}
