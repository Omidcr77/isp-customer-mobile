// Explicit opt-in. Credentials arrive at runtime over an ADB loopback tunnel;
// never pass them as dart-defines, write fixtures, or print customer data.
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:isp_customer_mobile/main.dart';
import 'package:isp_customer_mobile/features/auth/session_controller.dart';
import 'package:isp_customer_mobile/features/portal/data/delta_repository.dart';
import 'package:isp_customer_mobile/features/portal/domain/portal.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  testWidgets(
    'authorized native login, read-only portal pages, storage and logout',
    (tester) async {
      final vault = SecureSessionVault();
      final repo = DeltaRepository(vault: vault);
      final container = ProviderContainer(
        overrides: [repositoryProvider.overrideWithValue(repo)],
      );
      await vault.clear();
      try {
        await tester.pumpWidget(
          UncontrolledProviderScope(
            container: container,
            child: const CustomerApp(),
          ),
        );
        await tester.pumpAndSettle();
        await tester.ensureVisible(find.byType(CheckboxListTile));
        await tester.tap(find.byType(CheckboxListTile));
        await tester.pumpAndSettle();
        expect(container.read(sessionProvider).signedIn, false);
        expect(container.read(sessionProvider).error, isNull);

        await tester.ensureVisible(find.text('Sign in with my connection'));
        await tester.tap(find.text('Sign in with my connection'));
        await settleLogin(tester, container);
        final automatic = container.read(sessionProvider);
        // Controlled stage/status only. No response bodies or customer identifiers.
        debugPrint(
          'LIVE AutoLogin: ${automatic.signedIn ? "accepted" : automatic.error?.name}; support=${automatic.diagnostic ?? "none"}',
        );
        if (automatic.signedIn) {
          await container.read(sessionProvider.notifier).logout();
          await tester.pumpAndSettle();
          await tester.ensureVisible(find.byType(CheckboxListTile));
          await tester.tap(find.byType(CheckboxListTile));
          await tester.pumpAndSettle();
        }

        final client = HttpClient();
        Map<String, dynamic> credentials;
        try {
          final response = await (await client.getUrl(
            Uri.parse('http://127.0.0.1:8767/credentials'),
          )).close();
          credentials = jsonDecode(
            await utf8.decoder.bind(response).join(),
          ) as Map<String, dynamic>;
        } finally {
          client.close(force: true);
        }
        await tester.enterText(
          find.byType(TextFormField).at(0),
          credentials['username'] as String,
        );
        await tester.enterText(
          find.byType(TextFormField).at(1),
          credentials['password'] as String,
        );
        credentials.clear();
        await tester.ensureVisible(find.text('Sign in'));
        await tester.tap(find.text('Sign in'));
        await settleLogin(tester, container);
        final state = container.read(sessionProvider);
        if (!state.signedIn) {
          throw StateError(
            'Native manual login failed: ${state.error?.name}; support=${state.diagnostic ?? "none"}',
          );
        }
        debugPrint('LIVE ManualLogin: accepted');
        await tester.drag(find.byType(RefreshIndicator), const Offset(0, 350));
        await tester.pumpAndSettle();
        debugPrint('LIVE native pull-to-refresh: completed');
        final restored = DeltaRepository(vault: vault);
        expect(await restored.restore(), true);
        expect(restored.expiresAt, repo.expiresAt);
        for (final section in PortalSection.values) {
          await repo.read(section);
          debugPrint('LIVE read ${section.name}: completed');
        }
        for (final report in ['GiftHistory', 'InstallmentHistory']) {
          await repo.read(PortalSection.reports, report: report);
          debugPrint('LIVE read $report: completed');
        }
        final usage = await repo.read(PortalSection.usage);
        if (usage.usageLinks.isNotEmpty) {
          final monthly = await repo.read(
            PortalSection.usage,
            usage: usage.usageLinks.first.parameters,
          );
          debugPrint('LIVE usage drilldown: completed');
          if (monthly.usageLinks.isNotEmpty) {
            await repo.read(
              PortalSection.usage,
              usage: monthly.usageLinks.first.parameters,
            );
            debugPrint('LIVE second usage drilldown: completed');
          }
        }
        await container.read(sessionProvider.notifier).logout();
        await tester.pumpAndSettle();
        expect(container.read(sessionProvider).signedIn, false);
        expect(await vault.read(), isNull);
        debugPrint('LIVE logout and secure storage clearing: completed');
      } finally {
        if (repo.userId != null) {
          await repo.logout();
        } else {
          await repo.clear();
        }
        await tester.pumpWidget(const SizedBox());
        container.dispose();
      }
    },
    skip: !const bool.fromEnvironment('RUN_LIVE_PORTAL'),
  );
}

Future<void> settleLogin(
  WidgetTester tester,
  ProviderContainer container,
) async {
  for (var i = 0; i < 120; i++) {
    await tester.pump(const Duration(milliseconds: 500));
    if (!container.read(sessionProvider).busy) {
      await tester.pumpAndSettle(const Duration(milliseconds: 100));
      return;
    }
  }
  throw StateError('Native login did not complete within the test deadline');
}
