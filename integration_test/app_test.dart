import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:isp_customer_mobile/main.dart';
import 'package:isp_customer_mobile/features/auth/session_controller.dart';

import '../test/support.dart';

import 'package:isp_customer_mobile/features/portal/data/delta_repository.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  testWidgets('Android secure session storage round trip and clearing', (
    tester,
  ) async {
    final vault = SecureSessionVault();
    try {
      await vault.write('synthetic-session-only');
      expect(await vault.read(), 'synthetic-session-only');
    } finally {
      await vault.clear();
    }
    expect(await vault.read(), isNull);
  });
  testWidgets('fixture sign-in dashboard settings logout', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [repositoryProvider.overrideWithValue(FakeRepository())],
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
  });
}
