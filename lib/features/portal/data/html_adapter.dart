import 'dart:convert';

import 'package:html/parser.dart' as html;

import '../domain/portal.dart';

/// The only layer that knows portal markup. Never evaluates portal JavaScript.
class PortalHtmlAdapter {
  const PortalHtmlAdapter();
  void check(String source) {
    if (source.length > 4 * 1024 * 1024) {
      throw const PortalException(PortalFailure.malformed);
    }
    // Valid pages contain JavaScript branches mentioning these markers.
    // Inspect the actual response payload, not arbitrary source substrings.
    final doc = html.parse(source);
    final unauthenticated = doc
        .querySelectorAll('script')
        .any(
          (script) => RegExp(
            r"""^\s*(?:(?:var|let|const)\s+)?IsAuthenticated\s*=\s*(['"])No\1\s*;?\s*$""",
            multiLine: true,
          ).hasMatch(script.text),
        );
    final loginForm = doc
        .querySelectorAll('form')
        .any(
          (form) =>
              form.querySelector('input[name="Username"]') != null &&
              form.querySelector('input[name="Password"][type="password"]') !=
                  null,
        );
    for (final element in doc.querySelectorAll('script,style,template')) {
      element.remove();
    }
    final envelope = RegExp(
      r'^<data>\s*<Error>\s*<!\[CDATA\[([\s\S]*?)\]\]>\s*</Error>\s*</data>$',
      caseSensitive: false,
    ).firstMatch(source.trim());
    final payload = (envelope?[1] ?? doc.body?.text ?? '').trim();
    if (payload == '~SessionExpire' ||
        payload == '~ChangeUser' ||
        unauthenticated ||
        loginForm) {
      throw const PortalException(PortalFailure.expired);
    }
    if (payload.startsWith('~')) {
      throw const PortalException(PortalFailure.server);
    }
  }

  String loginId(String source) {
    if (source.contains('<Error>')) {
      source =
          RegExp(r'<!\[CDATA\[([\s\S]*?)\]\]>').firstMatch(source)?[1] ??
          html.parse(source).querySelector('error')?.text ??
          source;
    }
    final match = RegExp(
      r'^OK~([0-9]+)(?:~.*)?$',
      dotAll: true,
    ).firstMatch(source.trim());
    if (match == null) {
      if (source.trim().startsWith('~')) {
        throw const PortalException(PortalFailure.credentials);
      }
      throw const PortalException(PortalFailure.malformed);
    }
    return match[1]!;
  }

