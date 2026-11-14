import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flowtop/core/constants/app_constants.dart';
import 'package:flowtop/core/di/injection_container.dart';
import 'package:flowtop/core/router/navigation_helpers.dart';
import 'package:flowtop/core/widgets/app_button.dart';
import 'package:flowtop/core/widgets/app_text_field.dart';

/// Lets the signed-in user change the name teammates see.
class ProfileEditPage extends ConsumerStatefulWidget {
  const ProfileEditPage({super.key});

  @override
  ConsumerState<ProfileEditPage> createState() => _ProfileEditPageState();
}

class _ProfileEditPageState extends ConsumerState<ProfileEditPage> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _name;
  late final TextEditingController _email;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final user = ref.read(currentUserProvider);
    _name = TextEditingController(text: user?.displayName ?? '');
    _email = TextEditingController(text: user?.email ?? '');
  }

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_saving || !_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      await ref
          .read(authProvider.notifier)
          .updateProfile(displayName: _name.text.trim());
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Profile updated')));
      context.popOrGo(AppRoutes.profile);
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Could not update your profile. Please try again.'),
      ));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Edit profile')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            Text(
              'How should people see you?',
              style: theme.textTheme.headlineSmall
                  ?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            Text(
              'Your name is shown on tasks and in the workspaces you join.',
              style: theme.textTheme.bodyMedium,
            ),
            const SizedBox(height: 28),
            AppTextField(
              label: 'Name',
              hint: 'e.g. Amina Yusuf',
              icon: Icons.person_outline_rounded,
              controller: _name,
              textInputAction: TextInputAction.done,
              onFieldSubmitted: (_) => _save(),
              validator: (value) {
                final text = value?.trim() ?? '';
                if (text.isEmpty) return 'Enter your name';
                if (text.length > 60) return 'Use 60 characters or fewer';
                return null;
              },
            ),
            if (_email.text.isNotEmpty) ...[
              const SizedBox(height: 16),
              AppTextField(
                label: 'Email',
                icon: Icons.mail_outline_rounded,
                controller: _email,
                enabled: false,
              ),
            ],
            const SizedBox(height: 28),
            AppButton(text: 'Save changes', loading: _saving, onPressed: _save),
          ],
        ),
      ),
    );
  }
}
