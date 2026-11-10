import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flowtop/core/constants/app_constants.dart';
import 'package:flowtop/core/theme/app_theme.dart';
import 'package:flowtop/core/widgets/app_loading.dart';
import 'package:flowtop/core/widgets/app_empty_state.dart';
import 'package:flowtop/core/widgets/app_error_state.dart';

/// Pending invitations for a workspace.
///
/// Lists invitations the current user can accept/decline, and allows
/// workspace members with invite rights to send new invitations.
class WorkspaceInvitationsPage extends ConsumerStatefulWidget {
  final String workspaceId;

  const WorkspaceInvitationsPage({super.key, required this.workspaceId});

  @override
  ConsumerState<WorkspaceInvitationsPage> createState() =>
      _WorkspaceInvitationsPageState();
}

class _WorkspaceInvitationsPageState
    extends ConsumerState<WorkspaceInvitationsPage> {
  final _functions = FirebaseFunctions.instance;
  final _auth = FirebaseAuth.instance;

  List<Map<String, dynamic>> _invitations = [];
  bool _loading = true;
  String? _error;
  String? _currentUserEmail;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      _currentUserEmail = _auth.currentUser?.email;

      // Fetch pending invitations for this workspace where the email matches
      // the current user (invitations the user can accept/decline).
      final snap = await FirebaseFirestore.instance
          .collection('workspaces')
          .doc(widget.workspaceId)
          .collection('invitations')
          .where('status', isEqualTo: 'pending')
          .get();

      final now = DateTime.now();
      _invitations = snap.docs
          .map((doc) => doc.data())
          .where((data) {
            final expiresAt = data['expiresAt'];
            if (expiresAt == null) return false;
            final exp = expiresAt is Timestamp
                ? expiresAt.toDate()
                : DateTime.tryParse(expiresAt.toString());
            if (exp == null) return false;
            return exp.isAfter(now);
          })
          .toList();
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      setState(() => _loading = false);
    }
  }

  Future<void> _respond(String invitationId, String status) async {
    setState(() => _loading = true);
    try {
      await _functions.httpsCallable('acceptInvitation').call({
        'workspaceId': widget.workspaceId,
        'invitationId': invitationId,
      });
      // The callable updates status server-side. Refresh to reflect change.
      await _load();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              status == 'accepted'
                  ? AppStrings.accepted
                  : AppStrings.declined,
            ),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } on FirebaseFunctionsException catch (e) {
      setState(() => _error = e.message);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed: ${e.message}'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text(AppStrings.invitations),
      ),
      body: _loading
          ? const AppPageLoading(message: AppStrings.loading)
          : _error != null
              ? AppErrorState(
                  message: _error!,
                  onRetry: _load,
                )
              : _invitations.isEmpty
                  ? AppEmptyState(
                      title: _currentUserEmail == null
                          ? 'Sign in to view invitations'
                          : 'No pending invitations',
                      subtitle: _currentUserEmail == null
                          ? 'Please sign in to see your workspace invitations.'
                          : 'There are no pending invitations for ${
                              _currentUserEmail
                            } in this workspace.',
                      icon: Icons.email_outlined,
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: _invitations.length,
                      itemBuilder: (context, index) {
                        final inv = _invitations[index];
                        return Card(
                          margin: const EdgeInsets.only(bottom: 12),
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundColor:
                                  AppColors.primary.withOpacity(0.1),
                              child: const Icon(Icons.email,
                                  color: AppColors.primary),
                            ),
                            title: Text(
                              inv['email'] ?? 'Unknown email',
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const SizedBox(height: 4),
                                Text(
                                  'Role: ${inv['role'] ?? 'member'}',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Invited by ${inv['invitedBy'] ?? 'unknown'}',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                TextButton(
                                  onPressed: () => _respond(
                                      inv['invitationId'], 'accepted'),
                                  child: const Text(AppStrings.accepted),
                                ),
                                TextButton(
                                  onPressed: () => _respond(
                                      inv['invitationId'], 'declined'),
                                  child: const Text(AppStrings.declined),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
    );
  }
}
