import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flowtop/core/constants/app_constants.dart';
import 'package:flowtop/core/widgets/app_text_field.dart';
import 'package:flowtop/core/widgets/app_empty_state.dart';
import 'package:flowtop/core/widgets/app_button.dart';
import 'package:flowtop/core/di/injection_container.dart';
import 'package:flowtop/features/projects/domain/entities/project_entity.dart';

/// Create a new project within the selected workspace.
class ProjectCreatePage extends ConsumerStatefulWidget {
  const ProjectCreatePage({super.key});

  @override
  ConsumerState<ProjectCreatePage> createState() => _ProjectCreatePageState();
}

class _ProjectCreatePageState extends ConsumerState<ProjectCreatePage> {
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _saving = false;

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _create() async {
    if (_saving || !_formKey.currentState!.validate()) return;

    final user = ref.read(currentUserProvider);
    final workspaceId = ref.read(selectedWorkspaceProvider);

    if (user == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('You must be signed in to create a project.'),
            backgroundColor: AppColors.error,
          ),
        );
      }
      return;
    }

    if (workspaceId == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please select a workspace first.'),
            backgroundColor: AppColors.error,
          ),
        );
      }
      return;
    }

    setState(() => _saving = true);
    try {
      await ref.read(projectRepositoryProvider).createProject(
        ProjectEntity(
          id: '',
          name: _nameController.text.trim(),
          description: _descriptionController.text.trim(),
          ownerId: user.uid,
          workspaceId: workspaceId,
          color: 0xFF7C3AED,
        ),
      );
      if (mounted) context.go(AppRoutes.projects);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to create project: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final workspaceId = ref.watch(selectedWorkspaceProvider);

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text(AppStrings.addProject),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go(AppRoutes.projects),
        ),
      ),
      body: workspaceId == null
          ? const AppEmptyState(
              title: 'No workspace selected',
              subtitle: 'Please select a workspace before creating a project.',
              icon: Icons.folder_outlined,
            )
          : Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  AppTextField(
                    label: AppStrings.projectName,
                    hint: 'e.g. Quarterly Roadmap',
                    icon: Icons.folder,
                    controller: _nameController,
                    validator: (v) => (v == null || v.isEmpty) ? 'Project name is required' : null,
                    textInputAction: TextInputAction.next,
                  ),
                  const SizedBox(height: 16),
                  AppTextField(
                    label: 'Description',
                    hint: 'What is this project about?',
                    icon: Icons.description,
                    controller: _descriptionController,
                    maxLines: 3,
                    textInputAction: TextInputAction.done,
                  ),
                  const SizedBox(height: 30),
                  AppButton(text: AppStrings.create, loading: _saving, onPressed: _create),
                ],
              ),
            ),
    );
  }
}
