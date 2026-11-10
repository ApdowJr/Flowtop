import 'package:flowtop/features/auth/domain/entities/user_entity.dart';

/// Contract for authentication operations.
/// Implementations must never trust client-supplied roles or ownership;
/// all access control is enforced by Firebase Auth + Firestore Security Rules.
abstract class AuthRepository {
  /// Stream of the current authenticated user (emits null on sign-out).
  Stream<UserEntity?> get authStateChanges;

  /// The currently signed-in user, or null.
  UserEntity? get currentUser;

  /// Register with email and password. Initializes the user profile in Firestore.
  Future<UserEntity> registerWithEmailPassword({
    required String email,
    required String password,
    String? displayName,
  });

  /// Sign in with email and password.
  Future<UserEntity> signInWithEmailPassword({
    required String email,
    required String password,
  });

  /// Sign in with Google (credential supplied by the presentation layer).
  Future<UserEntity> signInWithGoogle(Object googleCredential);

  /// Send a password-reset email to the given address.
  Future<void> sendPasswordResetEmail(String email);

  /// Sign out the current user and clear local state.
  Future<void> signOut();

  /// Update the current user's profile (display name / photo URL).
  Future<void> updateProfile({String? displayName, String? photoUrl});
}
