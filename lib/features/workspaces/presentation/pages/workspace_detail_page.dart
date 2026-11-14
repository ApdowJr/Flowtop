import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flowtop/core/constants/app_constants.dart';
import 'package:flowtop/core/di/injection_container.dart';
import 'package:flowtop/core/widgets/app_loading.dart';
import 'package:flowtop/core/widgets/app_error_state.dart';
import 'package:flowtop/features/workspaces/domain/entities/workspace_entity.dart';

/// Workspace detail page.
///
/// Shows what the workspace is, who is in it and what the signed-in user can do
/// there: open the members, invite people, rename it or delete it.
class WorkspaceDetailPage extends ConsumerWidget {
  final String workspaceId;

  const WorkspaceDetailPage({super.key, required this.workspaceId});

  void _showMessage(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _edit(
    BuildContext context,
    WidgetRef ref,
    String? userId,
    WorkspaceEntity workspace,
  ) async {
    final result = await showDialog<_WorkspaceEdit>(
      context: context,
      builder: (_) => _EditWorkspaceDialog(workspace: workspace),
    );
    if (result == null || !context.mounted) return;
    try {
      await ref.read(workspaceListProvider(userId).notifier).updateWorkspace(
            workspaceId,
            workspace.copyWith(name: result.name, description: result.description),
          );
      if (!context.mounted) return;
      _showMessage(context, 'Workspace updated');
    } catch (_) {
      if (!context.mounted) return;
      _showMessage(context, 'Could not update the workspace. Please try again.');
    }
  }

  Future<void> _delete(
    BuildContext context,
    WidgetRef ref,
    String? userId,
    WorkspaceEntity workspace,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text('Delete ${workspace.name}?'),
        content: const Text(
          'Every task, project and member of this workspace is deleted for '
          'everyone. This cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            style: TextButton.styleFrom(
              foregroundColor: Theme.of(dialogContext).colorScheme.error,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;
    try {
      await ref.read(workspaceListProvider(userId).notifier).deleteWorkspace(workspaceId);
      if (!context.mounted) return;
      if (ref.read(selectedWorkspaceProvider) == workspaceId) {
        ref.read(selectedWorkspaceProvider.notifier).state = null;
      }
      _showMessage(context, 'Workspace deleted');
      context.go(AppRoutes.workspaces);
    } catch (_) {
      if (!context.mounted) return;
      _showMessage(context, 'Could not delete the workspace. Please try again.');
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final userId = ref.watch(currentUserProvider)?.uid;
    final members = ref.watch(workspaceMembersProvider(workspaceId));
    final selected = ref.watch(selectedWorkspaceProvider) == workspaceId;
    final role = ref.watch(myWorkspaceRoleProvider(workspaceId));
    final workspace = _find(ref.watch(workspaceListProvider(userId)).valueOrNull);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(title: Text(workspace?.name ?? AppStrings.workspace)),
      body: members.when(
        data: (memberList) {
          final color = Color(workspace?.color ?? 0xFF7C3AED);
          final description = workspace?.description ?? '';
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Card(
                margin: EdgeInsets.zero,
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 52,
                            height: 52,
                            decoration: BoxDecoration(
                              color: color.withValues(alpha: .14),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Icon(Icons.workspaces_outlined, color: color),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  workspace?.name ?? AppStrings.workspace,
                                  style: theme.textTheme.titleLarge
                                      ?.copyWith(fontWeight: FontWeight.w700),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  '${memberList.length} ${memberList.length == 1 ? 'member' : 'members'}'
                                  '${role == null ? '' : ' • You are ${_withArticle(role)}'}',
                                  style: theme.textTheme.bodySmall,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      if (description.isNotEmpty) ...[
                        const SizedBox(height: 16),
                        Text(description, style: theme.textTheme.bodyMedium),
                      ],
                      const SizedBox(height: 20),
                      Wrap(
                        spacing: 10,
                        runSpacing: 10,
                        children: [
                          FilledButton.tonalIcon(
                            onPressed: selected || workspace == null
                                ? null
                                : () => ref.read(selectedWorkspaceProvider.notifier).state =
                                    workspaceId,
                            icon: Icon(selected
                                ? Icons.check_circle_rounded
                                : Icons.radio_button_unchecked_rounded),
                            label: Text(selected ? 'Active workspace' : 'Make active'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Card(
                margin: EdgeInsets.zero,
                child: Column(
                  children: [
                    ListTile(
                      leading: const Icon(Icons.people_outline_rounded),
                      title: const Text(AppStrings.members),
                      subtitle: const Text('See who is in this workspace and what they can do'),
                      trailing: const Icon(Icons.chevron_right_rounded),
                      onTap: () => context.goNamed(
                        'workspaceMembers',
                        pathParameters: {'workspaceId': workspaceId},
                      ),
                    ),
                    const Divider(height: 1),
                    ListTile(
                      leading: const Icon(Icons.person_add_alt_1_outlined),
                      title: const Text('Invite people'),
                      subtitle: Text(role != null && role.canInvite
                          ? 'Send an invitation by email'
                          : 'See the invitations that were sent'),
                      trailing: const Icon(Icons.chevron_right_rounded),
                      onTap: () => context.goNamed(
                        'workspaceInvitations',
                        pathParameters: {'workspaceId': workspaceId},
                      ),
                    ),
                    if (workspace != null && role != null && role.canChangeRoles) ...[
                      const Divider(height: 1),
                      ListTile(
                        leading: const Icon(Icons.edit_outlined),
                        title: const Text('Rename workspace'),
                        subtitle: const Text('Change the name and description'),
                        trailing: const Icon(Icons.chevron_right_rounded),
                        onTap: () => _edit(context, ref, userId, workspace),
                      ),
                    ],
                    if (workspace != null && role == WorkspaceRole.owner) ...[
                      const Divider(height: 1),
                      ListTile(
                        leading: Icon(Icons.delete_outline_rounded, color: theme.colorScheme.error),
                        title: Text(
                          'Delete workspace',
                          style: TextStyle(color: theme.colorScheme.error),
                        ),
                        subtitle: const Text('Remove the workspace and everything in it'),
                        onTap: () => _delete(context, ref, userId, workspace),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          );
        },
        loading: () => const AppLoading(message: AppStrings.loading),
        error: (_, __) => AppErrorState(
          message: 'Could not load this workspace. Please try again.',
          onRetry: () => ref.invalidate(workspaceMembersProvider(workspaceId)),
        ),
      ),
    );
  }

  /// The workspace with [workspaceId] in [workspaces], if it is known.
  WorkspaceEntity? _find(List<WorkspaceEntity>? workspaces) {
    if (workspaces == null) return null;
    for (final candidate in workspaces) {
      if (candidate.id == workspaceId) return candidate;
    }
    return null;
  }

  static String _withArticle(WorkspaceRole role) {
    final label = role.label.toLowerCase();
    return (role == WorkspaceRole.admin || role == WorkspaceRole.owner) ? 'an $label' : 'a $label';
  }
}

/// The values entered in the rename dialog.
class _WorkspaceEdit {
  const _WorkspaceEdit(this.name, this.description);

  final String name;
  final String description;
}

class _EditWorkspaceDialog extends StatefulWidget {
  const _EditWorkspaceDialog({required this.workspace});

  final WorkspaceEntity workspace;

  @override
  State<_EditWorkspaceDialog> createState() => _EditWorkspaceDialogState();
}

class _EditWorkspaceDialogState extends State<_EditWorkspaceDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _name;
  late final TextEditingController _description;

  @override
  void initState() {
    super.initState();
    _name = TextEditingController(text: widget.workspace.name);
    _description = TextEditingController(text: widget.workspace.description);
  }

  @override
  void dispose() {
    _name.dispose();
    _description.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    Navigator.pop(
      context,
      _WorkspaceEdit(_name.text.trim(), _description.text.trim()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Rename workspace'),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: _name,
              autofocus: true,
              textInputAction: TextInputAction.next,
              decoration: const InputDecoration(labelText: 'Name'),
              validator: (value) {
                final text = value?.trim() ?? '';
                if (text.isEmpty) return 'Enter a name';
                if (text.length > 60) return 'Use 60 characters or fewer';
                return null;
              },
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _description,
              maxLines: 3,
              decoration: const InputDecoration(labelText: 'Description'),
              validator: (value) =>
                  (value?.trim().length ?? 0) > 300 ? 'Use 300 characters or fewer' : null,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
        TextButton(onPressed: _submit, child: const Text('Save')),
      ],
    );
  }
}
