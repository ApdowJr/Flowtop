import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';

/// Back navigation that also works for pages that were reached without a
/// stack (for example through a deep link or a tab switch).
extension BackNavigation on BuildContext {
  /// Pops the current page. When there is nothing to pop, navigates to
  /// [fallback] instead so the user never gets stuck on a page.
  void popOrGo(String fallback) {
    final router = GoRouter.of(this);
    if (router.canPop()) {
      router.pop();
    } else {
      router.go(fallback);
    }
  }
}
