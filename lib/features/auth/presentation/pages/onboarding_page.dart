import 'package:flutter/material.dart';
import 'package:flowtop/core/constants/app_constants.dart';
import 'package:flowtop/core/widgets/app_button.dart';
import 'package:go_router/go_router.dart';

/// Onboarding walkthrough (3 premium purple slides).
class OnboardingPage extends StatefulWidget {
  const OnboardingPage({super.key});

  @override
  State<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends State<OnboardingPage> {
  int _page = 0;
  final _controller = PageController(initialPage: 0);

  static const List<_Slide> _slides = [
    _Slide(
      title: AppStrings.onboardingTitle1,
      body: AppStrings.onboardingBody1,
      icon: Icons.list_alt,
    ),
    _Slide(
      title: AppStrings.onboardingTitle2,
      body: AppStrings.onboardingBody2,
      icon: Icons.people,
    ),
    _Slide(
      title: AppStrings.onboardingTitle3,
      body: AppStrings.onboardingBody3,
      icon: Icons.notifications,
    ),
  ];

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isLast = _page == _slides.length - 1;
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Column(
        children: [
          Expanded(
            child: PageView.builder(
              controller: _controller,
              onPageChanged: (i) => setState(() => _page = i),
              itemCount: _slides.length,
              itemBuilder: (_, i) {
                final slide = _slides[i];
                return Padding(
                  padding: const EdgeInsets.all(32),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(slide.icon, size: 72, color: AppColors.primary),
                      ),
                      const SizedBox(height: 40),
                      Text(
                        slide.title,
                        style: const TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        slide.body,
                        style: const TextStyle(
                          fontSize: 16,
                          color: AppColors.textSecondary,
                          height: 1.5,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
          // Page indicators
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(_slides.length, (i) {
              return AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                margin: const EdgeInsets.symmetric(horizontal: 6),
                width: _page == i ? 24 : 8,
                height: 8,
                decoration: BoxDecoration(
                  color: _page == i ? AppColors.primary : AppColors.divider,
                  borderRadius: BorderRadius.circular(4),
                ),
              );
            }),
          ),
          const SizedBox(height: 40),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 8),
            child: isLast
                ? AppButton(text: AppStrings.getStarted, onPressed: () {
                    context.go(AppRoutes.signIn);
                  })
                : Row(
                    children: [
                      Expanded(
                        child: AppOutlinedButton(
                          text: AppStrings.cancel,
                          onPressed: () => _controller.jumpToPage(_slides.length - 1),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: AppButton(
                          text: AppStrings.getStarted,
                          onPressed: () => _controller.nextPage(
                            duration: const Duration(milliseconds: 300),
                            curve: Curves.ease,
                          ),
                        ),
                      ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }
}

class _Slide {
  const _Slide({required this.title, required this.body, required this.icon});
  final String title;
  final String body;
  final IconData icon;
}
