# Security review

## Implemented

- Password used only for login, cleared from the input immediately after submission, never saved. Immutable Dart strings cannot be guaranteed memory-zeroed.
- Session cookies, user ID, origin and issuance time stored as one flutter_secure_storage entry. No real credentials in source, examples, fixtures or documentation.
- Session cookies in memory use CookieJar domain/path/expiry rules. Persisted sessions are bound to their origin. Origin change begins by clearing old state.
- Login accepts only a configured HTTP(S) `/users/` root with no user-info, query or fragment. HTTP requires debug compilation with ALLOW_HTTP and explicit user acknowledgement; release blocks it even if ALLOW_HTTP is set.
- Redirects are not followed. TLS verification is never disabled. No credential forwarding across redirects.
- Session lifetime is conservatively capped at 15 minutes. Server expiry and user-change markers clear authentication. App backgrounding clears rendered customer content; resumption refetches or expires.
- Logout attempts server invalidation and always clears local state. An unreachable server may keep its own session alive until server expiry; the UI reports failure without retaining the local session.
- Android backup disabled. FLAG_SECURE protects screenshots and recent-app previews.
- Fixed read endpoints and validated usage-navigation parameters. No transactional repository methods or actionable portal HTML. HTML converted into plain native text/tables. Script arrays are parsed as numeric data, never evaluated. No WebView or JavaScript bridge.
- No request/body logging, analytics or crash-report uploads. Error UI uses controlled messages, not raw Dio exceptions/server bodies. Response strings are limited to 4 MiB after receipt (not a streaming download cap).
- Language selection contains no secrets. No fixture contains actual customer data. Dependencies are locked by pubspec.lock.

## Observed server risks and release gates

1. Plain HTTP exposes credentials and session data to network observers. Use HTTPS with a valid certificate, preferably through a provider-controlled reverse proxy; protected VPN access can secure the network path. Do not publish the current LAN debug configuration as a production service.
2. Session cookies observed without Secure or HttpOnly. Server cookie and CSRF hardening needs an independently authorized server task; nothing was changed here.
3. Account-level HTML markup is not a stable API. Populated packages, attachments, invoices and notifications need further authorized discovery. Consider a stable HTTPS backend integration service, with logs redacted, before wide release. CORS is a browser policy and does not itself prevent native Android networking.
4. Secure storage protects data at rest, not against a compromised/rooted device. No certificate pinning is provided; platform trust is used.
5. Human review of Dari/Pashto translations is outstanding. Portal-supplied values remain original; Pashto Material framework strings fall back to Persian.
6. No purchase, renewal, payment, credit transfer, password/profile edit, upload, gift activation, emergency credit, disconnect or reserve activation is implemented. Each requires explicit authorization and separate threat/workflow review.
7. A production signing key and distribution process are not configured. Release builds must not use the debug key.
8. No physical Android device or emulator was initially attached. See README for exact verification performed; do not equate an APK build with on-device acceptance or a production security audit.

## Data limitations

The UI distinguishes connection permission from live connection status. It does not infer currency or calendar conversions. Remaining days are read directly from the portal. Unknown markup produces an explicit unsupported/empty state instead of fabricated records; some account variants can still require parser changes. Cookie rotation, concurrent session replacement, natural server timeout and backend authorization were not exhaustively audited.
