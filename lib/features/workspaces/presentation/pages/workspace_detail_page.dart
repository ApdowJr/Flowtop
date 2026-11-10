import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flowtop/core/constants/app_constants.dart';
import 'package:flowtop/core/theme/app_theme.dart';
import 'package:flowtop/core/widgets/app_loading.dart';
import 'package:flowtop/core/widgets/app_empty_state.dart';
import 'package:flowtop/core/widgets/app_error_state.dart';
import 'package:flowtop/features/workspaces/presentation/providers/workspace_provider.dart';

/// Workspace detail page.
///
/// Shows workspace information and quick navigation to members and invitations.
class WorkspaceDetailPage extends ConsumerWidget {
  final String workspaceId;

  const WorkspaceDetailPage({super.key, required this.workspaceId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Watch members to get member count and workspace context.
    final members = ref.watch(workspaceMembersProvider(workspaceId));

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text(AppStrings.workspace),
      ),
      body: members.when(
        data: (memberList) {
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        AppStrings.workspace,
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Members: ${memberList.length}',
                        style: const TextStyle(
                          fontSize: 16,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 24),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: () =>
                                  context.goNamed('workspaceMembers',
                                      pathParameters: {
                                        'workspaceId': workspaceId
                                      }),
                              icon: const Icon(Icons.people),
                              label: const Text(AppStrings.members),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: () =>
                                  context.goNamed('workspaceInvitations',
                                      pathParameters: {
                                        'workspaceId': workspaceId
                                      }),
                              icon: const Icon(Icons.email_outlined),
                              label: const Text(AppStrings.invitations),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              if (memberList.isEmpty)
                const AppEmptyState(
                  title: 'No members yet',
                  subtitle: 'Invite team members to join this workspace.',
                  icon: Icons.people_outline,
                ),
            ],
          );
        },
        loading: () => const AppPageLoading(message: AppStrings.loading),
        error: (e, _) => AppErrorState(
          message: e.toString(),
          onRetry: () => ref.refresh(workspaceMembersProvider(workspaceId)),
        ),
      ),
    );
  }
}
