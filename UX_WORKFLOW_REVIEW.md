# Critical and high-priority UX fixes

Implemented on 2026-10-17.

| Priority | Area | Result |
|---|---|---|
| Critical | Amount precision | Expense, bill and debt edit fields preserve two decimal places. Shared amount validation rejects non-finite values and fractional paise. Expense and bill records store integer minor units alongside the compatible amount field. |
| Critical | Bill payment | One transaction records payment, its optional expense and the next recurring bill. Stable document IDs and the stored paid flag prevent duplicate records on retries. Failed payments show a retry message. |
| High | Add action | The main Add menu offers Expense, Income, Scan receipt and Scan QR, with manual expense first. Income creation, updates and deletion update the income balance with the record in a transaction. |
| High | Reminders | Bill forms include a time picker and a local-date/time preview. Due dates remain current throughout the due day. Recurrence clamps short months while preserving the original day. Daily scheduling uses calendar days across DST. Schedules refresh on launch/data loading and app resume, including time-zone changes. |
| High | Income onboarding | Skip for now persists. A new month no longer blocks the dashboard. A dashboard card offers updating income or reusing last month's income. Existing users retain their completed setup. |
| High | Password recovery | Sign-in provides Forgot password, with email validation, progress, retry and a generic confirmation message. |
| High | QR payment flow | Opens a UPI payment chooser. On return, asks whether payment completed. Explicit confirmation opens an editable expense draft; only Save records it. Opening a payment app never records a payment. A manual completion action covers missing lifecycle callbacks. |

Receipt cancellation returns to the draft. OCR failure offers retry or manual entry and closes only its own loading dialog.

## Validation

- `flutter test`: 21 tests passed, including existing session/privacy/theme tests.
- `flutter analyze --no-pub --no-fatal-infos`: no errors or warnings; 144 informational lint/deprecation notices remain.
- Added regression coverage for monetary input and round trips, recurrence, due-day status, repeated bill payments, income record/balance consistency, persisted setup, encoded UPI parameters and daily scheduling across regions/DST.
- Widget checks cover decimal preservation, password recovery retries, explicit QR confirmation, and reminder previews/time pickers in light and dark themes.
- Firestore repository tests use an in-memory implementation; they are not live-service or device integration tests.

## Release checks still required

- Test payment-app handoff, camera permissions and notifications on physical Android devices, including denied permissions and battery restrictions.
- Android schedules are inexact. The selected time is the requested local time; operating-system restrictions can delay delivery. Travel-related schedules refresh when the app is opened/resumed; changes while the app remains closed require device verification.
- Keep the Functions backend undeployed as previously requested. Billing/key setup and backend-dependent release checks remain outstanding.
- The previously generated release bundle predates these changes. Build and test a new signed release bundle before uploading to Play Console.
