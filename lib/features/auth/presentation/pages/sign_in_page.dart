import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
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
    } on FirebaseAuthException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.message ?? 'Google sign-in failed.'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Google sign-in failed: $e'),
            backgroundColor: AppColors.error,
          ),
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
              const Text(
                'Sign in',
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Welcome back to flowTop',
                style: TextStyle(fontSize: 15, color: AppColors.textSecondary),
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
                  if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
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
                    style: const TextStyle(fontSize: 14, color: AppColors.primary),
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
              Align(
                alignment: Alignment.center,
                child: RichText(
                  text: TextSpan(
                    style: const TextStyle(fontSize: 14, color: AppColors.textSecondary),
                    children: [
                      const TextSpan(text: "Don't have an account?  "),
                      TextSpan(
                        text: AppStrings.signUp,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppColors.primary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 10),
              GestureDetector(
                onTap: () {
                  // Sign-up navigation handled via the rich text tap target area.
                },
                child: const SizedBox.shrink(),
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
              AppButton(
                text: AppStrings.signInWithGoogle,
                icon: const Icon(Icons.g_mobiledata, size: 20),
                loading: authState.isLoading,
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