  PortalPage parse(String source, {bool dashboard = false}) {
    check(source);
    final doc = html.parse(source);
    final root = dashboard ? doc.querySelector('#MainContent') : doc.body;
    if (root == null || source.trim().isEmpty) {
      throw const PortalException(PortalFailure.malformed);
    }
    final fields = <PortalField>[];
    for (final cell in root.querySelectorAll('td.Table_Title')) {
      final next = cell.nextElementSibling;
      if (next != null) {
        final copy = html.parseFragment(next.innerHtml);
        for (final e in copy.querySelectorAll('script,style,button,input,a')) {
          e.remove();
        }
        final label = clean(cell.text);
        final value = clean(copy.text ?? '');
        if (label.isNotEmpty &&
            value.isNotEmpty &&
            !fields.any((f) => f.label == label)) {
          fields.add(PortalField(label, value));
        }
      }
    }
    // Split header/content tables are used by the legacy portal.
    final tables = <PortalTable>[];
    List<String> pendingHeaders = [];
    for (final table in root.querySelectorAll('table')) {
      if (table.querySelector('.Table_Title') != null) continue;
      final headers = table
          .querySelectorAll('th')
          .map((e) => clean(e.text))
          .toList();
      if (headers.isNotEmpty) pendingHeaders = headers;
      final rows = table
          .querySelectorAll('tr')
          .where((r) => r.querySelector('td') != null)
          .map(
            (r) => r.querySelectorAll('td').map((e) => clean(e.text)).toList(),
          )
          .where((r) => r.any((s) => s.isNotEmpty))
          .toList();
      if (rows.isNotEmpty && pendingHeaders.isNotEmpty) {
        tables.add(PortalTable(List.of(pendingHeaders), rows));
      }
    }
    for (final item in root.querySelectorAll('.ChartLegend li')) {
      final text = clean(item.text);
      final colon = text.indexOf(':');
      if (colon > 0 && text.contains('روز')) {
        fields.add(
          PortalField(
            '${text.substring(0, colon).trim()} (روز)',
            text.substring(colon + 1).trim(),
          ),
        );
      }
    }
    final links = <UsageLink>[];
    final pattern = RegExp(
      r'''NavClick\(['"]DailyUsage['"],\s*['"]([^'"]+)['"]\)''',
    );
    for (final el in root.querySelectorAll('a,[onclick]')) {
      final action = el.attributes['onclick'] ?? el.attributes['href'] ?? '';
      final m = pattern.firstMatch(action);
      if (m == null) continue;
      final params = Uri.splitQueryString(
        m[1]!.replaceFirst(RegExp(r'^&'), ''),
      );
      if (!validUsage(params)) continue;
      if (links.any((l) => l.parameters.toString() == params.toString())) {
        continue;
      }
      final rowText = el.parent?.parent
          ?.querySelectorAll('td')
          .take(3)
          .map((e) => clean(e.text))
          .join(' · ');
      links.add(
        UsageLink(
          rowText?.isNotEmpty == true ? rowText! : clean(el.text),
          params,
        ),
      );
    }
    final hourly = <double>[];
    final chart = RegExp(
      r'var\s+lineChartData\s*=([\s\S]*?)function\s+ShowDetails',
    ).firstMatch(source);
    if (chart != null) {
      final data = RegExp(r'data:\s*(\[[0-9.,\s]*\])').firstMatch(chart[1]!);
      if (data != null) {
        try {
          hourly.addAll(
            (jsonDecode(data[1]!) as List).cast<num>().map((n) => n.toDouble()),
          );
        } catch (_) {
          throw const PortalException(PortalFailure.malformed);
        }
      }
    }
    double? used, total;
    final pie = RegExp(r'var\s+MainTrChartData\s*=\s*\[([\s\S]*?)\]')
        .firstMatch(source);
    if (pie != null) {
      final values = RegExp(r'value:\s*([0-9]+)')
          .allMatches(pie[1]!)
          .map((m) => double.parse(m[1]!))
          .toList();
      if (values.length == 2) {
        used = values[0];
        total = values[0] + values[1];
      }
    }
    if (hourly.length > 24 ||
        hourly.any((v) => !v.isFinite || v < 0) ||
        (used != null && !used.isFinite) ||
        (total != null && !total.isFinite)) {
      throw const PortalException(PortalFailure.malformed);
    }
    return PortalPage(
      fields: fields,
      tables: tables,
      usageLinks: links,
      hourlyBytes: hourly,
      totalBytes: total,
      usedBytes: used,
    );
  }

  static bool validUsage(Map<String, String> params) =>
      params.keys.every(
        (k) => ['Type', 'User_ServiceBase_Id', 'Year', 'Month'].contains(k),
      ) &&
      ['Totally', 'Monthly', 'Daily'].contains(params['Type']) &&
      params.entries
          .where((e) => e.key != 'Type')
          .every((e) => RegExp(r'^\d{1,12}$').hasMatch(e.value));

  static String clean(String text) => text
      .replaceAll(RegExp(r'\s+'), ' ')
      .replaceAll(RegExp('[\u202a-\u202e\u2066-\u2069]'), '')
      .trim();

  static String digits(String text) {
    const fa = '۰۱۲۳۴۵۶۷۸۹';
    const ar = '٠١٢٣٤٥٦٧٨٩';
    for (var i = 0; i < 10; i++) {
      text = text.replaceAll(fa[i], '$i').replaceAll(ar[i], '$i');
    }
    return text;
  }

  /// Binary units match the portal's ByteToR; money and calendar dates stay verbatim.
  static double? trafficBytes(String value) {
    value = digits(value).replaceAll(',', '');
    final matches = RegExp(
      r'(\d+(?:\.\d+)?)\s*(گیگ|مگ|کیلو|بایت|GiB|MiB|KiB|GB|MB|KB|Byte|B)',
      caseSensitive: false,
    ).allMatches(value);
    if (matches.isEmpty) return value.trim() == '0' ? 0 : null;
    var result = 0.0;
    for (final m in matches) {
      final unit = m[2]!.toLowerCase();
      final scale = ['گیگ', 'gib', 'gb'].contains(unit)
          ? 1073741824
          : ['مگ', 'mib', 'mb'].contains(unit)
          ? 1048576
          : ['کیلو', 'kib', 'kb'].contains(unit)
          ? 1024
          : 1;
      result += double.parse(m[1]!) * scale;
    }
    return result.isFinite ? result : null;
  }
}
