import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flowtop/core/constants/app_constants.dart';
import 'package:flowtop/core/di/injection_container.dart';
import 'package:flowtop/core/widgets/app_button.dart';
import 'package:flowtop/core/widgets/app_text_field.dart';
import 'package:flowtop/features/workspaces/domain/entities/workspace_entity.dart';

class WorkspaceCreatePage extends ConsumerStatefulWidget {
  const WorkspaceCreatePage({super.key});

  @override
  ConsumerState<WorkspaceCreatePage> createState() => _WorkspaceCreatePageState();
}

class _WorkspaceCreatePageState extends ConsumerState<WorkspaceCreatePage> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _description = TextEditingController();
  bool _saving = false;

  @override
  void dispose() {
    _name.dispose();
    _description.dispose();
    super.dispose();
  }

  Future<void> _create() async {
    if (_saving || !_formKey.currentState!.validate()) return;
    final user = ref.read(currentUserProvider);
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please sign in first.')));
      return;
    }
    setState(() => _saving = true);
    try {
      final id = await ref.read(workspaceRepositoryProvider).createWorkspace(
        WorkspaceEntity(
          id: '', name: _name.text.trim(), description: _description.text.trim(),
          ownerId: user.uid, role: WorkspaceRole.owner, memberCount: 1,
        ),
        ownerEmail: user.email,
        ownerName: user.displayName,
      );
      if (!mounted) return;
      ref.read(selectedWorkspaceProvider.notifier).state = id;
      context.go(AppRoutes.dashboard);
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Could not create your workspace. Please try again.')));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('New workspace'), leading: IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => context.go(AppRoutes.workspaces))),
      body: Form(
        key: _formKey,
        child: ListView(padding: const EdgeInsets.all(24), children: [
          Text('Make space for your work', style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          Text('Keep tasks and projects together in a space of their own.', style: theme.textTheme.bodyMedium),
          const SizedBox(height: 28),
          AppTextField(label: 'Workspace name', hint: 'e.g. Personal or Design team', icon: Icons.workspaces_outlined, controller: _name,
              textInputAction: TextInputAction.next, validator: (value) => value == null || value.trim().isEmpty ? 'Enter a workspace name' : null),
          const SizedBox(height: 16),
          AppTextField(label: 'Description (optional)', hint: 'What will you work on here?', icon: Icons.notes_rounded, controller: _description, maxLines: 3),
          const SizedBox(height: 28),
          AppButton(text: 'Create workspace', loading: _saving, onPressed: _create),
        ]),
      ),
    );
  }
}
