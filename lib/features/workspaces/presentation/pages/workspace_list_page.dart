import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flowtop/core/constants/app_constants.dart';
import 'package:flowtop/core/widgets/app_empty_state.dart';
import 'package:flowtop/features/auth/presentation/providers/auth_provider.dart';
import 'package:flowtop/features/workspaces/domain/entities/workspace_entity.dart';
import 'package:flowtop/features/workspaces/presentation/providers/workspace_provider.dart';

class WorkspaceListPage extends ConsumerWidget {
  const WorkspaceListPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userId = ref.watch(currentUserProvider)?.uid;

    if (userId == null) {
      return const Center(child: Text('Please sign in to view workspaces.'));
    }

    final workspaces = ref.watch(workspaceListProvider(userId));
    return workspaces.when(
      data: (ws) {
        if (ws.isEmpty) {
          return AppEmptyState(
            title: 'No workspaces',
            subtitle: 'Create your personal workspace or join a team.',
            icon: Icons.workspaces_outlined,
            action: () => context.go(AppRoutes.workspaceCreate),
            actionLabel: AppStrings.createWorkspace,
          );
        }
        return ListView.builder(
          itemCount: ws.length,
          itemBuilder: (_, i) {
            final w = ws[i];
            return Card(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: Color(w.color).withOpacity(0.15),
                  child: const Icon(Icons.workspaces),
                ),
                title: Text(w.name, style: const TextStyle(fontWeight: FontWeight.w600)),
                subtitle: Text(
                  '${w.role.label} • ${w.memberCount} members',
                  style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                ),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => context.go('${AppRoutes.workspaceDetail}/${w.id}'),
              ),
            );
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Error: $e')),
    );
  }
}
