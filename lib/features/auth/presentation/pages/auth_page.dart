import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flowtop/core/constants/app_constants.dart';
import 'package:flowtop/core/widgets/app_button.dart';

/// Entry point for authentication.
class AuthPage extends StatelessWidget {
  const AuthPage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 36),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 440),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [
                  Container(
                    width: 44, height: 44,
                    decoration: BoxDecoration(color: theme.colorScheme.primary, borderRadius: BorderRadius.circular(15)),
                    child: Icon(Icons.check_rounded, color: theme.colorScheme.onPrimary),
                  ),
                  const SizedBox(width: 12),
                  Text('flowTop', style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800)),
                ]),
                const SizedBox(height: 64),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(28),
                  decoration: BoxDecoration(
                    color: theme.cardColor,
                    border: Border.all(color: theme.dividerColor),
                    borderRadius: BorderRadius.circular(28),
                  ),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Icon(Icons.auto_awesome_rounded, color: theme.colorScheme.primary, size: 30),
                    SizedBox(height: 40),
                    Text('Make room for\nyour best work.', style: TextStyle(color: theme.colorScheme.onSurface, fontSize: 29, height: 1.15, fontWeight: FontWeight.w800)),
                    SizedBox(height: 14),
                    Text('Your tasks, projects and people, together in one calm space.', style: TextStyle(color: theme.colorScheme.onSurfaceVariant, fontSize: 15, height: 1.5)),
                  ]),
                ),
                const SizedBox(height: 36),
                Text('Ready to find your flow?', style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700)),
                const SizedBox(height: 8),
                Text('Sign in or create an account to get started.', style: theme.textTheme.bodyMedium),
                const SizedBox(height: 26),
                AppButton(text: AppStrings.signIn, onPressed: () => context.go(AppRoutes.signIn)),
                const SizedBox(height: 12),
                AppOutlinedButton(text: AppStrings.createAccount, onPressed: () => context.go(AppRoutes.signUp)),
                const SizedBox(height: 18),
                Center(child: Text('Google sign-in is available on the next screen', textAlign: TextAlign.center, style: theme.textTheme.bodySmall)),
              ]),
            ),
          ),
        ),
      ),
    );
  }
}
