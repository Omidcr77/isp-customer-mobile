import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:isp_customer_mobile/main.dart';
import 'package:isp_customer_mobile/core/l10n.dart';
import 'package:isp_customer_mobile/features/auth/session_controller.dart';
import 'package:isp_customer_mobile/features/portal/domain/portal.dart';

import 'support.dart';

void main() {
  for (final language in ['en', 'fa', 'ps']) {
    testWidgets('login and RTL layout in $language at narrow width', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(360, 800);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final container = ProviderContainer(
        overrides: [repositoryProvider.overrideWithValue(FakeRepository())],
      );
      addTearDown(container.dispose);
      container.read(languageProvider.notifier).select(language);
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const CustomerApp(),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text(Words(language)('login')), findsOneWidget);
      expect(
        Directionality.of(tester.element(find.byType(Form))),
        language == 'en' ? TextDirection.ltr : TextDirection.rtl,
      );
      expect(tester.takeException(), isNull);
    });
  }
  testWidgets('dashboard shows native customer fields', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          repositoryProvider.overrideWithValue(FakeRepository(restored: true)),
        ],
        child: const CustomerApp(),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Fixture service'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
  });
  test('authentication failure, success and expiry transitions', () async {
    final repo = FakeRepository(failure: PortalFailure.credentials);
    final c = ProviderContainer(
      overrides: [repositoryProvider.overrideWithValue(repo)],
    );
    addTearDown(c.dispose);
    final auth = c.read(sessionProvider.notifier);
    await auth.restore();
    await auth.login('fixture', 'fixture', false);
    expect(c.read(sessionProvider).error, PortalFailure.credentials);
    repo.failure = null;
    await auth.login('fixture', 'fixture', false);
    expect(c.read(sessionProvider).signedIn, true);
    await auth.expire();
    expect(c.read(sessionProvider).signedIn, false);
    expect(repo.cleared, true);
  });
}
