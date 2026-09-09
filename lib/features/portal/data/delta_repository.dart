import 'dart:convert';

import 'package:cookie_jar/cookie_jar.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../../../core/portal_config.dart';
import '../domain/portal.dart';
import 'html_adapter.dart';

abstract interface class SessionVault {
  Future<String?> read();
  Future<void> write(String value);
  Future<void> clear();
}

class SecureSessionVault implements SessionVault {
  final FlutterSecureStorage storage = const FlutterSecureStorage();
  @override
  Future<String?> read() => storage.read(key: 'portal_session');
  @override
  Future<void> write(String value) =>
      storage.write(key: 'portal_session', value: value);
  @override
  Future<void> clear() => storage.delete(key: 'portal_session');
}

class DeltaRepository implements PortalRepository {
  DeltaRepository({required this.vault, Dio? client, DateTime Function()? now})
    : dio = client ?? Dio(),
      now = now ?? DateTime.now {
    dio.options = BaseOptions(
      connectTimeout: const Duration(seconds: 12),
      receiveTimeout: const Duration(seconds: 20),
      sendTimeout: const Duration(seconds: 12),
      responseType: ResponseType.plain,
      followRedirects: false,
      validateStatus: (s) => s != null && s < 600,
    );
  }
  final Dio dio;
  final SessionVault vault;
  final DateTime Function() now;
  final adapter = const PortalHtmlAdapter();
  CookieJar jar = CookieJar();
  Uri? base;
  String? userId;
  DateTime? issuedAt;
  int generation = 0;
  static const maxAge = Duration(minutes: 15);
  @override
  DateTime? get expiresAt => issuedAt?.add(maxAge);

  static Uri validateBase(String value, {bool allowHttp = false}) {
    final uri = Uri.tryParse(value.trim());
    if (uri == null ||
        uri.host.isEmpty ||
        uri.userInfo.isNotEmpty ||
        uri.hasQuery ||
        uri.hasFragment ||
        !['http', 'https'].contains(uri.scheme)) {
      throw const PortalException(PortalFailure.insecure);
    }
    if (uri.scheme == 'http' &&
        (kReleaseMode ||
            !allowHttp ||
            !const bool.fromEnvironment('ALLOW_HTTP'))) {
      throw const PortalException(PortalFailure.insecure);
    }
    if (uri.path != '/users/' && uri.path != '/users') {
      throw const PortalException(PortalFailure.insecure);
    }
    return uri.replace(path: '/users/');
  }

  @override
  Future<bool> restore() async {
    try {
      final raw = await vault.read();
      if (raw == null) return false;
      final data = jsonDecode(raw) as Map<String, dynamic>;
      base = validateBase(
        data['base'] as String,
        allowHttp: data['http'] == true,
      );
      if (base.toString() != portalBaseUrl) {
        await clear();
        return false;
      }
      userId = data['id'] as String;
      issuedAt = DateTime.parse(data['issued'] as String);
      if (!RegExp(r'^\d+$').hasMatch(userId!) ||
          now().difference(issuedAt!) >= maxAge ||
          now().isBefore(issuedAt!)) {
        await clear();
        return false;
      }
      await jar.saveFromResponse(
        base!,
        (data['cookies'] as List)
            .cast<String>()
            .map(Cookie.fromSetCookieValue)
            .toList(),
      );
      return true;
    } catch (_) {
      await clear();
      return false;
    }
  }

  Future<void> persist() async {
    if (userId == null || base == null) return;
    try {
      final cookies = await jar.loadForRequest(
        base!.resolve('computer/DS_MyInternet.php'),
      );
      await vault.write(
        jsonEncode({
          'base': base.toString(),
          'id': userId,
          'issued': issuedAt!.toIso8601String(),
          'http': base!.scheme == 'http',
          'cookies': cookies.map((c) => c.toString()).toList(),
        }),
      );
    } catch (_) {
      throw const PortalException(PortalFailure.storage);
    }
  }

