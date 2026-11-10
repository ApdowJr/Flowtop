import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flowtop/core/constants/app_constants.dart';
import 'package:flowtop/core/widgets/app_loading.dart';
import 'package:flowtop/core/widgets/app_empty_state.dart';
import 'package:flowtop/core/widgets/app_error_state.dart';
import 'package:flowtop/features/workspaces/domain/entities/workspace_entity.dart';
import 'package:flowtop/features/workspaces/presentation/providers/workspace_provider.dart';

/// Members list for a workspace.
///
/// Shows all members of the workspace with their roles.
class WorkspaceMembersPage extends ConsumerWidget {
  final String workspaceId;

  const WorkspaceMembersPage({super.key, required this.workspaceId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final members = ref.watch(workspaceMembersProvider(workspaceId));

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text(AppStrings.members),
      ),
      body: members.when(
        data: (memberList) {
          if (memberList.isEmpty) {
            return const AppEmptyState(
              title: 'No members',
              subtitle: 'This workspace has no members yet.',
              icon: Icons.people_outline,
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: memberList.length,
            itemBuilder: (context, index) {
              final member = memberList[index];
              return Card(
                margin: const EdgeInsets.only(bottom: 8),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: AppColors.primary.withOpacity(0.1),
                    child: const Icon(Icons.person,
                        color: AppColors.primary),
                  ),
                  title: Text(
                    member.userId,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  subtitle: Text(
                    '${member.role.label} • ${member.workspaceId}',
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
              );
            },
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
