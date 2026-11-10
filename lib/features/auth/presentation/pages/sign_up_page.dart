import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flowtop/core/constants/app_constants.dart';
import 'package:flowtop/core/widgets/app_text_field.dart';
import 'package:flowtop/core/widgets/app_button.dart';
import 'package:flowtop/features/auth/presentation/providers/auth_provider.dart';

/// Email/password registration screen.
class SignUpPage extends ConsumerStatefulWidget {
  const SignUpPage({super.key});

  @override
  ConsumerState<SignUpPage> createState() => _SignUpPageState();
}

class _SignUpPageState extends ConsumerState<SignUpPage> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _displayNameController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _obscure = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _displayNameController.dispose();
    super.dispose();
  }

  Future<void> _signUp() async {
    if (!_formKey.currentState!.validate()) return;
    await ref.read(authProvider.notifier).registerWithEmailPassword(
      email: _emailController.text.trim(),
      password: _passwordController.text,
      displayName: _displayNameController.text.trim().isEmpty
          ? null
          : _displayNameController.text.trim(),
    );
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
                'Create account',
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Join flowTop and start organizing your tasks.',
                style: TextStyle(fontSize: 15, color: AppColors.textSecondary),
              ),
              const SizedBox(height: 32),
              AppTextField(
                label: 'Full name',
                hint: 'Jane Doe',
                icon: Icons.person_outlined,
                textInputAction: TextInputAction.next,
                controller: _displayNameController,
              ),
              const SizedBox(height: 16),
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
                textInputAction: TextInputAction.next,
                validator: (value) {
                  if (value == null || value.isEmpty) return AppStrings.passwordRequired;
                  if (value.length < 6) return AppStrings.passwordTooShort;
                  return null;
                },
              ),
              const SizedBox(height: 16),
              AppTextField(
                label: AppStrings.confirmPassword,
                hint: '••••••••',
                icon: Icons.lock_outlined,
                obscureText: _obscure,
                suffixIcon: IconButton(
                  icon: Icon(_obscure ? Icons.visibility : Icons.visibility_off),
                  onPressed: () => setState(() => _obscure = !_obscure),
                ),
                controller: _confirmPasswordController,
                textInputAction: TextInputAction.done,
                onFieldSubmitted: (_) => _signUp(),
                validator: (value) {
                  if (value == null || value.isEmpty) return AppStrings.passwordRequired;
                  if (value != _passwordController.text) {
                    return AppStrings.passwordsDoNotMatch;
                  }
                  return null;
                },
              ),
              if (error != null) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.error.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppColors.error.withOpacity(0.3)),
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
              AppButton(
                text: AppStrings.signUp,
                loading: loading,
                onPressed: _signUp,
              ),
              const SizedBox(height: 16),
              Align(
                alignment: Alignment.center,
                child: RichText(
                  text: TextSpan(
                    style: const TextStyle(fontSize: 14, color: AppColors.textSecondary),
                    children: [
                      const TextSpan(text: 'Already have an account?  '),
                      TextSpan(
                        text: AppStrings.signIn,
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
            ],
          ),
        ),
      ),
    );
  }

  String _authErrorMessage(Object error) {
    if (error is FirebaseAuthException) {
      switch (error.code) {
        case 'email-already-in-use':
          return 'An account already exists for this email.';
        case 'invalid-email':
          return 'Please enter a valid email.';
        case 'operation-not-allowed':
          return 'Email/password accounts are not enabled.';
        case 'weak-password':
          return 'Please choose a stronger password.';
        case 'too-many-requests':
          return 'Too many failed attempts. Try again later.';
        default:
          return error.message ?? 'Registration failed.';
      }
    }
    return 'An unexpected error occurred.';
  }
}
