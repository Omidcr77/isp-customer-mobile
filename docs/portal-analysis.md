# Portal analysis

Analyzed 2026-09-09 from the authorized workstation. Target: `http://192.168.10.2/users/`. No credentials, cookie values, account identifiers, customer records, raw responses, or HAR files are included in this project. Test fixtures are invented data based on inspected markup.

## Method and scope

Connectivity confirmed: `/users` returned HTTP 301; `/users/` returned HTTP 200 from the supplied LAN address. Chromium through Playwright rendered the real portal, submitted the explicitly authorized login, and observed browser document/XHR requests. Network event instrumentation was used rather than a manually opened DevTools panel; only methods, paths and parameter **names** were printed. DOM inspection recorded field names and navigation. Login succeeded. A second login checked display formats and day counters. Logout was tested successfully; a report requested afterward returned an HTML error envelope containing `~SessionExpire` with HTTP 200.

Only page-rendering requests, authentication and logout were submitted. No purchase, renewal, transfer, password change, profile edit, file upload, payment, reserve activation, emergency credit, gift change or disconnect operation was submitted. Read-page POSTs are distinguished from transactional POSTs below. No production configuration or software was changed.

This is an account-scoped discovery, not a claim that every installation, role, populated dataset or server-side branch has been tested. Notification rendering was intentionally withheld because opening messages may mark them read. Natural server timeout duration, incorrect-password server responses, and transaction validation were not induced. No authentication/authorization boundary was bypassed. A code reference alone is not treated as a verified API.

## Interface and feature inventory

| Feature | Observed portal behavior | Mobile support |
|---|---|---|
| Home/login | Persian interface; Fa/En language choices; iframe home and login | Native login; English, Dari/Persian and Pashto app copy |
| Dashboard | Customer name and username; service, credit, finance and gift tabs | Native cards, pull-to-refresh and hourly chart |
| Active service | Account status, connection permission, package, start and end dates | Native service details |
| Days | Total duration, elapsed and remaining days in chart legend | Portal-provided values; no calendar guessing |
| Traffic | Charged/free traffic, upload/download/actual total, service/extra balance | Native fields and used/remaining GiB summary |
| Hourly graph | Embedded Chart.js numeric array; hourly details 0–1 through 23–24 | Native accessible bar chart; no JS execution |
| Usage reports | Service list → monthly totals → daily rows including hourly columns | Validated drill-down, tables and daily/monthly charts when rows contain recognized units |
| Account status | Observed vocabulary `Enable`; connection permission `دارد` | Original status preserved; permission is not claimed to mean a live connection |
| Financial balance | Credit-status field and increase-credit/payment button | Read-only credit field; currency kept as supplied |
| Service history | Cost, tax, discount, paid amount, method, type, status | Read-only table; portal client filters not reproduced |
| Payment history | Serial, timestamp, type, amount, balance, transaction number | Read-only native table |
| Gift history | Page rendered without table headers/records | Empty state |
| Installment history | Page rendered without table headers/records | Empty state |
| Packages | Base, extra traffic, extra time and special-service selection pages exist; no selectable entries in this account | Base catalog read attempted; unsupported/empty-layout notice. Populated card layout needs further verification |
| Documents | Page has file-upload control; no document table observed | No upload; explicit unsupported-content state if no supported table returned |
| Notifications | Navigation handler exists and hides unread popup | Withheld: opening could alter read status; explanatory screen |
| Profile | Customer identity on dashboard; `UserProfile` handler in source, no visible profile control found | Dashboard identity only; no unverified profile request |
| Invoices | `CanInvoice=Yes`, `CanPrintInvoice`, and invoice link generation in purchase code | No verified invoice list/download workflow; explanatory screen |
| Password change | Old/new/confirmation form and client validation inspected | Not implemented: mutation requires separate authorization |
| Logout | POST Logout; iframe returns to login; subsequent report rejects session | Server logout with local clearing even when network fails |
| Other actions | Reserve activation, emergency traffic, credit transfer, payment, gifts, disconnect | Not implemented |

## Field, translation and format inventory

Dashboard labels (original → English meaning):

