import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/portal_config.dart';
import '../portal/data/delta_repository.dart';
import '../portal/domain/portal.dart';

final repositoryProvider = Provider<PortalRepository>(
  (ref) => DeltaRepository(vault: SecureSessionVault()),
);
final sessionProvider = NotifierProvider<SessionController, SessionState>(
  SessionController.new,
);

class SessionState {
  const SessionState({
    this.ready = false,
    this.signedIn = false,
    this.busy = false,
    this.error,
  });
  final bool ready, signedIn, busy;
  final PortalFailure? error;
}

class SessionController extends Notifier<SessionState> {
  Timer? timer;
  @override
  SessionState build() {
    ref.onDispose(() => timer?.cancel());
    return const SessionState();
  }

  Future<void> restore() async {
    try {
      final ok = await ref.read(repositoryProvider).restore();
      state = SessionState(ready: true, signedIn: ok);
      if (ok) arm();
    } catch (_) {
      state = const SessionState(ready: true, error: PortalFailure.storage);
    }
  }

  void arm() {
    timer?.cancel();
    final deadline = ref.read(repositoryProvider).expiresAt;
    final remaining =
        deadline?.difference(DateTime.now()) ?? DeltaRepository.maxAge;
    timer = Timer(
      remaining.isNegative ? Duration.zero : remaining,
      () => expire(),
    );
  }

  Future<void> login(String user, String pass, bool http) async {
    if (state.busy) return;
    state = const SessionState(ready: true, busy: true);
    try {
      await ref
          .read(repositoryProvider)
          .login(portalBaseUrl, user, pass, allowHttp: http);
      state = const SessionState(ready: true, signedIn: true);
      arm();
    } on PortalException catch (e) {
      state = SessionState(ready: true, error: e.kind);
    } catch (_) {
      state = const SessionState(ready: true, error: PortalFailure.server);
    }
  }

  Future<void> autoLogin(bool http) async {
    if (state.busy) return;
    state = const SessionState(ready: true, busy: true);
    try {
      await ref
          .read(repositoryProvider)
          .autoLogin(portalBaseUrl, allowHttp: http);
      state = const SessionState(ready: true, signedIn: true);
      arm();
    } on PortalException catch (e) {
      state = SessionState(ready: true, error: e.kind);
    } catch (_) {
      state = const SessionState(ready: true, error: PortalFailure.server);
    }
  }

  Future<void> expire() async {
    timer?.cancel();
    try {
      await ref.read(repositoryProvider).clear();
      state = const SessionState(ready: true, error: PortalFailure.expired);
    } catch (_) {
      state = const SessionState(ready: true, error: PortalFailure.storage);
    }
  }

  Future<void> logout() async {
    timer?.cancel();
    try {
      await ref.read(repositoryProvider).logout();
      state = const SessionState(ready: true);
    } on PortalException catch (e) {
      state = SessionState(ready: true, error: e.kind);
    } catch (_) {
      state = const SessionState(ready: true, error: PortalFailure.server);
    }
  }
}
