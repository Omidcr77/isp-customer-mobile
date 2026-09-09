# Verification — 2026-09-09

- Portal connectivity: HTTP 301 → 200 verified from the workstation.
- Authorized browser login: successful; account-scoped read-page navigation inspected.
- Browser logout: returned to login; subsequent authenticated report returned SessionExpire (HTTP 200 HTML envelope).
- No transactional/account-update requests submitted.
- `flutter test`: **20 passing tests**, including parser/conversion, actual repository with mocked Dio responses, authentication state, expiry, unreachable server, complete fixture login/logout and English/Dari/Pashto RTL widget checks.
- `flutter analyze`: **no issues found**.
- Formatting: checked using Dart formatter; final artifact step rechecks formatting.
- APK signature: **verified** with apksigner (v2 signature, one signer).
- Final Android debug APK: **build succeeded**, including the last parser guard. Package metadata verified with aapt2: `net.customerportal.isp_customer_mobile`, version `0.1.0` (1), min SDK 24, target SDK 36.
- Android device tests: **not run to completion**. KVM access was unavailable; software emulation exposed ADB but remained too unresponsive for reliable execution. The emulator was shut down. `integration_test/app_test.dart` includes native secure-storage round-trip/clearing and fixture login/logout tests for a working emulator or test phone.

Tests contain invented data and never connect to the production portal. The native device fixture test is distinct from the host tests and must not be reported as passed unless the emulator executes it successfully. No real-device performance, accessibility audit, Play Store release, or production penetration test is claimed.

Build environment corrections: relocated the Flutter/Android tooling from RAM-backed `/tmp` to the main disk after NDK extraction exhausted temporary space; selected the existing complete Temurin JDK 21 because the system Java 21 directory lacked a compiler. The emulator had no KVM access; software emulation was attempted and shut down after unreliable boot behavior. No production-server settings changed.

## APK artifact

`artifacts/isp-customer-mobile-debug.apk`

SHA-256: `69ccf20ac03962b20efadd5d1316969ef50959543eb1787f74fa0e679329ad66`

The debug manifest declares backup disabled and HTTP allowed; application code additionally requires explicit HTTP acknowledgement. Release manifest/code prohibit HTTP. This is a debug build, not a signed production release.
