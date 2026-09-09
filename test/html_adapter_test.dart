import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:isp_customer_mobile/features/portal/data/html_adapter.dart';
import 'package:isp_customer_mobile/features/portal/domain/portal.dart';

void main() {
  test('rejects non-finite chart quantities from untrusted HTML', () {
    final value = List.filled(400, '9').join();
    final source =
        '<div id="MainContent"></div><script>var MainTrChartData=[{value:$value},{value:1}];</script>';
    expect(
      () => const PortalHtmlAdapter().parse(source, dashboard: true),
      throwsA(isA<PortalException>()),
    );
    expect(PortalHtmlAdapter.trafficBytes('$value GiB'), isNull);
  });

  const adapter = PortalHtmlAdapter();
  test(
    'extracts native dashboard fields, chart bytes and portal remaining days',
    () {
      final page = adapter.parse(
        File('test/fixtures/dashboard.html').readAsStringSync(),
        dashboard: true,
      );
      expect(page.usedBytes, 1073741824);
      expect(page.totalBytes, 6442450944);
      expect(page.hourlyBytes, [1073741824, 2147483648]);
      expect(
        page.fields.singleWhere((f) => f.label == 'باقیمانده (روز)').value,
        '12 روز',
      );
      expect(
        page.fields.singleWhere((f) => f.label == 'وضعیت اعتبار').value,
        '100 AFN',
      );
    },
  );
  test('joins split tables and accepts only validated usage navigation', () {
    final page = adapter.parse(
      File('test/fixtures/usage.html').readAsStringSync(),
    );
    expect(page.tables.single.rows.single[2], '۲ گیگ ۵۱۲ مگ');
    expect(page.usageLinks.length, 1);
    expect(page.usageLinks.single.parameters['Month'], '1');
  });
  test('converts Persian Arabic and binary data units without guessing', () {
    expect(PortalHtmlAdapter.trafficBytes('۲ گیگ ۵۱۲ مگ'), 2.5 * 1073741824);
    expect(PortalHtmlAdapter.trafficBytes('١ كي غير معروف'), isNull);
    expect(PortalHtmlAdapter.trafficBytes('0'), 0);
    expect(PortalHtmlAdapter.digits('۱۲٣'), '123');
  });
  test('recognizes expired session even in HTML error envelope', () {
    expect(
      () => adapter.parse(
        '<data><Error><![CDATA[~SessionExpire]]></Error></data>',
      ),
      throwsA(
        isA<PortalException>().having(
          (e) => e.kind,
          'kind',
          PortalFailure.expired,
        ),
      ),
    );
    expect(
      () => adapter.parse('<html></html>', dashboard: true),
      throwsA(isA<PortalException>()),
    );
    expect(
      () => adapter.loginId('unexpected'),
      throwsA(isA<PortalException>()),
    );
    expect(adapter.loginId('OK~42~Welcome'), '42');
    expect(
      () =>
          adapter.loginId('<data><Error><![CDATA[~Rejected]]></Error></data>'),
      throwsA(
        isA<PortalException>().having(
          (e) => e.kind,
          'kind',
          PortalFailure.credentials,
        ),
      ),
    );
    expect(
      () => adapter.loginId('~Rejected'),
      throwsA(
        isA<PortalException>().having(
          (e) => e.kind,
          'kind',
          PortalFailure.credentials,
        ),
      ),
    );
  });
}
