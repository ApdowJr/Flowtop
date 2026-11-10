import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flowtop/features/auth/presentation/providers/auth_provider.dart';

export 'package:flowtop/features/auth/presentation/providers/auth_provider.dart';
export 'package:flowtop/features/tasks/presentation/providers/task_provider.dart';
export 'package:flowtop/features/projects/presentation/providers/project_provider.dart';
export 'package:flowtop/features/workspaces/presentation/providers/workspace_provider.dart';
export 'package:flowtop/features/notifications/presentation/providers/notification_provider.dart';
export 'package:flowtop/features/profile/presentation/providers/profile_provider.dart';
export 'package:flowtop/features/statistics/presentation/providers/statistics_provider.dart';

/// Theme mode provider (light/dark/system).
final themeModeProvider = StateProvider<ThemeMode>((ref) => ThemeMode.system);

/// Currently selected workspace ID (null = no workspace selected).
/// Used by project and task features to scope operations to a workspace.
final selectedWorkspaceProvider = StateProvider<String?>((ref) => null);

/// Listener that resets the selected workspace when the authenticated user changes.
/// Prevents user B from inheriting user A's workspace context after sign-out or
/// account switching. No circular dependency: this provider only reads [authProvider]
/// and writes [selectedWorkspaceProvider]; neither reads this provider.
final selectedWorkspaceAuthListener = Provider((ref) {
  ref.listen(
    authProvider,
    (previous, next) {
      final previousUser = previous?.valueOrNull;
      final nextUser = next.valueOrNull;
      if (previousUser?.uid != nextUser?.uid) {
        ref.read(selectedWorkspaceProvider.notifier).state = null;
      }
    },
  );
});

/// Initialize all dependency injection / providers.
/// In a Riverpod-based architecture, "DI" is handled by providers themselves.
/// This function is a placeholder for future eager initializations (e.g. FCM).
Future<void> initInjectionContainer() async {
  // No eager initialization required; providers are lazy.
}

