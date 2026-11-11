import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flowtop/features/notifications/data/datasources/fcm_messaging_service.dart';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flowtop/features/auth/domain/entities/user_entity.dart';
import 'package:flowtop/features/auth/domain/repositories/auth_repository.dart';
import 'package:flowtop/features/auth/data/datasources/auth_remote_datasource.dart';
import 'package:flowtop/features/auth/data/repositories/auth_repository_impl.dart';

/// Firebase Auth + Google Sign-In instances (shared).
final firebaseAuthProvider = Provider<FirebaseAuth>((ref) => FirebaseAuth.instance);
final googleSignInProvider = Provider<GoogleSignIn>((ref) => GoogleSignIn());

/// Keep one messaging service alive for this application session.
final fcmServiceProvider = Provider<FcmMessagingService>((ref) {
  final service = createFcmMessagingService();
  ref.onDispose(() => unawaited(service.dispose()));
  return service;
});

/// Start messaging without preventing the app from opening if FCM is unavailable.
final fcmStartupProvider = Provider<void>((ref) {
  if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) return;
  unawaited(ref.read(fcmServiceProvider).initialize().catchError((Object error) {
    debugPrint('FCM initialization failed: $error');
  }));
});

/// Auth remote data source provider.
final authRemoteDataSourceProvider = Provider<AuthRemoteDataSource>((ref) {
  final auth = ref.watch(firebaseAuthProvider);
  final googleSignIn = ref.watch(googleSignInProvider);
  return AuthRemoteDataSourceImpl(auth, googleSignIn,
    beforeSignOut: !kIsWeb && defaultTargetPlatform == TargetPlatform.android
        ? () => ref.read(fcmServiceProvider).unregisterCurrentDevice()
        : null,
  );
});

/// Auth repository provider.
final authRepositoryProvider = Provider<AuthRepository>((ref) {
  final remote = ref.watch(authRemoteDataSourceProvider);
  final firestore = FirebaseFirestore.instance;
  return AuthRepositoryImpl(remote, firestore);
});

/// Authentication state notifier.
class AuthNotifier extends StateNotifier<AsyncValue<UserEntity?>> {
  AuthNotifier(this._repository) : super(const AsyncValue.loading()) {
    _subscribe();
  }

  final AuthRepository _repository;
  StreamSubscription<UserEntity?>? _subscription;

  void _subscribe() {
    _subscription = _repository.authStateChanges.listen(
      (user) => state = AsyncValue.data(user),
      onError: (error) => state = AsyncValue.error(error, StackTrace.current),
    );
    // Emit the current value immediately.
    state = AsyncValue.data(_repository.currentUser);
  }

  /// Sign in with email and password.
  Future<void> signInWithEmailPassword({
    required String email,
    required String password,
  }) async {
    state = const AsyncValue.loading();
    try {
      final user = await _repository.signInWithEmailPassword(
        email: email,
        password: password,
      );
      state = AsyncValue.data(user);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  /// Register with email and password.
  Future<void> registerWithEmailPassword({
    required String email,
    required String password,
    String? displayName,
  }) async {
    state = const AsyncValue.loading();
    try {
      final user = await _repository.registerWithEmailPassword(
        email: email,
        password: password,
        displayName: displayName,
      );
      state = AsyncValue.data(user);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  /// Sign in with Google using an ID token + access token.
  Future<void> signInWithGoogle({
    required String idToken,
    required String accessToken,
  }) async {
    state = const AsyncValue.loading();
    try {
      final credential = GoogleAuthHelper.fromGoogleSignIn(
        idToken: idToken,
        accessToken: accessToken,
      );
      final user = await _repository.signInWithGoogle(credential);
      state = AsyncValue.data(user);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  /// Send a password-reset email.
  Future<void> sendPasswordResetEmail(String email) async {
    state = const AsyncValue.loading();
    try {
      await _repository.sendPasswordResetEmail(email);
      state = AsyncValue.data(_repository.currentUser);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  /// Sign out.
  Future<void> signOut() async {
    state = const AsyncValue.loading();
    try {
      await _repository.signOut();
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  /// Update the current user's profile.
  Future<void> updateProfile({String? displayName, String? photoUrl}) async {
    state = const AsyncValue.loading();
    try {
      await _repository.updateProfile(displayName: displayName, photoUrl: photoUrl);
      state = AsyncValue.data(_repository.currentUser);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}

/// Provider exposing the authenticated user and auth actions.
final authProvider = StateNotifierProvider<AuthNotifier, AsyncValue<UserEntity?>>(
  (ref) {
    final repository = ref.watch(authRepositoryProvider);
    return AuthNotifier(repository);
  },
);

/// Convenience provider for the current user value.
final currentUserProvider = Provider<UserEntity?>((ref) {
  final async = ref.watch(authProvider);
  return async.valueOrNull;
});

/// Whether a user is currently signed in.
final isSignedInProvider = Provider<bool>((ref) {
  final async = ref.watch(authProvider);
  return async.value != null;
});
