import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:isp_customer_mobile/main.dart';
import 'package:isp_customer_mobile/features/auth/session_controller.dart';
import 'package:isp_customer_mobile/features/portal/domain/portal.dart';

import 'support.dart';

void main() {
  testWidgets('fixture login, dashboard, settings and complete logout', (
    tester,
  ) async {
    final repo = FakeRepository();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [repositoryProvider.overrideWithValue(repo)],
        child: const CustomerApp(),
      ),
    );
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextFormField).at(1), 'fixture');
    await tester.enterText(find.byType(TextFormField).at(2), 'fixture');
    await tester.ensureVisible(find.text('Sign in'));
    await tester.tap(find.text('Sign in'));
    await tester.pumpAndSettle();
    expect(find.text('Fixture service'), findsOneWidget);
    await tester.tap(find.byIcon(Icons.tune));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Sign out & clear data'));
    await tester.pumpAndSettle();
    expect(find.text('Sign in'), findsOneWidget);
    expect(repo.cleared, true);
    expect(find.text('Fixture service'), findsNothing);
  });
  testWidgets('expired report clears dashboard and returns to sign in', (
    tester,
  ) async {
    final repo = FakeRepository(restored: true, failure: PortalFailure.expired);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [repositoryProvider.overrideWithValue(repo)],
        child: const CustomerApp(),
      ),
    );
    await tester.pumpAndSettle();
    expect(
      find.text('Your session ended. Please sign in again.'),
      findsOneWidget,
    );
    expect(find.text('Sign in'), findsOneWidget);
    expect(repo.cleared, true);
  });
  testWidgets('unreachable server shows retry without stale customer data', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          repositoryProvider.overrideWithValue(
            FakeRepository(restored: true, failure: PortalFailure.unreachable),
          ),
        ],
        child: const CustomerApp(),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Try again'), findsOneWidget);
    expect(find.text('Fixture service'), findsNothing);
    expect(find.byIcon(Icons.cloud_off_outlined), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
  });
}
