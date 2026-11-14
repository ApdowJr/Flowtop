import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flowtop/core/constants/app_constants.dart';
import 'package:flowtop/core/di/injection_container.dart';
import 'package:flowtop/core/widgets/app_empty_state.dart';
import 'package:flowtop/core/widgets/app_error_state.dart';
import 'package:flowtop/core/widgets/app_loading.dart';
import 'package:flowtop/features/workspaces/domain/entities/workspace_entity.dart';
import 'package:flowtop/features/workspaces/domain/entities/workspace_invitation_entity.dart';

/// The invitations other people sent to the signed-in user.
///
/// Invitations are addressed to an email address, so they only show up for
/// users who verified theirs; everybody else gets a card that explains how.
class MyInvitationsPage extends ConsumerStatefulWidget {
  const MyInvitationsPage({super.key});

  @override
  ConsumerState<MyInvitationsPage> createState() => _MyInvitationsPageState();
}

class _MyInvitationsPageState extends ConsumerState<MyInvitationsPage> {
  /// The invitation that is being answered right now, if any.
  String? _busyInvitationId;
  bool _verificationBusy = false;

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  String _describe(Object error, String fallback) {
    if (error is FirebaseFunctionsException) {
      final message = error.message;
      if (message != null && message.isNotEmpty) return message;
    }
    return fallback;
  }

  Future<void> _accept(WorkspaceInvitationEntity invitation) async {
    if (_busyInvitationId != null) return;
    setState(() => _busyInvitationId = invitation.id);
    try {
      await ref
          .read(workspaceRepositoryProvider)
          .acceptInvitation(invitation.workspaceId, invitation.id);
      if (!mounted) return;
      // The first workspace a person joins becomes their active one.
      if (ref.read(selectedWorkspaceProvider) == null) {
        ref.read(selectedWorkspaceProvider.notifier).state = invitation.workspaceId;
      }
      _showMessage('You joined ${invitation.workspaceName ?? 'the workspace'}');
    } catch (error) {
      if (!mounted) return;
      _showMessage(_describe(error, 'Could not accept the invitation. Please try again.'));
    } finally {
      if (mounted) setState(() => _busyInvitationId = null);
    }
  }

  Future<void> _decline(WorkspaceInvitationEntity invitation) async {
    if (_busyInvitationId != null) return;
    setState(() => _busyInvitationId = invitation.id);
    try {
      await ref
          .read(workspaceRepositoryProvider)
          .declineInvitation(invitation.workspaceId, invitation.id);
      if (!mounted) return;
      _showMessage('Invitation declined');
    } catch (error) {
      if (!mounted) return;
      _showMessage(_describe(error, 'Could not decline the invitation. Please try again.'));
    } finally {
      if (mounted) setState(() => _busyInvitationId = null);
    }
  }

  Future<void> _sendVerificationEmail() async {
    if (_verificationBusy) return;
    setState(() => _verificationBusy = true);
    try {
      await ref.read(authProvider.notifier).sendEmailVerification();
      if (!mounted) return;
      _showMessage('Verification email sent. Check your inbox.');
    } catch (_) {
      if (!mounted) return;
      _showMessage('Could not send the email. Please try again later.');
    } finally {
      if (mounted) setState(() => _verificationBusy = false);
    }
  }

  Future<void> _refreshVerification() async {
    if (_verificationBusy) return;
    setState(() => _verificationBusy = true);
    try {
      await ref.read(authProvider.notifier).refreshUser();
      if (!mounted) return;
      if (ref.read(currentUserProvider)?.emailVerified != true) {
        _showMessage('Your email is not verified yet.');
      }
    } catch (_) {
      if (!mounted) return;
      _showMessage('Could not check your email status. Please try again.');
    } finally {
      if (mounted) setState(() => _verificationBusy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProvider);
    final invitations = ref.watch(openInvitationsProvider);
    final stream = ref.watch(myInvitationsProvider);
    final verified = user?.emailVerified ?? false;

    Widget content;
    if (user == null) {
      content = const AppEmptyState(
        title: 'Sign in to see your invitations',
        icon: Icons.mail_outline_rounded,
      );
    } else if (!verified) {
      content = ListView(
        padding: const EdgeInsets.all(20),
        children: [
          _VerifyEmailCard(
            email: user.email,
            busy: _verificationBusy,
            onSend: _sendVerificationEmail,
            onRefresh: _refreshVerification,
          ),
        ],
      );
    } else if (stream.hasError) {
      content = AppErrorState(
        message: 'Could not load your invitations. Please try again.',
        onRetry: () => ref.invalidate(myInvitationsProvider),
      );
    } else if (stream.isLoading && invitations.isEmpty) {
      content = const AppLoading(message: AppStrings.loading);
    } else if (invitations.isEmpty) {
      content = AppEmptyState(
        title: 'No pending invitations',
        subtitle: 'When someone invites ${user.email ?? 'you'} to a workspace, '
            'the invitation shows up here.',
        icon: Icons.mark_email_read_outlined,
      );
    } else {
      content = ListView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
        children: [
          for (final invitation in invitations)
            _InvitationCard(
              invitation: invitation,
              busy: _busyInvitationId == invitation.id,
              enabled: _busyInvitationId == null,
              onAccept: () => _accept(invitation),
              onDecline: () => _decline(invitation),
            ),
        ],
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Invitations')),
      body: content,
    );
  }
}

class _InvitationCard extends StatelessWidget {
  const _InvitationCard({
    required this.invitation,
    required this.busy,
    required this.enabled,
    required this.onAccept,
    required this.onDecline,
  });

  final WorkspaceInvitationEntity invitation;
  final bool busy;
  final bool enabled;
  final VoidCallback onAccept;
  final VoidCallback onDecline;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final inviter = invitation.invitedByName;
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: theme.colorScheme.primary.withValues(alpha: .12),
                  child: Icon(Icons.workspaces_outlined, color: theme.colorScheme.primary),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        invitation.workspaceName ?? 'A workspace',
                        style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        inviter == null
                            ? 'You were invited as ${invitation.role.label}'
                            : '$inviter invited you as ${invitation.role.label}',
                        style: theme.textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: enabled ? onDecline : null,
                    child: const Text('Decline'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton(
                    onPressed: enabled ? onAccept : null,
                    child: busy
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('Accept'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _VerifyEmailCard extends StatelessWidget {
  const _VerifyEmailCard({
    required this.email,
    required this.busy,
    required this.onSend,
    required this.onRefresh,
  });

  final String? email;
  final bool busy;
  final VoidCallback onSend;
  final VoidCallback onRefresh;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(Icons.mark_email_unread_outlined, size: 32, color: theme.colorScheme.primary),
            const SizedBox(height: 14),
            Text(
              'Verify your email to see invitations',
              style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            Text(
              'Invitations are sent to an email address. Confirm that '
              '${email ?? 'your address'} is yours and any invitation waiting for '
              'it will appear here.',
              style: theme.textTheme.bodyMedium,
            ),
            const SizedBox(height: 18),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: busy ? null : onSend,
                child: const Text('Send verification email'),
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: busy ? null : onRefresh,
                child: const Text("I've verified my email"),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
