import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flowtop/core/constants/app_constants.dart';
import 'package:flowtop/core/di/injection_container.dart';
import 'package:flowtop/core/theme/app_theme.dart';
import 'package:flowtop/core/widgets/app_button.dart';
import 'package:flowtop/features/auth/presentation/providers/auth_provider.dart';

/// Profile and user preferences screen.
class ProfilePage extends ConsumerWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    final themeMode = ref.watch(themeModeProvider);
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(title: const Text(AppStrings.profileTitle)),
      body: ListView(
        children: [
          const SizedBox(height: 20),
          Center(
            child: Column(
              children: [
                const CircleAvatar(radius: 40, backgroundColor: AppColors.surfaceVariant, child: Icon(Icons.person, size: 40, color: AppColors.primary)),
                const SizedBox(height: 12),
                Text(user?.displayName ?? 'User', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
                const SizedBox(height: 4),
                Text(user?.email ?? 'email@example.com', style: const TextStyle(fontSize: 14, color: AppColors.textSecondary)),
              ],
            ),
          ),
          const SizedBox(height: 24),
          ListTile(
            leading: const Icon(Icons.brightness_6, color: AppColors.textSecondary),
            title: const Text(AppStrings.darkMode),
            trailing: Switch(
              value: themeMode == ThemeMode.dark,
              onChanged: (_) => ref.read(themeModeProvider.notifier).state =
                  themeMode == ThemeMode.light ? ThemeMode.dark : ThemeMode.light,
            ),
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.notifications, color: AppColors.textSecondary),
            title: const Text(AppStrings.pushNotifications),
            trailing: const Switch(value: true, onChanged: null),
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.email, color: AppColors.textSecondary),
            title: const Text(AppStrings.emailAddress),
            trailing: const Icon(Icons.chevron_right),
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.person, color: AppColors.textSecondary),
            title: const Text(AppStrings.changePhoto),
            trailing: const Icon(Icons.camera_alt),
          ),
          const Divider(),
          const SizedBox(height: 20),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: AppButton(text: AppStrings.signOut, onPressed: () => ref.read(authProvider.notifier).signOut()),
          ),
        ],
      ),
    );
  }
}
