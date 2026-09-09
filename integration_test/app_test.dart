import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:isp_customer_mobile/main.dart';
import 'package:isp_customer_mobile/features/auth/session_controller.dart';

import 'package:isp_customer_mobile/core/l10n.dart';

import '../test/support.dart';
import '../test/app_flow_test.dart' as app_flows;

import 'package:isp_customer_mobile/features/portal/data/delta_repository.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  app_flows.main();
  testWidgets('native English, Dari and Pashto login layouts', (tester) async {
    final container = ProviderContainer(
      overrides: [repositoryProvider.overrideWithValue(FakeRepository())],
    );
    try {
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const CustomerApp(),
        ),
      );
      for (final language in ['en', 'fa', 'ps']) {
        container.read(languageProvider.notifier).select(language);
        await tester.pumpAndSettle();
        expect(
          Directionality.of(tester.element(find.byType(Form))),
          language == 'en' ? TextDirection.ltr : TextDirection.rtl,
        );
        expect(find.byType(TextFormField), findsNWidgets(2));
        expect(tester.takeException(), isNull);
      }
    } finally {
      await tester.pumpWidget(const SizedBox());
      container.dispose();
    }
  });
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
    await tester.enterText(find.byType(TextFormField).at(0), 'fixture');
    await tester.enterText(find.byType(TextFormField).at(1), 'fixture');
    await tester.ensureVisible(find.text('Sign in'));
    await tester.tap(find.text('Sign in'));
    await tester.pumpAndSettle();
    expect(find.text('Fixture service'), findsOneWidget);
    await tester.tap(find.byIcon(Icons.tune));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.text('Sign out & clear data'),
      150,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.text('Sign out & clear data'));
    await tester.pumpAndSettle();
    expect(find.text('Sign in'), findsOneWidget);
  });
}
