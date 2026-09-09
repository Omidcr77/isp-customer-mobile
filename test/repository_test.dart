import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:isp_customer_mobile/features/portal/data/delta_repository.dart';
import 'package:isp_customer_mobile/features/portal/domain/portal.dart';

import 'support.dart';

void main() {
  test(
    'automatic login uses only the server action and its returned identity',
    () async {
      final requests = <RequestOptions>[];
      final vault = MemoryVault();
      final dio = Dio()
        ..httpClientAdapter = FixtureTransport((r) {
          requests.add(r);
          return ResponseBody.fromString(
            r.path.contains('ProcessLogin') ? 'OK~42' : 'wrapper',
            200,
            headers: {
              'set-cookie': ['DSUSERSESSID=fixture; Path=/users/; Secure'],
            },
          );
        });
      final repo = DeltaRepository(vault: vault, client: dio);
      await repo.autoLogin('https://portal.example/users/');
      expect(requests.length, 2);
      expect(requests.first.method, 'GET');
      expect(requests.first.uri.path, '/users/');
      expect(requests.last.method, 'POST');
      expect(requests.last.data, {'act': 'AutoLogin'});
      expect(requests.last.uri.queryParameters, {'User_Id': '0'});
      expect(repo.userId, '42');
      expect(vault.value, isNotNull);
      await repo.clear();
    },
  );

  for (final response in [
    '~Not detected',
    '<data><Error><![CDATA[~Not detected]]></Error></data>',
    'unexpected HTML',
    'OK~42',
  ]) {
    test(
      'automatic login rejects invalid or cookieless response $response',
      () async {
        final vault = MemoryVault();
        final dio = Dio()
          ..httpClientAdapter = FixtureTransport(
            (r) => ResponseBody.fromString(
              r.path.contains('ProcessLogin') ? response : 'wrapper',
              200,
            ),
          );
        final repo = DeltaRepository(vault: vault, client: dio);
        await expectLater(
          repo.autoLogin('https://portal.example/users/'),
          throwsA(
            isA<PortalException>().having(
              (e) => e.kind,
              'failure',
              response.contains('Not detected')
                  ? PortalFailure.autoUnavailable
                  : PortalFailure.malformed,
            ),
          ),
        );
        expect(vault.value, isNull);
        expect(repo.userId, isNull);
      },
    );
  }

  test(
    'automatic login timeout clears the session and remains retryable',
    () async {
      final vault = MemoryVault();
      final dio = Dio()
        ..httpClientAdapter = FixtureTransport(
          (r) => throw DioException(
            requestOptions: r,
            type: DioExceptionType.receiveTimeout,
          ),
        );
      final repo = DeltaRepository(vault: vault, client: dio);
      await expectLater(
        repo.autoLogin('https://portal.example/users/'),
        throwsA(
          isA<PortalException>().having(
            (e) => e.kind,
            'failure',
            PortalFailure.timeout,
          ),
        ),
      );
      expect(vault.value, isNull);
    },
  );

  test('HTTP authentication rejection maps to credentials', () async {
    final dio = Dio()
      ..httpClientAdapter = FixtureTransport(
        (r) => ResponseBody.fromString('Unauthorized', 401),
      );
    final repo = DeltaRepository(vault: MemoryVault(), client: dio);
    await expectLater(
      repo.login('https://portal.example/users/', 'fixture', 'fixture'),
      throwsA(
        isA<PortalException>().having(
          (e) => e.kind,
          'kind',
          PortalFailure.credentials,
        ),
      ),
    );
  });

  test('real adapter integrates login cookies reads logout without persisting password', () async {
    final vault = MemoryVault();
    final requests = <RequestOptions>[];
    final dio = Dio()
      ..httpClientAdapter = FixtureTransport((r) {
        requests.add(r);
        if (r.path.contains('ProcessLogin')) {
          return ResponseBody.fromString(
            'OK~42',
            200,
            headers: {
              'set-cookie': [
                'DSUSERSESSID=fixture-only; Path=/users/; HttpOnly; Secure',
              ],
            },
          );
        }
        if (r.path.contains('DS_MyInternet')) {
          return ResponseBody.fromString(
            File('test/fixtures/dashboard.html').readAsStringSync(),
            200,
          );
        }
        return ResponseBody.fromString('OK', 200);
      });
    final repo = DeltaRepository(vault: vault, client: dio);
    await repo.login(
      'https://portal.example/users/',
      'fixture-user',
      'fixture-password',
    );
    expect(vault.value, isNot(contains('fixture-password')));
    final page = await repo.read(PortalSection.dashboard);
    expect(page.fields, isNotEmpty);
    expect(
      requests.last.headers['Cookie'],
      contains('DSUSERSESSID=fixture-only'),
    );
    await repo.logout();
    expect(vault.value, isNull);
    expect(repo.userId, isNull);
    expect(
      requests.where((r) => r.uri.queryParameters['act'] == 'Logout').length,
      1,
    );
  });
  test('expired marker clears persisted authentication', () async {
    final vault = MemoryVault();
    final dio = Dio()
      ..httpClientAdapter = FixtureTransport(
        (r) => r.path.contains('ProcessLogin')
            ? ResponseBody.fromString(
                'OK~42',
                200,
                headers: {
                  'set-cookie': ['DSUSERSESSID=fixture; Path=/users/; Secure'],
                },
              )
            : ResponseBody.fromString(
                r.path.contains('DS_Login')
                    ? 'login'
                    : '<data>~SessionExpire</data>',
                200,
              ),
      );
    final repo = DeltaRepository(vault: vault, client: dio);
    await repo.login('https://portal.example/users/', 'fixture', 'fixture');
    await expectLater(
      repo.read(PortalSection.dashboard),
      throwsA(
        isA<PortalException>().having(
          (e) => e.kind,
          'kind',
          PortalFailure.expired,
        ),
      ),
    );
    expect(vault.value, isNull);
  });
  for (final type in [
    DioExceptionType.connectionError,
    DioExceptionType.receiveTimeout,
  ]) {
    test('maps ${type.name} without exposing request data', () async {
      final dio = Dio()
        ..httpClientAdapter = FixtureTransport(
          (r) => throw DioException(requestOptions: r, type: type),
        );
      final repo = DeltaRepository(vault: MemoryVault(), client: dio);
      await expectLater(
        repo.login('https://portal.example/users/', 'fixture', 'secret'),
        throwsA(
          isA<PortalException>().having(
            (e) => e.kind,
            'kind',
            type == DioExceptionType.connectionError
                ? PortalFailure.unreachable
                : PortalFailure.timeout,
          ),
        ),
      );
    });
  }
  test('rejects unsafe origins and paths', () {
    for (final url in [
      'http://portal.example/users/',
      'https://u:p@portal.example/users/',
      'https://portal.example/admin/',
      'https://portal.example/users/?token=x',
      'file:///users/',
    ]) {
      expect(
        () => DeltaRepository.validateBase(url),
        throwsA(isA<PortalException>()),
      );
    }
  });
  test(
    'restored fixed-provider sessions retain their original deadline',
    () async {
      var now = DateTime.now();
      final vault = MemoryVault();
      final dio = Dio()
        ..httpClientAdapter = FixtureTransport(
          (r) => ResponseBody.fromString(
            r.path.contains('ProcessLogin') ? 'OK~42' : 'wrapper',
            200,
            headers: {
              'set-cookie': ['DSUSERSESSID=fixture; Path=/users/'],
            },
          ),
        );
      final repo = DeltaRepository(vault: vault, client: dio, now: () => now);
      await repo.autoLogin('http://192.168.10.2/users/', allowHttp: true);
      final restored = DeltaRepository(vault: vault, now: () => now);
      expect(await restored.restore(), true);
      expect(restored.expiresAt, repo.expiresAt);
      now = now.add(const Duration(minutes: 16));
      expect(
        await DeltaRepository(vault: vault, now: () => now).restore(),
        false,
      );
      expect(vault.value, isNull);
    },
    skip: !const bool.fromEnvironment('ALLOW_HTTP'),
  );

  test('restoration rejects sessions saved for a different server', () async {
    final vault = MemoryVault();
    final dio = Dio()
      ..httpClientAdapter = FixtureTransport(
        (r) => ResponseBody.fromString(
          r.path.contains('ProcessLogin') ? 'OK~42' : 'wrapper',
          200,
          headers: {
            'set-cookie': ['DSUSERSESSID=fixture; Path=/users/; Secure'],
          },
        ),
      );
    await DeltaRepository(
      vault: vault,
      client: dio,
    ).autoLogin('https://portal.example/users/');
    expect(await DeltaRepository(vault: vault).restore(), false);
    expect(vault.value, isNull);
  });
}
