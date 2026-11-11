import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flowtop/core/di/injection_container.dart';
import 'package:flowtop/features/profile/presentation/pages/profile_page.dart';

void main() {
  testWidgets('dark mode choice is stored', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    await tester.pumpWidget(ProviderScope(overrides: [
      preferencesProvider.overrideWithValue(prefs),
      currentUserProvider.overrideWith((ref) => null),
    ], child: const MaterialApp(home: ProfilePage())));
    await tester.tap(find.byType(SwitchListTile));
    await tester.pumpAndSettle();
    expect(prefs.getString('theme_mode'), 'light');
  });
}