- `کاربر گرامی`, `کاربر گرامی :` → customer; `نام کاربری`, `نام کاربری :` → username.
- `ترافیک محاسبه شده` → charged traffic; `ترافیک مصرفی رایگان` → free traffic.
- `ارسال واقعی` → actual upload; `دریافت واقعی` → actual download; `مجموع مصرف واقعی` → total actual usage.
- Hour ranges `0 تا 1` through `23 تا 24` → hourly details.
- `وضعیت اشتراک` → subscription/account status; `مجوز اتصال` → permission to connect.
- `سرویس فعال` → active service; `تاریخ شروع سرویس` → start; `تاریخ پایان سرویس` → expiry.
- `آخرین بروز رسانی` → last update; `مانده ترافیک سرویس` → remaining service data; `مانده اضافه ترافیک` → remaining extra data.
- `وضعیت اعتبار` → credit status; `وضعیت هدیه` → gift status.
- `مدت کل سرویس`, `مصرف شده`, `باقیمانده` with `روز` → duration, elapsed days, remaining days.
- `کل ترافیک سرویس`, `مصرف شده`, `باقیمانده` with data units → total/used/remaining traffic.

Report columns:

- Service selection: `#`, `نام سرویس`, `وضعیت`, start/end date, `جزئیات`.
- Monthly: `سال`, `ماه`, `مجموع ارسال واقعی`, `مجموع دریافت واقعی`, `مجموع مجموع مصرف واقعی`, details.
- Daily: `روز`, charged/free traffic, actual upload/download/total, 24 hour ranges.
- Service history: `زمان`, `نام سرویس`, `وضعیت سرویس`, `هزینه سرویس`, `ارزش افزوده`, `تخفیف`, `هزینه پرداختی`, `روش خرید`, `نوع`.
- Payments: `سریال`, `زمان`, `نوع`, `مبلغ`, `موجودی`, `شماره تراکنش`.

Date values use `NNNN/NN/NN`. Calendar and server timezone were not independently established; dates remain verbatim. Remaining days come directly from rendered text. Currency is not inferred or converted. Source JavaScript formats money with comma grouping and zero decimal places by default. Data units `بایت`, `کیلو`, `مگ`, `گیگ` use powers of 1024 in `ByteToR`; app chart labels explicitly use GiB. Persian and Arabic digits are normalized only for numeric conversion. Portal content remains in its original language when no reviewed translation exists. App-owned copy and known field labels have English/Dari/Pashto mappings. Human linguistic review remains a release requirement; Pashto framework controls use Persian fallback where Flutter lacks translations.

## Validation and workflows

Login: `Username` and `Password`, both required (`pt=NE`) and maximum 32 characters. Username tooltip asks for username; password tooltip asks for password. Password typing warns `توجه! صفحه کلید فارسی می باشد` when outside the JavaScript Latin-character whitelist. No CAPTCHA or login CSRF field was observed. Empty request responses display `Empty response`; successful login parses `OK~<user-id>`. Leading `~` indicates an error. Generic AJAX unwraps `<data><Error><![CDATA[...]]></Error></data>`.

Password form: `OldPass`, `NewPass1`, `NewPass2`; client rejects mismatched new/confirmation (`رمز عبور جدید و تكرار آن یكی نیست`) and unchanged old/new (`رمز عبور قدیم و جدید یكی هست`). These were read from client code, not triggered against the account. Payment form exposes `PayBalance` and `PayPrice`; amount submission was not tested. Document form exposes file upload; it was not used.

Expiry: `~SessionExpire`, `~ChangeUser`, and timeout callbacks redirect toward login. Logout does not necessarily remove browser cookie objects; its server invalidation was verified separately. Cookie names: `DSUSERSESSID`, `DSUserTimeOut`. Both appeared without Secure or HttpOnly; Chromium reported SameSite Lax. No cookie/token values recorded. True idle/absolute server timeout and CSRF protections on unsubmitted mutations remain unknown.

## Architecture decision

Native Flutter → Riverpod session controller and screen state → `PortalRepository` interface → `DeltaRepository` (Dio, encrypted session vault, same-origin requests) → isolated `PortalHtmlAdapter` → immutable domain data → native widgets.

Direct Android integration works without browser CORS constraints. The legacy HTML contract is fragile and private-address-only. A provider-operated HTTPS integration service with a stable, versioned read-only JSON contract is preferable before broad deployment, particularly if portal schema or network exposure cannot be controlled. No such service was deployed or invented as an existing API. No WebView, JavaScript bridge or TLS bypass is used.
