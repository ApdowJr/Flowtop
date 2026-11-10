import 'package:flutter/material.dart';
import 'package:flowtop/core/constants/app_constants.dart';
import 'package:flowtop/core/widgets/app_text_field.dart';
import 'package:flowtop/core/widgets/app_button.dart';

class WorkspaceCreatePage extends StatelessWidget {
  const WorkspaceCreatePage({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text(AppStrings.createWorkspace)),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AppTextField(label: AppStrings.workspaceName, icon: Icons.work),
            const SizedBox(height: 20),
            AppButton(text: AppStrings.create, onPressed: () {}),
          ],
        ),
      ),
    );
  }
}
