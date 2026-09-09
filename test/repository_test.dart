import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:isp_customer_mobile/features/portal/data/delta_repository.dart';
import 'package:isp_customer_mobile/features/portal/domain/portal.dart';

import 'support.dart';

void main() {
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
  test('restored sessions expire at original deadline', () async {
    var now = DateTime.utc(2026, 1, 1);
    final vault = MemoryVault();
    final dio = Dio()
      ..httpClientAdapter = FixtureTransport(
        (r) => ResponseBody.fromString(
          r.path.contains('ProcessLogin') ? 'OK~42' : 'login',
          200,
          headers: {
            'set-cookie': ['DSUSERSESSID=fixture; Path=/users/; Secure'],
          },
        ),
      );
    final repo = DeltaRepository(vault: vault, client: dio, now: () => now);
    await repo.login('https://portal.example/users/', 'fixture', 'fixture');
    now = now.add(const Duration(minutes: 16));
    expect(
      await DeltaRepository(vault: vault, now: () => now).restore(),
      false,
    );
    expect(vault.value, isNull);
  });
}