  @override
  Future<void> login(
    String baseUrl,
    String username,
    String password, {
    bool allowHttp = false,
  }) async {
    await clear();
    base = validateBase(baseUrl, allowHttp: allowHttp);
    if (username.trim().isEmpty ||
        password.isEmpty ||
        username.length > 32 ||
        password.length > 32) {
      throw const PortalException(PortalFailure.credentials);
    }
    try {
      await _request(
        'computer/DS_Login.php',
        query: {'User_Id': '0', 'Device': 'computer'},
        authenticated: false,
      );
      final response = await _request(
        'commonpages/DSUserProcessLogin.php',
        post: true,
        query: {'User_Id': '0'},
        data: {
          'Username': username.trim(),
          'Password': password,
          'act': 'ManualLogin',
        },
        authenticated: false,
      );
      await _acceptLogin(response);
    } catch (_) {
      await clear();
      rethrow;
    }
  }

  @override
  Future<void> autoLogin(String baseUrl, {bool allowHttp = false}) async {
    await clear();
    base = validateBase(baseUrl, allowHttp: allowHttp);
    try {
      // Match the portal wrapper's normal connection-based login flow.
      await _request('', authenticated: false);
      final response = await _request(
        'commonpages/DSUserProcessLogin.php',
        post: true,
        query: {'User_Id': '0'},
        data: {'act': 'AutoLogin'},
        authenticated: false,
      );
      await _acceptLogin(response);
      // A success token alone does not prove the server accepted the session.
      await _request(
        'computer/DS_MyInternet.php',
        query: {
          'Device': 'computer',
          'WebNewUser': 'No',
          'NCR': 'No',
          'Feedback': 'No',
        },
      );
    } on PortalException catch (e) {
      await clear();
      throw PortalException(
        e.kind == PortalFailure.credentials ||
                e.kind == PortalFailure.expired ||
                (e.diagnostic?.contains('-HTTP3') ?? false)
            ? PortalFailure.autoUnavailable
            : e.kind,
        diagnostic: e.diagnostic ?? 'AUTO-${e.kind.name.toUpperCase()}',
      );
    } catch (_) {
      await clear();
      rethrow;
    }
  }

  Future<void> _acceptLogin(String response) async {
    userId = adapter.loginId(response);
    issuedAt = now();
    final cookies = await jar.loadForRequest(base!);
    if (!cookies.any((c) => c.name == 'DSUSERSESSID' && c.value.isNotEmpty)) {
      throw const PortalException(PortalFailure.malformed);
    }
    await persist();
  }

  Future<String> _request(
    String path, {
    bool post = false,
    Map<String, String> query = const {},
    Map<String, String> data = const {},
    bool authenticated = true,
  }) async {
    final stage = path.isEmpty
        ? 'ENTRY'
        : path.contains('ProcessLogin')
        ? 'AUTH'
        : path.contains('DS_Login')
        ? 'FORM'
        : 'ACCOUNT';
    final epoch = generation;
    if (authenticated &&
        (userId == null ||
            issuedAt == null ||
            now().difference(issuedAt!) >= maxAge)) {
      await clear();
      throw const PortalException(PortalFailure.expired);
    }
    final uri = base!
        .resolve(path)
        .replace(
          queryParameters: {...query, if (authenticated) 'User_Id': userId!},
        );
    try {
      final cookies = await jar.loadForRequest(uri);
      final response = await dio.requestUri<String>(
        uri,
        data: post ? data : null,
        options: Options(
          method: post ? 'POST' : 'GET',
          contentType: Headers.formUrlEncodedContentType,
          headers: {
            if (cookies.isNotEmpty)
              'Cookie': cookies.map((c) => '${c.name}=${c.value}').join('; '),
          },
        ),
      );
      if (generation != epoch) {
        throw const PortalException(PortalFailure.expired);
      }
      final status = response.statusCode ?? 0;
      if (status == 401 || status == 403) {
        throw PortalException(
          authenticated ? PortalFailure.expired : PortalFailure.credentials,
          diagnostic: '$stage-HTTP$status',
        );
      }
      if (status >= 300 && status < 400) {
        throw PortalException(
          authenticated ? PortalFailure.expired : PortalFailure.server,
          diagnostic: '$stage-HTTP$status',
        );
      }
      if (status != 200) throw const PortalException(PortalFailure.server);
      final body = response.data ?? '';
      if (body.length > 4 * 1024 * 1024) {
        throw const PortalException(PortalFailure.malformed);
      }
      await jar.saveFromResponse(
        uri,
        (response.headers['set-cookie'] ?? [])
            .map(Cookie.fromSetCookieValue)
            .toList(),
      );
      if (authenticated) {
        adapter.check(body);
        await persist();
      }
      return body;
    } on DioException catch (e) {
      throw PortalException(switch (e.type) {
        DioExceptionType.connectionTimeout ||
        DioExceptionType.sendTimeout ||
        DioExceptionType.receiveTimeout => PortalFailure.timeout,
        DioExceptionType.badCertificate => PortalFailure.insecure,
        _ => PortalFailure.unreachable,
      });
    } on PortalException catch (e) {
      if (e.kind == PortalFailure.expired) await clear();
      throw PortalException(
        e.kind,
        diagnostic: e.diagnostic ?? '$stage-${e.kind.name.toUpperCase()}',
      );
    } on FormatException {
      throw const PortalException(PortalFailure.malformed);
    }
  }

