import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flowtop/core/constants/app_constants.dart';
import 'package:flowtop/core/theme/app_theme.dart';
import 'package:flowtop/core/widgets/app_loading.dart';
import 'package:flowtop/core/widgets/app_empty_state.dart';
import 'package:flowtop/core/widgets/app_error_state.dart';
import 'package:flowtop/core/widgets/app_button.dart';
import 'package:flowtop/core/di/injection_container.dart';
import 'package:flowtop/features/auth/domain/entities/user_entity.dart';
import 'package:flowtop/features/auth/presentation/providers/auth_provider.dart';
import 'package:flowtop/features/projects/domain/entities/project_entity.dart';
import 'package:flowtop/features/projects/presentation/providers/project_provider.dart';

class ProjectListPage extends ConsumerStatefulWidget {
  const ProjectListPage({super.key});
  @override
  ConsumerState<ProjectListPage> createState() => _ProjectListPageState();
}

class _ProjectListPageState extends ConsumerState<ProjectListPage> {
  @override
  void dispose() { super.dispose(); }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    final selectedWorkspaceId = ref.watch(selectedWorkspaceProvider);

    if (user == null) {
      return const AppEmptyState(
        title: 'Sign in to view projects',
        subtitle: 'Please sign in to see your projects.',
        icon: Icons.folder_outlined,
      );
    }

    if (selectedWorkspaceId == null) {
      return _buildWorkspaceSelector(context, ref, user);
    }

    final projectsAsync = ref.watch(projectListProvider(selectedWorkspaceId));
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(title: const Text(AppStrings.projects)),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.go(AppRoutes.projectCreate),
        label: const Text(AppStrings.addProject),
        icon: const Icon(Icons.add),
      ),
      body: projectsAsync.when(
        data: (projects) {
          if (projects.isEmpty) {
            return AppEmptyState(
              title: AppStrings.noProjects,
              subtitle: 'Create a project to group your tasks.',
              icon: Icons.folder_outlined,
              action: () => context.go(AppRoutes.projectCreate),
              actionLabel: AppStrings.addProject,
            );
          }
          return ListView.builder(
            itemCount: projects.length,
            itemBuilder: (_, i) {
              final p = projects[i];
              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: Color(p.color).withOpacity(0.15),
                    child: Icon(Icons.folder, color: Color(p.color)),
                  ),
                  title: Text(p.name, style: const TextStyle(fontWeight: FontWeight.w600)),
                  subtitle: Text('${p.taskIds.length} tasks', style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => context.go('${AppRoutes.projectDetail}/${p.id}'),
                ),
              );
            },
          );
        },
        loading: () => const AppPageLoading(),
        error: (e, _) => AppErrorState(message: e.toString()),
      ),
    );
  }

  Widget _buildWorkspaceSelector(BuildContext context, WidgetRef ref, UserEntity user) {
    final workspacesAsync = ref.watch(workspaceListProvider(user.uid));

    return workspacesAsync.when(
      data: (workspaces) {
        if (workspaces.isEmpty) {
          return const AppEmptyState(
            title: 'No workspaces',
            subtitle: 'Create or join a workspace to see projects.',
            icon: Icons.workspaces_outlined,
          );
        }
        return Scaffold(
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          appBar: AppBar(title: const Text(AppStrings.projects)),
          body: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: workspaces.length,
            itemBuilder: (context, index) {
              final ws = workspaces[index];
              return Card(
                margin: const EdgeInsets.only(bottom: 8),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: Color(ws.color).withOpacity(0.15),
                    child: Icon(Icons.workspaces, color: Color(ws.color)),
                  ),
                  title: Text(ws.name, style: const TextStyle(fontWeight: FontWeight.w600)),
                  subtitle: Text('${ws.role.label} • ${ws.memberCount} members', style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    ref.read(selectedWorkspaceProvider.notifier).state = ws.id;
                  },
                ),
              );
            },
          ),
        );
      },
      loading: () => const AppPageLoading(),
      error: (e, _) => AppErrorState(message: e.toString()),
    );
  }

}
