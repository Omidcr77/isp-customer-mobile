import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:isp_customer_mobile/main.dart';
import 'package:isp_customer_mobile/features/auth/session_controller.dart';
import 'package:isp_customer_mobile/features/portal/domain/portal.dart';

import 'support.dart';

void main() {
  testWidgets('HTTP acknowledgement starts exactly one automatic attempt', (
    tester,
  ) async {
    final repo = FakeRepository(failure: PortalFailure.autoUnavailable);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [repositoryProvider.overrideWithValue(repo)],
        child: const CustomerApp(),
      ),
    );
    await tester.pumpAndSettle();
    expect(repo.autoAttempts, 0);
    await tester.ensureVisible(find.byType(CheckboxListTile));
    await tester.tap(find.byType(CheckboxListTile));
    await tester.pumpAndSettle();
    expect(repo.autoAttempts, 1);
    await tester.pump(const Duration(seconds: 30));
    expect(repo.autoAttempts, 1);
  }, skip: !const bool.fromEnvironment('ALLOW_HTTP'));

  testWidgets(
    'connection login uses the fixed portal and logout does not loop',
    (tester) async {
      final repo = FakeRepository();
      await tester.pumpWidget(
        ProviderScope(
          overrides: [repositoryProvider.overrideWithValue(repo)],
          child: const CustomerApp(),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Portal URL'), findsNothing);
      expect(find.byType(TextFormField), findsNWidgets(2));
      await tester.ensureVisible(find.text('Sign in with my connection'));
      await tester.tap(find.text('Sign in with my connection'));
      await tester.pumpAndSettle();
      expect(repo.loginBase, 'http://192.168.10.2/users/');
      expect(find.text('Fixture service'), findsOneWidget);
      await tester.tap(find.byIcon(Icons.tune));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Sign out & clear data'));
      await tester.pumpAndSettle();
      expect(repo.autoAttempts, 1);
      expect(find.text('Sign in'), findsOneWidget);
    },
  );

  testWidgets('failed connection detection allows manual sign-in', (
    tester,
  ) async {
    final repo = FakeRepository(failure: PortalFailure.autoUnavailable);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [repositoryProvider.overrideWithValue(repo)],
        child: const CustomerApp(),
      ),
    );
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Sign in with my connection'));
    await tester.tap(find.text('Sign in with my connection'));
    await tester.pumpAndSettle();
    expect(
      find.text(
        'Your connection could not be matched to an account. Sign in with your username and password.',
      ),
      findsOneWidget,
    );
    repo.failure = null;
    await tester.enterText(find.byType(TextFormField).at(0), 'fixture');
    await tester.enterText(find.byType(TextFormField).at(1), 'fixture');
    await tester.ensureVisible(find.text('Sign in'));
    await tester.tap(find.text('Sign in'));
    await tester.pumpAndSettle();
    expect(repo.loginBase, 'http://192.168.10.2/users/');
    expect(find.text('Fixture service'), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
  });

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
    await tester.enterText(find.byType(TextFormField).at(0), 'fixture');
    await tester.enterText(find.byType(TextFormField).at(1), 'fixture');
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
