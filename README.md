# My Internet — ISP customer Android app

Native Flutter Android client for the inspected DeltaSIB portal. This is a working read-only integration project, **not a production-release certification**. It does not embed a website or contain test-account credentials.

## Version 0.1.3: explicit connection login

The login screen uses the fixed provider address `http://192.168.10.2/users/`; there is no URL setting or SERVER_URL override. Connect to the ISP Wi-Fi and acknowledge HTTP transport. **The checkbox only records acknowledgment; it does not submit a login.** Then choose **Sign in with my connection**, or enter your own username/password and tap **Sign in**. The app does not extract passwords saved in Chrome. Logout never automatically signs back in.

Connection login uses the portal's existing AutoLogin action and verifies that the returned session can access the account before opening the dashboard. If the server refuses or redirects this flow, the app offers manual sign-in instead of claiming an existing session expired. An application-generated support code identifies the failed stage/status without exposing URLs, credentials, cookies or customer IDs. Redirects remain blocked.

The exact failure reported on the customer's phone has not been reproduced from this workstation. The live workstation AutoLogin request was rejected; success is covered by mock responses and still needs confirmation from an eligible customer connection. Automatic login depends on the portal's network-to-account mapping and may fail over mobile data or a VPN.

## Version 0.1.1 login fix

Version 0.1.0 incorrectly treated expiry-marker strings inside the dashboard's normal JavaScript error handlers as a real expired session, clearing a successful login. Version 0.1.1 checks response payloads and actual authentication controls instead. Updated dashboard fixtures reproduce the original failure, and the 22-test suite passes after the fix. Install the updated APK over the existing app and sign in again; a password change is not required for this bug.

## Open and build

Toolchain used: Flutter 3.47.2 / Dart 3.13.2, JDK 21, Android SDK 36 (Gradle may install additional pinned SDK/NDK components), minimum Android API 24. Install Flutter and Android command-line tools or Android Studio; accept the local SDK licenses. No tooling is installed on the ISP server.

```sh
cd /home/omid/projects/isp-customer-mobile
export PATH=/home/omid/projects/.isp-toolchain/flutter/bin:$PATH
export ANDROID_HOME=/home/omid/projects/.isp-toolchain/android-sdk
export JAVA_HOME=/tmp/khazana-jdk
export TMPDIR=/home/omid/projects/.isp-toolchain/tmp
flutter pub get
dart format --output=none --set-exit-if-changed lib test integration_test
flutter analyze
flutter test --dart-define=ALLOW_HTTP=true
flutter build apk --debug \
  --dart-define=ALLOW_HTTP=true
```

On another workstation, replace the toolchain environment paths with your installed Flutter/Android SDK/JDK. The project does not rely on `.env` loading; `.env.example` explains the compile-time flags. `android/local.properties` is machine-local and ignored.

Deliverable copies are in `artifacts/`: the debug APK and a source ZIP. Normal build output is `build/app/outputs/flutter-apk/app-debug.apk`. Install locally with:

```sh
adb install -r build/app/outputs/flutter-apk/app-debug.apk
```

The phone must be on a network that can reach the fixed portal. The debug HTTP checkbox explicitly acknowledges plaintext transport. Automatic login sends no username or password; manual login remains available. No real credentials are pre-filled. Sessions previously saved for a different origin are discarded.

Before release, migrate to a valid HTTPS endpoint through a reviewed change to `lib/core/portal_config.dart` and configure private signing. HTTP remains blocked in release even if ALLOW_HTTP is set, so the current fixed HTTP address is for LAN debug use. Follow the official [Flutter Android signing/build guide](https://docs.flutter.dev/deployment/android). Do not distribute a debug APK as a production release.

## App behavior

Drawer: overview, active service, traffic, usage, balance, payment history, packages, reports, documents, notifications, profile, invoices and settings. Bottom navigation gives quick access to overview, usage, payments and settings. Pull down to refresh. Usage follows account-owned service links to monthly and daily detail, with native charts when data is parseable. Tables preserve all supplied columns and scroll horizontally. Day counters come directly from the portal. Dates/currency remain in the original format.

English, Dari/Persian and Pashto app copy; RTL layouts for both regional languages. Known portal labels are translated, customer-supplied values remain original. Pashto framework controls use Persian fallback where necessary. Language selection is currently in-memory and resets on process restart.

Sessions use encrypted platform storage and an absolute 15-minute app cap, with server-expiry handling. Backgrounding removes visible account data until refreshed. Logout attempts server invalidation and clears local state even if offline. Android screenshots and backup are disabled for customer privacy. Storage setup follows [flutter_secure_storage guidance](https://pub.dev/packages/flutter_secure_storage).

## Structure

```text
lib/core/l10n.dart                      App and portal-label translations
lib/features/auth/                     Session state and native login
lib/features/portal/domain/             Models and replaceable repository contract
lib/features/portal/data/               Dio transport, secure vault, isolated HTML parser
lib/features/portal/presentation/       Native navigation, cards, charts and tables
test/fixtures/                         Invented sanitized HTML
integration_test/                      Device fixture flow
```

The repository exposes reads plus login/logout, with no transaction methods. Dio uses normal certificate verification and disables redirect following; see [Dio options](https://pub.dev/documentation/dio/latest/dio/BaseOptions-class.html). No WebView, server script evaluation or arbitrary URL navigation occurs. A stable provider-operated HTTPS integration service is the recommended long-term replacement for the legacy HTML adapter; none was deployed.

## Tests

`flutter test --dart-define=ALLOW_HTTP=true` runs parser/data-conversion tests, real repository integration with mocked Dio responses, authentication state tests and English/Dari/Pashto widget tests. These never call the production portal. Fixtures use fictitious names, IDs and session strings. For a connected local emulator/test phone:

```sh
flutter devices
flutter test integration_test/app_test.dart -d DEVICE_ID
```

Device integration uses a fake repository and does not transmit credentials. Verification results are recorded in `docs/verification.md`.

## Remaining unsupported features

- Purchases, renewals, payments, transfers, account/password changes, uploads, emergency credit, gift actions, reserve activation and disconnection: deliberately absent; explicit authorization required.
- Notifications: viewing may mark messages read; not requested during analysis.
- Invoice list/download: only purchase-code references were found; endpoint/workflow unverified.
- Full profile: no account-visible profile route verified; dashboard identity is available.
- Populated product cards/document downloads: analyzed account did not expose selectable products or a document table. App reports unsupported/empty content; further authorized fixtures are needed.
- Live online/offline connection: permission to connect is available, but a live session-status source was not verified.
- Original portal client-side history filters, natural server timeout tests, all possible status/validation branches, and full portal-content translation are not complete.

See [portal analysis](docs/portal-analysis.md), [endpoint inventory](docs/endpoint-inventory.md), and [security review](docs/security-review.md). No claim is made that these unverified features work. Plain HTTP exposes credentials; HTTPS or a protected network path is required before public deployment.
