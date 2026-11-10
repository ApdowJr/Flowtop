import 'package:flutter/material.dart';
import 'package:flowtop/core/constants/app_constants.dart';
import 'package:flowtop/core/theme/app_theme.dart';
import 'package:flowtop/core/widgets/app_button.dart';

/// Entry point for authentication: choose sign in or sign up.
class AuthPage extends StatelessWidget {
  const AuthPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.login, size: 56, color: AppColors.primary),
              ),
              const SizedBox(height: 24),
              const Text(
                'Welcome back to flowTop',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              const Text(
                'Sign in to access your tasks and teams.',
                style: TextStyle(fontSize: 15, color: AppColors.textSecondary),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              AppButton(
                text: AppStrings.signIn,
                onPressed: () => Navigator.of(context).pushNamed(AppRoutes.signIn),
              ),
              const SizedBox(height: 16),
              AppOutlinedButton(
                text: AppStrings.createAccount,
                onPressed: () => Navigator.of(context).pushNamed(AppRoutes.signUp),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(child: Divider(color: AppColors.divider)),
                  const SizedBox(width: 12),
                  const Text(
                    'Or continue with Google',
                    style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
                  ),
                  const SizedBox(width: 12),
                  Expanded(child: Divider(color: AppColors.divider)),
                ],
              ),
              const SizedBox(height: 16),
              AppButton(
                text: AppStrings.signInWithGoogle,
                icon: const Icon(Icons.g_mobiledata, size: 20, color: Colors.white),
                onPressed: () {},
                // Google sign-in is handled on the SignIn page.
              ),
            ],
          ),
        ),
      ),
    );
  }
}
