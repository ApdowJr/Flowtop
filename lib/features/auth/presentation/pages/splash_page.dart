import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flowtop/core/constants/app_constants.dart';
import 'package:flowtop/core/di/injection_container.dart';

/// Splash screen with the flowTop brand mark.
class SplashPage extends ConsumerStatefulWidget {
  const SplashPage({super.key});

  @override
  ConsumerState<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends ConsumerState<SplashPage> {
  @override
  void initState() {
    super.initState();
    _navigateAfterDelay();
  }

  Future<void> _navigateAfterDelay() async {
    await Future.delayed(const Duration(seconds: 2));
    if (!mounted) return;
    final prefs = ref.read(preferencesProvider);
    if (ref.read(isSignedInProvider)) {
      // Returning users never need the walkthrough, not even after signing out.
      await prefs?.setBool(AppPrefs.onboardingSeen, true);
      if (!mounted) return;
      context.go(AppRoutes.dashboard);
      return;
    }
    // First-time visitors see the walkthrough once. When preferences cannot be
    // read the walkthrough is skipped rather than repeated on every launch.
    final seenOnboarding = prefs?.getBool(AppPrefs.onboardingSeen) ?? true;
    context.go(seenOnboarding ? AppRoutes.signIn : AppRoutes.onboarding);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surfaceDark,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 96,
              height: 96,
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.4),
                    blurRadius: 24,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: const Icon(
                Icons.rocket_launch,
                size: 48,
                color: AppColors.onPrimary,
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              AppStrings.appName,
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.w800,
                color: Colors.white,
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Organize your work. Collaborate with your team.',
              style: TextStyle(fontSize: 14, color: Colors.white70),
            ),
            const SizedBox(height: 40),
            const SizedBox(
              height: 32,
              width: 32,
              child: CircularProgressIndicator(
                strokeWidth: 3,
                valueColor: AlwaysStoppedAnimation(Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
