import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flowtop/features/auth/domain/entities/user_entity.dart';
import 'package:flowtop/features/auth/domain/repositories/auth_repository.dart';
import 'package:flowtop/features/auth/data/datasources/auth_remote_datasource.dart';
import 'package:flowtop/features/auth/data/models/user_model.dart';

class AuthRepositoryImpl implements AuthRepository {
  AuthRepositoryImpl(this._remoteDataSource, this._firestore);

  final AuthRemoteDataSource _remoteDataSource;
  final FirebaseFirestore _firestore;

  static const String _usersCollection = 'users';

  @override
  Stream<UserEntity?> get authStateChanges =>
      _remoteDataSource.authStateChanges.map((user) {
        if (user == null) return null;
        return _userEntityFromFirebaseUser(user);
      });

  @override
  UserEntity? get currentUser {
    final user = _remoteDataSource.currentUser;
    if (user == null) return null;
    return _userEntityFromFirebaseUser(user);
  }

  @override
  Future<UserEntity> registerWithEmailPassword({
    required String email,
    required String password,
    String? displayName,
  }) async {
    final credential = await _remoteDataSource.registerWithEmailPassword(
      email: email,
      password: password,
    );
    final firebaseUser = credential.user;
    if (firebaseUser == null) {
      throw FirebaseAuthException(
        code: 'registration-failed',
        message: 'Unable to complete registration.',
      );
    }

    // Keep the name on the Auth profile as well, so it is available as soon as
    // the user is signed in (greeting, invitations). A failure here is not
    // fatal: the account exists and the profile document below holds the name.
    final name = displayName?.trim();
    if (name != null && name.isNotEmpty) {
      try {
        await _remoteDataSource.updateProfile(displayName: name);
      } catch (_) {
        // Intentionally ignored, see above.
      }
    }
    // Invitations can only be claimed with a verified email address.
    try {
      await _remoteDataSource.sendEmailVerification();
    } catch (_) {
      // Intentionally ignored: the user can ask for the email again later.
    }
    final registeredUser = _remoteDataSource.currentUser ?? firebaseUser;
    final entity = _userEntityFromFirebaseUser(registeredUser).copyWith(
      displayName: (name == null || name.isEmpty) ? null : name,
    );

    // Initialize the user profile document (trusted server-side fields only).
    await _firestore.collection(_usersCollection).doc(firebaseUser.uid).set(
      UserModel.fromEntity(entity).toMap(),
      SetOptions(merge: true),
    );

    return entity;
  }

  @override
  Future<UserEntity> signInWithEmailPassword({
    required String email,
    required String password,
  }) async {
    final credential = await _remoteDataSource.signInWithEmailPassword(
      email: email,
      password: password,
    );
    final user = credential.user;
    if (user == null) {
      throw FirebaseAuthException(
        code: 'sign-in-failed',
        message: 'Unable to sign in.',
      );
    }
    return _userEntityFromFirebaseUser(user);
  }

  @override
  Future<UserEntity> signInWithGoogle(Object googleCredential) async {
    final credential = await _remoteDataSource.signInWithGoogle(googleCredential);
    final user = credential.user;
    if (user == null) {
      throw FirebaseAuthException(
        code: 'google-sign-in-failed',
        message: 'Unable to sign in with Google.',
      );
    }

    // Initialize profile if it doesn't exist yet.
    final doc = _firestore.collection(_usersCollection).doc(user.uid);
    final snapshot = await doc.get();
    if (!snapshot.exists) {
      await doc.set(UserModel.fromEntity(_userEntityFromFirebaseUser(user)).toMap());
    }

    return _userEntityFromFirebaseUser(user);
  }

  @override
  Future<void> sendPasswordResetEmail(String email) async {
    await _remoteDataSource.sendPasswordResetEmail(email);
  }

  @override
  Future<void> signOut() async {
    await _remoteDataSource.signOut();
  }

  @override
  Future<void> updateProfile({String? displayName, String? photoUrl}) async {
    await _remoteDataSource.updateProfile(displayName: displayName, photoUrl: photoUrl);
    final user = _remoteDataSource.currentUser;
    if (user == null) return;
    // Merge instead of update so a missing profile document is created. The uid
    // is part of the payload because the security rules require it to match.
    await _firestore.collection(_usersCollection).doc(user.uid).set({
      'uid': user.uid,
      if (displayName != null) 'displayName': displayName,
      if (photoUrl != null) 'photoUrl': photoUrl,
    }, SetOptions(merge: true));
  }

  @override
  Future<void> sendEmailVerification() => _remoteDataSource.sendEmailVerification();

  @override
  Future<void> reloadUser() => _remoteDataSource.reloadUser();

  UserEntity _userEntityFromFirebaseUser(User user) {
    return UserEntity(
      uid: user.uid,
      email: user.email,
      displayName: user.displayName,
      photoUrl: user.photoURL,
      emailVerified: user.emailVerified,
      createdAt: user.metadata.creationTime,
    );
  }
}
