import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flowtop/core/constants/app_constants.dart';
import 'package:flowtop/core/di/injection_container.dart';
import 'package:flowtop/core/widgets/app_button.dart';
import 'package:flowtop/core/widgets/app_error_state.dart';
import 'package:flowtop/core/widgets/app_loading.dart';
import 'package:flowtop/core/widgets/app_text_field.dart';
import 'package:flowtop/features/workspaces/domain/entities/workspace_entity.dart';
import 'package:flowtop/features/workspaces/domain/entities/workspace_invitation_entity.dart';

/// Invite people to a workspace and follow the invitations that were sent.
///
/// Owners, admins and managers can send and withdraw invitations. Every other
/// member can only see them.
class WorkspaceInvitationsPage extends ConsumerStatefulWidget {
  final String workspaceId;

  const WorkspaceInvitationsPage({super.key, required this.workspaceId});

  @override
  ConsumerState<WorkspaceInvitationsPage> createState() =>
      _WorkspaceInvitationsPageState();
}

class _WorkspaceInvitationsPageState
    extends ConsumerState<WorkspaceInvitationsPage> {
  /// People can be invited with any role except owner.
  static const List<WorkspaceRole> _invitableRoles = [
    WorkspaceRole.admin,
    WorkspaceRole.manager,
    WorkspaceRole.member,
    WorkspaceRole.viewer,
  ];

  static final RegExp _emailPattern = RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$');

  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  WorkspaceRole _role = WorkspaceRole.member;
  bool _sending = false;

  @override
  void dispose() {
    _email.dispose();
    super.dispose();
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _send() async {
    if (_sending || !_formKey.currentState!.validate()) return;
    final user = ref.read(currentUserProvider);
    if (user == null) return;
    setState(() => _sending = true);
    try {
      await ref.read(workspaceRepositoryProvider).inviteMember(
            widget.workspaceId,
            _email.text.trim(),
            _role,
            invitedBy: user.uid,
          );
      if (!mounted) return;
      _email.clear();
      _showMessage('Invitation sent');
    } on FirebaseFunctionsException catch (error) {
      if (!mounted) return;
      final message = error.message;
      _showMessage(message != null && message.isNotEmpty
          ? message
          : 'Could not send the invitation. Please try again.');
    } catch (_) {
      if (!mounted) return;
      _showMessage('Could not send the invitation. Please try again.');
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  Future<void> _revoke(WorkspaceInvitationEntity invitation) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Withdraw invitation?'),
        content: Text('${invitation.email} will no longer be able to join with this invitation.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Keep'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Withdraw'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    try {
      await ref
          .read(workspaceRepositoryProvider)
          .revokeInvitation(widget.workspaceId, invitation.id);
      if (!mounted) return;
      _showMessage('Invitation withdrawn');
    } catch (_) {
      if (!mounted) return;
      _showMessage('Could not withdraw the invitation. Please try again.');
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final role = ref.watch(myWorkspaceRoleProvider(widget.workspaceId));
    final canInvite = role?.canInvite ?? false;
    final invitations = ref.watch(workspaceInvitationsProvider(widget.workspaceId));

    return Scaffold(
      appBar: AppBar(title: const Text('Invite people')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
        children: [
          if (canInvite)
            Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Add someone to this workspace',
                    style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'They get the invitation under Spaces once they have verified their email.',
                    style: theme.textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 18),
                  AppTextField(
                    label: 'Email address',
                    hint: 'name@example.com',
                    icon: Icons.mail_outline_rounded,
                    controller: _email,
                    keyboardType: TextInputType.emailAddress,
                    textInputAction: TextInputAction.done,
                    validator: (value) {
                      final text = value?.trim() ?? '';
                      if (text.isEmpty) return 'Enter an email address';
                      if (!_emailPattern.hasMatch(text)) return 'Enter a valid email address';
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  Text('Role', style: theme.textTheme.labelLarge),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (final option in _invitableRoles)
                        ChoiceChip(
                          label: Text(option.label),
                          selected: _role == option,
                          onSelected: (_) => setState(() => _role = option),
                        ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  AppButton(
                    text: 'Send invitation',
                    loading: _sending,
                    onPressed: _send,
                  ),
                ],
              ),
            )
          else if (role != null)
            Card(
              margin: EdgeInsets.zero,
              child: ListTile(
                leading: const Icon(Icons.lock_outline_rounded),
                title: const Text('Only owners, admins and managers can invite people'),
                subtitle: Text('You are a ${role.label.toLowerCase()} of this workspace.'),
              ),
            ),
          const SizedBox(height: 28),
          Text(
            'SENT INVITATIONS',
            style: theme.textTheme.labelSmall?.copyWith(
              fontWeight: FontWeight.w700,
              letterSpacing: 1.1,
              color: theme.colorScheme.primary,
            ),
          ),
          const SizedBox(height: 10),
          invitations.when(
            loading: () => const Padding(
              padding: EdgeInsets.symmetric(vertical: 32),
              child: AppLoading(message: AppStrings.loading),
            ),
            error: (_, __) => AppErrorState(
              message: 'Could not load the invitations. Please try again.',
              onRetry: () => ref.invalidate(workspaceInvitationsProvider(widget.workspaceId)),
            ),
            data: (list) {
              if (list.isEmpty) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 24),
                  child: Text(
                    'No invitations yet.',
                    style: theme.textTheme.bodyMedium,
                    textAlign: TextAlign.center,
                  ),
                );
              }
              final now = DateTime.now();
              return Column(
                children: [
                  for (final invitation in list)
                    _SentInvitationTile(
                      invitation: invitation,
                      now: now,
                      onRevoke: canInvite && invitation.isOpenAt(now)
                          ? () => _revoke(invitation)
                          : null,
                    ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

class _SentInvitationTile extends StatelessWidget {
  const _SentInvitationTile({
    required this.invitation,
    required this.now,
    required this.onRevoke,
  });

  final WorkspaceInvitationEntity invitation;
  final DateTime now;
  final VoidCallback? onRevoke;

  String get _statusLabel {
    switch (invitation.status) {
      case InvitationStatus.accepted:
        return 'Accepted';
      case InvitationStatus.declined:
        return 'Declined';
      case InvitationStatus.pending:
        return invitation.isExpiredAt(now) ? 'Expired' : 'Pending';
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: theme.colorScheme.primary.withValues(alpha: .12),
          child: Icon(Icons.mail_outline_rounded, color: theme.colorScheme.primary),
        ),
        title: Text(
          invitation.email,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Text('${invitation.role.label} • $_statusLabel'),
        trailing: onRevoke == null
            ? null
            : IconButton(
                tooltip: 'Withdraw invitation',
                icon: const Icon(Icons.close_rounded),
                onPressed: onRevoke,
              ),
      ),
    );
  }
}
