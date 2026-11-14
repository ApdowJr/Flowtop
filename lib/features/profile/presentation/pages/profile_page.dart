import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flowtop/core/constants/app_constants.dart';
import 'package:flowtop/core/di/injection_container.dart';

/// Profile and appearance preferences.
class ProfilePage extends ConsumerWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    final mode = ref.watch(themeModeProvider);
    final theme = Theme.of(context);
    final isDark = mode == ThemeMode.dark || (mode == ThemeMode.system && theme.brightness == Brightness.dark);
    final name = user?.displayName?.trim();
    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: ListView(padding: const EdgeInsets.fromLTRB(24, 20, 24, 32), children: [
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(color: theme.cardColor, borderRadius: BorderRadius.circular(24)),
          child: Column(children: [
            CircleAvatar(radius: 34, backgroundColor: theme.colorScheme.primary.withValues(alpha: .12), child: Icon(Icons.person_outline_rounded, size: 34, color: theme.colorScheme.primary)),
            const SizedBox(height: 14),
            Text(name == null || name.isEmpty ? 'Your account' : name, style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700), textAlign: TextAlign.center),
            if (user?.email != null) ...[const SizedBox(height: 4), Text(user!.email!, style: theme.textTheme.bodyMedium, textAlign: TextAlign.center)],
          ]),
        ),
        const SizedBox(height: 16),
        Card(margin: EdgeInsets.zero, child: ListTile(
          leading: const Icon(Icons.edit_outlined),
          title: const Text('Edit profile'),
          subtitle: const Text('Change the name teammates see'),
          trailing: const Icon(Icons.chevron_right_rounded),
          onTap: () => context.go(AppRoutes.profileEdit),
        )),
        const SizedBox(height: 28),
        Text('PREFERENCES', style: theme.textTheme.labelSmall?.copyWith(fontWeight: FontWeight.w700, letterSpacing: 1.1, color: theme.colorScheme.primary)),
        const SizedBox(height: 10),
        Card(margin: EdgeInsets.zero, child: SwitchListTile(
          secondary: Icon(isDark ? Icons.dark_mode_outlined : Icons.light_mode_outlined),
          title: const Text('Dark mode'),
          subtitle: const Text('Adjust the look of your workspace'),
          value: isDark,
          onChanged: (value) {
            ref.read(themeModeProvider.notifier).state = value ? ThemeMode.dark : ThemeMode.light;
            ref.read(preferencesProvider)?.setString(AppPrefs.themeMode, value ? 'dark' : 'light');
          },
        )),
        const SizedBox(height: 28),
        OutlinedButton.icon(
          onPressed: () async {
            final confirmed = await showDialog<bool>(context: context, builder: (context) => AlertDialog(
              title: const Text('Sign out?'),
              content: const Text('You can sign back in whenever you are ready.'),
              actions: [TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')), TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Sign out'))],
            ));
            if (confirmed != true || !context.mounted) return;
            await ref.read(authProvider.notifier).signOut();
            if (!context.mounted) return;
            if (ref.read(authProvider).hasError) {
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Could not sign out. Please try again.')));
            } else {
              context.go(AppRoutes.signIn);
            }
          },
          icon: const Icon(Icons.logout_rounded), label: const Text('Sign out'),
        ),
      ]),
    );
  }
}
