import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flowtop/core/constants/app_constants.dart';
import 'package:flowtop/core/di/injection_container.dart';
import 'package:flowtop/core/widgets/app_empty_state.dart';
import 'package:flowtop/core/widgets/app_error_state.dart';
import 'package:flowtop/core/widgets/app_loading.dart';
import 'package:flowtop/features/workspaces/domain/entities/workspace_entity.dart';

/// Members of a workspace with their roles.
///
/// Owners and admins can change roles and remove people. Everybody except the
/// owner can leave the workspace.
class WorkspaceMembersPage extends ConsumerWidget {
  final String workspaceId;

  const WorkspaceMembersPage({super.key, required this.workspaceId});

  /// Roles that can be handed out. Ownership cannot be transferred here.
  static const List<WorkspaceRole> _assignableRoles = [
    WorkspaceRole.admin,
    WorkspaceRole.manager,
    WorkspaceRole.member,
    WorkspaceRole.viewer,
  ];

  void _showMessage(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _changeRole(
    BuildContext context,
    WidgetRef ref,
    WorkspaceMemberEntity member,
  ) async {
    final choice = await showDialog<WorkspaceRole>(
      context: context,
      builder: (dialogContext) => SimpleDialog(
        title: Text('Role for ${member.label}'),
        children: [
          for (final role in _assignableRoles)
            SimpleDialogOption(
              onPressed: () => Navigator.pop(dialogContext, role),
              child: Row(
                children: [
                  Expanded(child: Text(role.label)),
                  if (role == member.role) const Icon(Icons.check_rounded, size: 20),
                ],
              ),
            ),
        ],
      ),
    );
    if (choice == null || choice == member.role || !context.mounted) return;
    try {
      await ref
          .read(workspaceMembersProvider(workspaceId).notifier)
          .changeRole(member.userId, choice);
      if (!context.mounted) return;
      _showMessage(context, '${member.label} is now ${choice.label.toLowerCase()}');
    } catch (_) {
      if (!context.mounted) return;
      _showMessage(context, 'Could not change the role. Please try again.');
    }
  }

  Future<void> _remove(
    BuildContext context,
    WidgetRef ref,
    WorkspaceMemberEntity member,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text('Remove ${member.label}?'),
        content: const Text('They will lose access to this workspace, its tasks and projects.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Remove'),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;
    try {
      await ref
          .read(workspaceMembersProvider(workspaceId).notifier)
          .removeMember(member.userId);
      if (!context.mounted) return;
      _showMessage(context, '${member.label} was removed');
    } catch (_) {
      if (!context.mounted) return;
      _showMessage(context, 'Could not remove this member. Please try again.');
    }
  }

  Future<void> _leave(BuildContext context, WidgetRef ref, String userId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Leave this workspace?'),
        content: const Text('You will need a new invitation to come back.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Stay'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Leave'),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;
    try {
      await ref
          .read(workspaceMembersProvider(workspaceId).notifier)
          .removeMember(userId);
      if (!context.mounted) return;
      if (ref.read(selectedWorkspaceProvider) == workspaceId) {
        ref.read(selectedWorkspaceProvider.notifier).state = null;
      }
      context.go(AppRoutes.workspaces);
    } catch (_) {
      if (!context.mounted) return;
      _showMessage(context, 'Could not leave the workspace. Please try again.');
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final members = ref.watch(workspaceMembersProvider(workspaceId));
    final me = ref.watch(currentUserProvider);
    final myRole = ref.watch(myWorkspaceRoleProvider(workspaceId));

    return Scaffold(
      appBar: AppBar(
        title: const Text(AppStrings.members),
        actions: [
          if (myRole != null && myRole.canInvite)
            IconButton(
              tooltip: 'Invite people',
              icon: const Icon(Icons.person_add_alt_1_outlined),
              onPressed: () => context.go('${AppRoutes.workspaceInvitations}/$workspaceId'),
            ),
        ],
      ),
      body: members.when(
        loading: () => const AppLoading(message: AppStrings.loading),
        error: (_, __) => AppErrorState(
          message: 'Could not load the members. Please try again.',
          onRetry: () => ref.invalidate(workspaceMembersProvider(workspaceId)),
        ),
        data: (memberList) {
          if (memberList.isEmpty) {
            return const AppEmptyState(
              title: 'No members',
              subtitle: 'This workspace has no members yet.',
              icon: Icons.people_outline,
            );
          }
          final sorted = [...memberList]..sort((a, b) {
              final byRole = a.role.index.compareTo(b.role.index);
              if (byRole != 0) return byRole;
              return a.label.toLowerCase().compareTo(b.label.toLowerCase());
            });
          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
            children: [
              for (final member in sorted)
                _MemberTile(
                  member: member,
                  isMe: member.userId == me?.uid,
                  fallbackName: me?.displayName ?? me?.email,
                  canManage: myRole != null &&
                      myRole.canChangeRoles &&
                      member.userId != me?.uid &&
                      (myRole == WorkspaceRole.owner || member.role != WorkspaceRole.owner),
                  onChangeRole: () => _changeRole(context, ref, member),
                  onRemove: () => _remove(context, ref, member),
                ),
              if (me != null && myRole != null && myRole != WorkspaceRole.owner) ...[
                const SizedBox(height: 20),
                OutlinedButton.icon(
                  onPressed: () => _leave(context, ref, me.uid),
                  icon: const Icon(Icons.logout_rounded),
                  label: const Text('Leave workspace'),
                  style: OutlinedButton.styleFrom(foregroundColor: theme.colorScheme.error),
                ),
              ],
            ],
          );
        },
      ),
    );
  }
}

class _MemberTile extends StatelessWidget {
  const _MemberTile({
    required this.member,
    required this.isMe,
    required this.fallbackName,
    required this.canManage,
    required this.onChangeRole,
    required this.onRemove,
  });

  final WorkspaceMemberEntity member;
  final bool isMe;

  /// Name to show for the signed-in user when their record has no name yet.
  final String? fallbackName;
  final bool canManage;
  final VoidCallback onChangeRole;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    var name = member.label;
    if (isMe && member.displayName == null && member.email == null && fallbackName != null) {
      name = fallbackName!;
    }
    final email = member.email;
    final showsEmail = email != null && email.isNotEmpty && email != name;
    final initial = name.trim().isEmpty ? '?' : name.trim().substring(0, 1).toUpperCase();

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: theme.colorScheme.primary.withValues(alpha: .12),
          child: Text(
            initial,
            style: TextStyle(
              color: theme.colorScheme.primary,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        title: Text(
          isMe ? '$name (you)' : name,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Text(
          showsEmail ? '${member.role.label} • $email' : member.role.label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        trailing: canManage
            ? PopupMenuButton<String>(
                tooltip: 'Manage member',
                onSelected: (action) {
                  if (action == 'role') {
                    onChangeRole();
                  } else {
                    onRemove();
                  }
                },
                itemBuilder: (context) => const [
                  PopupMenuItem(value: 'role', child: Text('Change role')),
                  PopupMenuItem(value: 'remove', child: Text('Remove from workspace')),
                ],
              )
            : null,
      ),
    );
  }
}
