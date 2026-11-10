import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flowtop/core/constants/app_constants.dart';
import 'package:flowtop/core/widgets/app_text_field.dart';
import 'package:flowtop/core/widgets/app_button.dart';
import 'package:flowtop/features/auth/presentation/providers/auth_provider.dart';

/// Email/password sign-in screen with Google Sign-In option.
class SignInPage extends ConsumerStatefulWidget {
  const SignInPage({super.key});

  @override
  ConsumerState<SignInPage> createState() => _SignInPageState();
}

class _SignInPageState extends ConsumerState<SignInPage> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _obscure = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _signIn() async {
    if (!_formKey.currentState!.validate()) return;
    await ref.read(authProvider.notifier).signInWithEmailPassword(
      email: _emailController.text.trim(),
      password: _passwordController.text,
    );
    if (mounted && ref.read(authProvider).valueOrNull != null) {
      context.go(AppRoutes.dashboard);
    }
  }

  Future<void> _signInWithGoogle() async {
    try {
      final googleSignIn = ref.read(googleSignInProvider);
      final account = await googleSignIn.signIn();
      if (account == null) {
        // User cancelled the sign-in flow.
        return;
      }
      final authentication = await account.authentication;
      final idToken = authentication.idToken;
      final accessToken = authentication.accessToken;
      if (idToken == null || accessToken == null) {
        throw FirebaseAuthException(
          code: 'missing-google-token',
          message: 'Google sign-in returned no tokens.',
        );
      }
      await ref.read(authProvider.notifier).signInWithGoogle(
        idToken: idToken,
        accessToken: accessToken,
      );
      if (mounted && ref.read(authProvider).valueOrNull != null) {
        context.go(AppRoutes.dashboard);
      }
    } on FirebaseAuthException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.message ?? 'Google sign-in failed.'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } on PlatformException catch (e) {
      if (mounted) {
        final isConfigurationError = e.code == 'sign_in_failed' &&
            (e.message?.contains('ApiException: 10') ?? false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(isConfigurationError
                ? 'Google sign-in is not configured for this app build. Please contact support.'
                : 'Google sign-in failed. Please try again.'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Google sign-in failed. Please try again.')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final loading = authState.isLoading;
    final error = authState.error;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go(AppRoutes.auth),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Sign in',
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w700,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Welcome back to flowTop',
                style: TextStyle(fontSize: 15, color: Theme.of(context).colorScheme.onSurfaceVariant),
              ),
              const SizedBox(height: 32),
              AppTextField(
                label: AppStrings.email,
                hint: 'you@example.com',
                icon: Icons.email_outlined,
                keyboardType: TextInputType.emailAddress,
                textInputAction: TextInputAction.next,
                controller: _emailController,
                validator: (value) {
                  if (value == null || value.isEmpty) return AppStrings.emailRequired;
                  if (!RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(value.trim())) {
                    return AppStrings.validEmail;
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              AppTextField(
                label: AppStrings.password,
                hint: '••••••••',
                icon: Icons.lock_outlined,
                obscureText: _obscure,
                suffixIcon: IconButton(
                  tooltip: _obscure ? 'Show password' : 'Hide password',
                  icon: Icon(_obscure ? Icons.visibility : Icons.visibility_off),
                  onPressed: () => setState(() => _obscure = !_obscure),
                ),
                controller: _passwordController,
                validator: (value) {
                  if (value == null || value.isEmpty) return AppStrings.passwordRequired;
                  if (value.length < 6) return AppStrings.passwordTooShort;
                  return null;
                },
                textInputAction: TextInputAction.done,
                onFieldSubmitted: (_) => _signIn(),
              ),
              if (error != null) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.error.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppColors.error.withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.error_outline, size: 18, color: AppColors.error),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _authErrorMessage(error),
                          style: const TextStyle(fontSize: 13, color: AppColors.error),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 24),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: loading ? null : () => context.go(AppRoutes.resetPassword),
                  child: Text(
                    AppStrings.forgotPassword,
                    style: TextStyle(fontSize: 14, color: Theme.of(context).colorScheme.primary),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              AppButton(
                text: AppStrings.signIn,
                loading: loading,
                onPressed: _signIn,
              ),
              const SizedBox(height: 16),
              const SizedBox(
                height: 1,
                width: double.infinity,
                child: ColoredBox(color: AppColors.divider),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text("Don't have an account?"),
                  TextButton(
                    onPressed: loading ? null : () => context.go(AppRoutes.signUp),
                    child: const Text(AppStrings.signUp),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(child: Divider(color: AppColors.divider)),
                  const SizedBox(width: 12),
                  const Text('Or', style: TextStyle(fontSize: 13, color: AppColors.textSecondary)),
                  const SizedBox(width: 12),
                  Expanded(child: Divider(color: AppColors.divider)),
                ],
              ),
              const SizedBox(height: 16),
              AppOutlinedButton(
                text: AppStrings.signInWithGoogle,
                icon: const Icon(Icons.g_mobiledata, size: 24),
                onPressed: loading ? null : _signInWithGoogle,
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _authErrorMessage(Object error) {
    if (error is FirebaseAuthException) {
      switch (error.code) {
        case 'user-not-found':
        case 'wrong-password':
        case 'invalid-credential':
          return 'Invalid email or password.';
        case 'invalid-email':
          return 'Please enter a valid email.';
        case 'user-disabled':
          return 'This account has been disabled.';
        case 'too-many-requests':
          return 'Too many failed attempts. Try again later.';
        default:
          return error.message ?? 'Sign-in failed.';
      }
    }
    return 'An unexpected error occurred.';
  }
}
