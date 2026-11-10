import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

/// Remote data source backed by Firebase Authentication.
abstract class AuthRemoteDataSource {
  Stream<User?> get authStateChanges;
  User? get currentUser;

  Future<UserCredential> registerWithEmailPassword({
    required String email,
    required String password,
  });
  Future<UserCredential> signInWithEmailPassword({
    required String email,
    required String password,
  });
  Future<UserCredential> signInWithGoogle(Object googleCredential);
  Future<void> sendPasswordResetEmail(String email);
  Future<void> signOut();
  Future<void> updateProfile({String? displayName, String? photoUrl});
}

class AuthRemoteDataSourceImpl implements AuthRemoteDataSource {
  AuthRemoteDataSourceImpl(this._auth, this._googleSignIn);

  final FirebaseAuth _auth;
  final GoogleSignIn _googleSignIn;

  @override
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  @override
  User? get currentUser => _auth.currentUser;

  @override
  Future<UserCredential> registerWithEmailPassword({
    required String email,
    required String password,
  }) async {
    return await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );
  }

  @override
  Future<UserCredential> signInWithEmailPassword({
    required String email,
    required String password,
  }) async {
    return await _auth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
  }

  @override
  Future<UserCredential> signInWithGoogle(Object googleCredential) async {
    final credential = googleCredential as OAuthCredential;
    return await _auth.signInWithCredential(credential);
  }

  @override
  Future<void> sendPasswordResetEmail(String email) async {
    await _auth.sendPasswordResetEmail(email: email);
  }

  @override
  Future<void> signOut() async {
    await Future.wait([
      _auth.signOut(),
      _googleSignIn.signOut(),
    ]);
  }

  @override
  Future<void> updateProfile({String? displayName, String? photoUrl}) async {
    final user = _auth.currentUser;
    if (user == null) throw FirebaseAuthException(
      code: 'not-authenticated',
      message: 'No authenticated user.',
    );
    await user.updateDisplayName(displayName);
    if (photoUrl != null) {
      await user.updatePhotoURL(photoUrl);
    }
    await user.reload();
  }
}

/// Helper to build a GoogleAuthCredential from a GoogleSignInAuthentication.
class GoogleAuthHelper {
  static OAuthCredential fromGoogleSignIn({
    required String idToken,
    required String accessToken,
  }) {
    return GoogleAuthProvider.credential(
      accessToken: accessToken,
      idToken: idToken,
    );
  }
}
