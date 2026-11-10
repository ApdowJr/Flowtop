import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flowtop/core/constants/app_constants.dart';
import 'package:flowtop/features/tasks/presentation/pages/task_list_page.dart';

void main() {
  testWidgets('TaskListPage renders with ProviderScope', (WidgetTester tester) async {
    // TaskListPage is a Riverpod consumer widget; it must be wrapped in ProviderScope.
    // Note: This test exercises the widget tree only. The underlying task stream
    // requires Firestore and is exercised separately against the emulator.
    await tester.pumpWidget(
      const ProviderScope(child: MaterialApp(home: TaskListPage())),
    );
    await tester.pumpAndSettle();
    expect(find.text(AppStrings.tasks), findsOneWidget);
  });
}
