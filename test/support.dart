import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:isp_customer_mobile/features/portal/data/delta_repository.dart';
import 'package:isp_customer_mobile/features/portal/domain/portal.dart';

class MemoryVault implements SessionVault {
  String? value;
  @override
  Future<String?> read() async => value;
  @override
  Future<void> write(String value) async {
    this.value = value;
  }

  @override
  Future<void> clear() async {
    value = null;
  }
}

class FixtureTransport implements HttpClientAdapter {
  FixtureTransport(this.handler);
  final ResponseBody Function(RequestOptions) handler;
  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? stream,
    Future<void>? cancel,
  ) async => handler(options);
  @override
  void close({bool force = false}) {}
}

class FakeRepository implements PortalRepository {
  @override
  DateTime? get expiresAt => DateTime.now().add(const Duration(minutes: 15));
  FakeRepository({this.failure, this.restored = false});
  PortalFailure? failure;
  bool restored, cleared = false;
  @override
  Future<bool> restore() async => restored;
  @override
  Future<void> login(
    String b,
    String u,
    String p, {
    bool allowHttp = false,
  }) async {
    if (failure != null) throw PortalException(failure!);
    restored = true;
  }

  @override
  Future<PortalPage> read(
    PortalSection section, {
    Map<String, String> usage = const {},
    String report = 'ServiceHistory',
  }) async {
    if (failure != null) throw PortalException(failure!);
    return const PortalPage(
      fields: [PortalField('سرویس فعال', 'Fixture service')],
    );
  }

  @override
  Future<void> clear() async {
    cleared = true;
    restored = false;
  }

  @override
  Future<void> logout() => clear();
}
