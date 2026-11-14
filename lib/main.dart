import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flowtop/core/constants/app_constants.dart';
import 'package:flowtop/core/theme/app_theme.dart';
import 'package:flowtop/core/di/injection_container.dart';
import 'package:flowtop/core/router/app_router.dart';
import 'package:flowtop/firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase (falls back to no-op options if not configured).
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Initialize dependency injection (providers).
  await initInjectionContainer();

  SharedPreferences? preferences;
  try {
    preferences = await SharedPreferences.getInstance();
  } catch (_) {
    // The app remains usable even if local preferences are unavailable.
  }
  final storedTheme = preferences?.getString(AppPrefs.themeMode);
  runApp(ProviderScope(
    overrides: [
      preferencesProvider.overrideWithValue(preferences),
      themeModeProvider.overrideWith((ref) => storedTheme == 'light' ? ThemeMode.light : ThemeMode.dark),
    ],
    child: const FlowTopApp(),
  ));
}

/// Root application widget.
class FlowTopApp extends ConsumerWidget {
  const FlowTopApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Activate the auth-state listener that resets selectedWorkspaceProvider
    // when the authenticated user changes (sign-out, sign-in, account switch).
    // This prevents user B from inheriting user A's workspace context.
    ref.read(selectedWorkspaceAuthListener);
    ref.read(fcmStartupProvider);

    final themeMode = ref.watch(themeModeProvider);

    return MaterialApp.router(
      title: AppStrings.appName,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme(),
      darkTheme: AppTheme.darkTheme(),
      themeMode: themeMode,
      routerConfig: AppRouter.router,
    );
  }
}