  @override
  Future<PortalPage> read(
    PortalSection section, {
    Map<String, String> usage = const {},
    String report = 'ServiceHistory',
  }) async {
    if ([
      PortalSection.notifications,
      PortalSection.invoices,
    ].contains(section)) {
      return const PortalPage(notice: 'unsupported');
    }
    if ([
      PortalSection.dashboard,
      PortalSection.service,
      PortalSection.traffic,
      PortalSection.balance,
      PortalSection.profile,
    ].contains(section)) {
      return adapter.parse(
        await _request(
          'computer/DS_MyInternet.php',
          query: {
            'Device': 'computer',
            'WebNewUser': 'No',
            'NCR': 'No',
            'Feedback': 'No',
          },
        ),
        dashboard: true,
      );
    }
    String path;
    Map<String, String> data = {};
    switch (section) {
      case PortalSection.usage:
        data = usage.isEmpty ? {'Type': 'Totally'} : usage;
        if (!PortalHtmlAdapter.validUsage(data)) {
          throw const PortalException(PortalFailure.malformed);
        }
        path = 'DS_Rep_DailyUsage.php';
      case PortalSection.payments:
        path = 'DS_Rep_PaymentHistory.php';
      case PortalSection.reports:
        if (![
          'ServiceHistory',
          'GiftHistory',
          'InstallmentHistory',
        ].contains(report)) {
          throw const PortalException(PortalFailure.malformed);
        }
        path = 'DS_Rep_$report.php';
      case PortalSection.documents:
        path = 'DS_Attachment.php';
        data = {'CanPrintInvoice': 'Yes'};
      case PortalSection.packages:
        path = 'DS_BuyService.php';
        data = {'type': 'SelectServiceBase', 'CanPrintInvoice': 'Yes'};
      default:
        throw const PortalException(PortalFailure.malformed);
    }
    final parsed = adapter.parse(
      await _request('computer/$path', post: true, data: data),
    );
    // Catalog and document markup was empty for the analyzed account. Do not
    // infer product cards or turn embedded upload/purchase controls into actions.
    if (parsed.isEmpty &&
        [PortalSection.packages, PortalSection.documents].contains(section)) {
      return const PortalPage(notice: 'unverifiedContent');
    }
    return parsed;
  }

  @override
  Future<void> logout() async {
    try {
      if (userId != null) {
        await _request(
          'commonpages/DSMyInternetRender.php',
          post: true,
          query: {'act': 'Logout'},
        );
      }
    } finally {
      await clear();
    }
  }

  @override
  Future<void> clear() async {
    generation++;
    userId = null;
    issuedAt = null;
    base = null;
    jar = CookieJar();
    try {
      await vault.clear();
    } catch (_) {
      throw const PortalException(PortalFailure.storage);
    }
  }
}
