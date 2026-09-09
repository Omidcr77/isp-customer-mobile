# Sanitized endpoint inventory

App base: fixed `http://192.168.10.2/users/`. All authenticated requests use the session cookie and the **login-returned** `User_Id`; no arbitrary customer IDs are discovered or iterated. Parameters below are names, except public action selectors. Responses were HTML or delimited text, not a documented REST/JSON API.

| Relative path | Method | Parameters | Evidence / classification |
|---|---|---|---|
| `/users` | GET | none | 301 to trailing slash |
| `/users/` | GET | none | 200 iframe wrapper |
| `computer/DS_Home.php` | GET | WebNewUser, NCR, Feedback, User_Id, Device | Browser home |
| `computer/Custom.php` | GET | none | Public embedded landing content |
| `computer/DS_Login.php` | GET | same iframe parameters | Login form |
| `commonpages/DSUserProcessLogin.php` | POST | query User_Id; form Username, Password, act=ManualLogin | Successful authorized login; text `OK~<id>` |
| `commonpages/DSUserProcessLogin.php` | POST | query User_Id=0; form act=AutoLogin only | Public wrapper callback and AJAX helper inspected; live request rejected on workstation connection; app supports normal login response and manual fallback |
| `computer/DS_MyInternet.php` | GET | User_Id, Device, WebNewUser, NCR, Feedback | Authenticated full HTML dashboard |
| `computer/DS_Rep_DailyUsage.php` | POST | query User_Id; form Type=Totally | Account service report |
| same | POST | query User_Id; Type=Monthly, User_ServiceBase_Id | Monthly totals; identifiers follow links belonging to account |
| same | POST | query User_Id; Type=Daily, User_ServiceBase_Id, Year, Month | Daily rows and hourly columns |
| `computer/DS_Rep_ServiceHistory.php` | POST | query User_Id | Read-only history HTML |
| `computer/DS_Rep_PaymentHistory.php` | POST | query User_Id | Read-only payment HTML |
| `computer/DS_Rep_GiftHistory.php` | POST | query User_Id | Empty report observed |
| `computer/DS_Rep_InstallmentHistory.php` | POST | query User_Id | Empty report observed |
| `computer/DS_Attachment.php` | POST | query User_Id; CanPrintInvoice | Document/upload page rendering only |
| `computer/DS_ChangePassword.php` | POST | query User_Id; CanPrintInvoice | Password form rendering only; app does not call |
| `computer/DS_BuyService.php` | POST | query User_Id; type, CanPrintInvoice | SelectServiceBase / SelectServiceExtraTraffic / SelectServiceExtraTime / SelectServiceOther page reads; no selection submitted |
| `computer/DS_TransferCredit.php` | POST | query User_Id | Transfer form rendering only; app does not call |
| `computer/DS_PayPrice.php` | POST | query User_Id; CanPrintInvoice | Payment form rendering only; app does not call |
| `computer/DS_EmergencyServiceExtraTraffic.php` | POST | query User_Id; CanPrintInvoice | Emergency form rendering only; no credit requested |
| `commonpages/DSMyInternetRender.php` | POST | query User_Id, act=Logout | Logout verified; subsequent report yielded SessionExpire |

## Source references only, not executed or exposed by app

- `computer/DS_UserMessage.php`: navigation exists; potential mark-as-read effect prevents a read-only assumption.
- `computer/DS_UserProfile.php`: handler exists, not verified as visible/available to account.
- `computer/DS_Rep_ConnectionHistory.php`, `DS_Rep_SavingOffHistory.php`: switch cases only, no visible account entry verified.
- `commonpages/DSInvoice.php?Id=...`: invoice code reference; no verified list or download access.
- `computer/DS_verifyAgreement.php`: purchase agreement step.
- `commonpages/DSMyInternetRender.php`: source mentions ChangePass, TransferCredit, AddEmergencyCredit, ActiveServiceReserve, Disconnect, ActiveGift, AbandonGift, FindFamily, CheckShahkar, GetServicePrice. No requests to these actions were made. Parameter contracts and side effects must be reviewed before any future implementation.
- AutoLogin uses the normal authentication handler; no username, password or customer ID is inferred by the app.

## Authentication and transport

Cookies: DSUSERSESSID and DSUserTimeOut, values omitted. Observed flags lacked Secure/HttpOnly; SameSite Lax reported by browser. No CSRF input was observed in the inspected login/password forms; absence in inspected markup is **not** proof that the server has no CSRF defense. App follows no redirects, rejects non-HTTPS release URLs, uses normal platform certificate validation, and reads only fixed page paths. It never evaluates returned scripts or follows invoice/document/external links.

Browser network capture was programmatic. Natural authentication timeout, incorrect-login response text, populated catalog/documents, notification effects, and transaction responses were not tested. All tests in the repository run with synthetic fixtures; they do not contact the portal.

## Connection login update (0.1.2)

Read-only public source inspection found `ShowAutoLogin(Username, Delay)`, whose confirmation/countdown calls `DoAjax` with `act=AutoLogin`. The helper sends a POST and appends `User_Id`; its success callback accepts `OK~<id>`. The workstation wrapper did not invoke ShowAutoLogin for this connection. A normal AutoLogin request with an in-memory cookie jar returned HTTP 200 with an error envelope, not a successful identity. No credential or cookie values were saved. Successful connection detection on an eligible phone remains unverified; browser password-manager autofill is a separate mechanism that this endpoint does not provide.
