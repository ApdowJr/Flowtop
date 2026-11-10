import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flowtop/core/constants/app_constants.dart';
import 'package:flowtop/core/di/injection_container.dart';
import 'package:flowtop/core/widgets/app_empty_state.dart';
import 'package:flowtop/core/widgets/app_error_state.dart';
import 'package:flowtop/features/workspaces/domain/entities/workspace_entity.dart';

class WorkspaceListPage extends ConsumerWidget {
  const WorkspaceListPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userId = ref.watch(currentUserProvider)?.uid;
    final selected = ref.watch(selectedWorkspaceProvider);
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Workspaces')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.go(AppRoutes.workspaceCreate),
        icon: const Icon(Icons.add_rounded), label: const Text('New workspace'),
      ),
      body: userId == null
          ? const AppEmptyState(title: 'Sign in to see your workspaces', icon: Icons.workspaces_outlined)
          : ref.watch(workspaceListProvider(userId)).when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (_, __) => AppErrorState(message: 'Could not load your workspaces. Please try again.', onRetry: () => ref.invalidate(workspaceListProvider(userId))),
              data: (workspaces) {
                if (workspaces.isEmpty) {
                  return AppEmptyState(title: 'A space to call yours', subtitle: 'Create a workspace to start organizing your tasks and projects.', icon: Icons.workspaces_outlined,
                      action: () => context.go(AppRoutes.workspaceCreate), actionLabel: 'Create workspace');
                }
                return ListView(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 100),
                  children: [
                    Text('Your spaces', style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700)),
                    const SizedBox(height: 6),
                    Text('Choose where you want to focus.', style: theme.textTheme.bodyMedium),
                    const SizedBox(height: 20),
                    ...workspaces.map((workspace) {
                      final active = selected == workspace.id;
                      final color = Color(workspace.color);
                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        clipBehavior: Clip.antiAlias,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20), side: BorderSide(color: active ? theme.colorScheme.primary : theme.dividerColor, width: active ? 1.5 : 0.5)),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            Row(children: [
                              Container(width: 46, height: 46, decoration: BoxDecoration(color: color.withValues(alpha: .14), borderRadius: BorderRadius.circular(14)), child: Icon(Icons.workspaces_outlined, color: color)),
                              const SizedBox(width: 12),
                              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                Text(workspace.name, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
                                const SizedBox(height: 3),
                                Text(workspace.role.label, style: theme.textTheme.bodySmall),
                              ])),
                              if (active) Icon(Icons.check_circle_rounded, color: theme.colorScheme.primary),
                            ]),
                            if (workspace.description.isNotEmpty) ...[
                              const SizedBox(height: 12),
                              Text(workspace.description, maxLines: 2, overflow: TextOverflow.ellipsis, style: theme.textTheme.bodyMedium),
                            ],
                            const SizedBox(height: 12),
                            Wrap(spacing: 8, children: [
                              FilledButton.tonal(
                                onPressed: active ? null : () => ref.read(selectedWorkspaceProvider.notifier).state = workspace.id,
                                child: Text(active ? 'Selected' : 'Select workspace'),
                              ),
                              TextButton(onPressed: () => context.go('${AppRoutes.workspaceDetail}/${workspace.id}'), child: const Text('Details')),
                            ]),
                          ]),
                        ),
                      );
                    }),
                  ],
                );
              },
            ),
    );
  }
}
