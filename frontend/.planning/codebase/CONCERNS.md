# Codebase Concerns

**Analysis Date:** 2026-05-05

---

## Tech Debt

**Duplicated base URL constant:**
- Issue: The production API base URL `'https://mobile.ivend.cloud/api/v1'` is defined as a `static const` in three separate service classes.
- Files: `lib/services/user_service.dart:42`, `lib/services/api_service.dart:6`, `lib/services/promotions_service.dart:30`
- Impact: Changing the backend URL or adding a staging environment requires editing three files. Risk of drift.
- Fix approach: Extract to a single `AppConfig` or `Env` class, e.g. `lib/config/app_config.dart`, and import from there.

**Global mutable state alongside Provider:**
- Issue: Two module-level mutable globals exist: `currentUser` (`lib/models/user_model.dart:110`) and `mockTransactions` (`lib/models/transaction_model.dart:159`). They are read directly by screens without going through the Provider tree.
- Files: `lib/models/user_model.dart:110`, `lib/models/transaction_model.dart:159`, `lib/screens/home/dashboard_screen.dart:68`, `lib/screens/home/transactions_screen.dart:57-71`, `lib/screens/home/profile_screen.dart:54`, `lib/screens/home/qr_screen.dart:611`
- Impact: State is split between Provider-notified `User` and a raw global list. The transactions list is never notified via `ChangeNotifier`, so screens that read `mockTransactions` don't rebuild when it changes without a manual `setState`. This also makes testing impossible.
- Fix approach: Move `mockTransactions` into a `TransactionsProvider` (or into `User`) and expose it through the Provider tree. Rename the variable — the "mock" prefix is misleading since it now holds live API data.

**`PromotionsService` bypasses the shared auth retry logic:**
- Issue: `PromotionsService.fetch()` makes its own raw `http.get` call with a manually attached token, bypassing `UserService.authGet()` which handles 401 token-refresh-and-retry.
- Files: `lib/services/promotions_service.dart:37-43`
- Impact: If the access token expires, promotions will silently return empty instead of refreshing and retrying. This is inconsistent with the rest of the API layer.
- Fix approach: Replace the raw `http.get` with `UserService.authGet('/promotions/')`.

**`_collapseProgress` / `_onScroll` duplicated across 5 screens:**
- Issue: The collapsing header scroll-listener pattern is copy-pasted with nearly identical code into `DashboardScreen`, `TopUpScreen`, `ProfileScreen`, `EditProfileScreen`, `TransactionsScreen`, and `LocationsScreen`.
- Files: `lib/screens/home/dashboard_screen.dart`, `lib/screens/home/top_up_screen.dart`, `lib/screens/home/profile_screen.dart`, `lib/screens/home/edit_profile_screen.dart`, `lib/screens/home/transactions_screen.dart`, `lib/screens/home/locations_screen.dart`
- Impact: Bug fixes or behavior changes must be applied in 6 places. Constants like `_expandedHeight` and `_fadeStart` differ subtly across copies.
- Fix approach: Extract to a `CollapsingHeaderMixin` or a `CollapsingHeaderDelegate` widget.

---

## Known Bugs

**`UserService.fetch()` crashes if the `/users/` response is an empty list:**
- Symptoms: `RangeError (index): Invalid value: Valid value range is empty: 0` at startup or on dashboard refresh.
- Files: `lib/services/user_service.dart:213`
- Trigger: `final userData = userDataList[0];` — if the backend returns `[]` the app throws.
- Workaround: Wrapped in a `try/catch` in `main.dart:46` and `dashboard_screen.dart:71`, so it silently fails and leaves user data unpopulated. No user-visible error is shown.

**Top-up screen does not actually call any payment API:**
- Symptoms: Tapping "Pay" shows a success modal and calls `user.addTopUp(_amount)` locally, but no API call is made. The wallet balance displayed in the app increases, but the backend is never charged. On next app restart or refresh, the inflated balance disappears.
- Files: `lib/screens/home/top_up_screen.dart:526-531`, `lib/screens/home/top_up_screen.dart:663-668`
- Trigger: Selecting any amount and tapping the confirm button.
- Workaround: None — this is a major functional gap.

**Hardcoded avatar initial 'A' in dashboard header:**
- Symptoms: The avatar circle in the dashboard header always displays the letter 'A' regardless of the logged-in user's name.
- Files: `lib/screens/home/dashboard_screen.dart:432`
- Trigger: Any user whose name does not start with 'A' sees the wrong initial.
- Workaround: The `User` model has a correct `avatarInitial` property; it is just not used here.

**Notification bell always shows the orange dot badge:**
- Symptoms: The notification indicator dot in the dashboard header is always rendered unconditionally; there is no check against unread notification count.
- Files: `lib/screens/home/dashboard_screen.dart:395-406`
- Trigger: Visible on every app open even when there are no unread notifications.
- Workaround: None.

---

## Security Considerations

**No HTTP request timeouts:**
- Risk: All `http.get` and `http.post` calls in the service layer have no timeout configured. A stalled backend will hang the app indefinitely.
- Files: `lib/services/user_service.dart` (all `http.get`/`http.post` calls), `lib/services/api_service.dart`, `lib/services/promotions_service.dart`
- Current mitigation: None.
- Recommendations: Add `.timeout(const Duration(seconds: 15))` to all HTTP calls, or use an `http.Client` configured with a timeout.

**`debugPrint` leaks payment and authentication details to console in production:**
- Risk: `debugPrint` calls are present throughout the service layer logging token refresh results, payment request details (machine ID, slot, price, order ID), and raw error messages. In Flutter release builds `debugPrint` is a no-op, but in profile builds and during development sensitive data is exposed to console/logcat.
- Files: `lib/services/user_service.dart:82,86`, `lib/services/api_service.dart:15,24,30`, `lib/screens/home/dashboard_screen.dart:72` (uses bare `print()` — not stripped in release)
- Current mitigation: None. The single bare `print()` call at `dashboard_screen.dart:72` is not stripped in any build mode.
- Recommendations: Replace the bare `print()` with `debugPrint()`. Consider a structured logging abstraction that can be silenced for release.

**Forgot password flow is a UI stub — no actual OTP is sent:**
- Risk: `ForgotPasswordScreen._sendOTP()` simply waits 1.5 seconds and sets `_sent = true`. No API call is made. Users who forget their password have no working recovery path.
- Files: `lib/screens/auth/forgot_password_screen.dart:47-57`
- Current mitigation: None.
- Recommendations: Implement a real `POST /auth/password-reset/` or equivalent endpoint call.

---

## Performance Concerns

**`_onScroll` calls `setState` on every scroll frame:**
- Problem: The scroll listener fires on every pixel of scroll and calls `setState` if `_collapseProgress` changes, which re-renders the full screen subtree. This pattern exists in at least 5 screens.
- Files: `lib/screens/home/dashboard_screen.dart:76-83`, same pattern in top_up, profile, edit_profile, transactions, locations screens.
- Cause: No debouncing or `ValueNotifier` + `AnimatedBuilder` isolation.
- Improvement path: Use a `ValueNotifier<double>` for collapse progress, drive a dedicated `AnimatedBuilder` scoped to only the header widget so the full screen does not rebuild on scroll.

**`main()` performs two blocking API calls before `runApp()`:**
- Problem: `UserService.fetch()` and `TransactionsService.fetch()` are both `await`-ed in `main()` before `runApp()` is called. If the backend is slow, users see a blank screen (or whatever the OS shows) for the full request duration.
- Files: `lib/main.dart:38-48`
- Cause: Pre-fetch before app initialization.
- Improvement path: Call `runApp()` immediately (show `SplashScreen`), then kick off the data fetch asynchronously inside the splash or a startup service.

---

## Missing Error Handling

**Silent camera start/stop failures in QR screen:**
- Files: `lib/screens/home/qr_screen.dart:129`, `lib/screens/home/qr_screen.dart:139`, `lib/screens/home/qr_screen.dart:225`
- What's missing: `_cam.start()`, `_cam.stop()`, and the QR URI parser all catch all exceptions with `catch (_) {}` (empty body). If the camera fails to start, the user sees a black screen with no message.

**`UserService.fetch()` throws on non-200 responses with no user message:**
- Files: `lib/services/user_service.dart:220-221`
- What's missing: `throw Exception('Failed to load user data')` is caught in `_DashboardScreen._fetchData()` at line 71, but the catch block only calls `print()` — no error state is set and the UI shows no feedback.

**`authGet`/`authPost` return the raw failed response on refresh failure:**
- Files: `lib/services/user_service.dart:101-113`, `lib/services/user_service.dart:127-140`
- What's missing: If the token refresh fails, the original 401 response is returned to the caller without any indication that authentication has permanently failed. There is no automatic logout or redirect to sign-in.

**Edit profile save shows success without any API call:**
- Files: `lib/screens/home/edit_profile_screen.dart:66-149`
- What's missing: `_save()` validates the form, shows a success modal, and dismisses. No API call is made. Changes to name, email, or password are not persisted to the backend.

---

## Incomplete / Placeholder Features

**Top-up payment flow — UI only, no backend:**
- `lib/screens/home/top_up_screen.dart` displays Card, Apple Pay, and Google Pay options and a success dialog, but makes no payment API calls. The wallet balance is updated locally only.

**Password reset — UI only, no backend:**
- `lib/screens/auth/forgot_password_screen.dart:47-57` simulates a 1.5-second loading delay and then shows a "code sent" message. No real OTP or reset email is dispatched.

**Profile edit — UI only, no backend:**
- `lib/screens/home/edit_profile_screen.dart` has form fields for name, email, current password, and new password but no save API call.

**Points system is fully commented out / stubbed:**
- The `_PayMethod.points` enum value exists in `qr_screen.dart` and renders a tile showing hardcoded `'2,450 pts ≈ EGP 24.50'`. The `_PayMethod.applePay` and `_PayMethod.card` enum values also exist but are never surfaced in the UI — only `balance` is offered.
- Files: `lib/screens/home/qr_screen.dart:545`, `lib/screens/home/qr_screen.dart:864-870`
- The points wallet stat rows in `dashboard_screen.dart` (lines 599-628) and `transactions_screen.dart` (lines 63-70) are commented out. The `User.totalPointsEarned` / `totalPointsUsed` fields are populated by `updateFromTransactions()` but the backend returns `pointsDelta: 0` for all transactions.

**Profile settings toggles (notifications, dark mode, biometric) do nothing:**
- `_notificationsOn`, `_darkModeOn`, `_biometricOn` are declared in `ProfileScreen` state but their switch widgets are commented out.
- Files: `lib/screens/home/profile_screen.dart:20-22`, lines 182-207.

**Tier system is always 'Standard':**
- `UserData.fromJson` hardcodes `tier: 'Standard'` regardless of backend response. The `User.tier` getter exists but is commented out in the profile screen.
- Files: `lib/services/user_service.dart:35`.

**`_demoScan()` method is dead code:**
- `QrScreenState._demoScan()` at `lib/screens/home/qr_screen.dart:240-245` creates a fake ivend payment string using an old colon-delimited format (not the current `ivend://pay?` query-param format) and calls `_handleScan`. It is never called from anywhere and would produce a parse failure (`_parse` would return `null`) if it were.

---

## Dead Code / Commented-Out Code

**Entire `_AdsCard` widget (130+ lines):**
- Files: `lib/screens/home/dashboard_screen.dart:638-807`
- A fully-implemented promotional card widget with animation is entirely commented out. The class `_WalletStat` (lines 809-855) is also defined but never used (its call sites inside the balance card are commented out).

**Points wallet stat row in balance card:**
- Files: `lib/screens/home/dashboard_screen.dart:599-628`
- ~30 lines of commented-out code including a divider, `_WalletStat` widgets, and `Icons.stars_rounded` display.

**Transactions filter for 'Points' type:**
- Files: `lib/screens/home/transactions_screen.dart:63-70` — the points filter case is commented out. The `_Filter.points` enum variant is removed but `TransactionType.pointsEarned` and `pointsRedeemed` remain in the model.

**Phone field in edit profile:**
- Files: `lib/screens/home/edit_profile_screen.dart:37,59` — `_phoneCtrl` reference is commented out in the listener list and dispose.

**`_TopBtn` back arrow in QR screen:**
- Files: `lib/screens/home/qr_screen.dart:407-410` — back navigation button is commented out.

**`const _filters` in locations screen:**
- Files: `lib/screens/home/locations_screen.dart:10` — the filter constants array is commented out.

---

## Test Coverage Gaps

**Zero test files exist:**
- What's not tested: The entire codebase has no test files. `flutter test` would run nothing.
- Files: All files under `lib/`
- Risk: Any regression in the payment flow (`ApiService.payQR`), token refresh logic (`UserService.refreshAccessToken`), or transaction parsing (`TransactionModel.fromOrderJson`, `TransactionModel.fromBackendJson`) goes undetected.
- Priority: High — the payment path is critical and has no coverage whatsoever.

**No integration or widget tests for auth flow:**
- What's not tested: Sign-in, sign-up, token storage, logout.
- Priority: High.

---

## Dependencies at Risk

**`withOpacity` deprecated in Flutter 3.x (223 usages):**
- Risk: `Color.withOpacity()` is deprecated in Flutter 3.27+ in favor of `Color.withValues(alpha: ...)`. All 223 usages across the codebase will generate deprecation warnings in newer Flutter SDK versions.
- Impact: No immediate breakage, but accumulating warnings make it harder to spot real issues. Will eventually be a breaking change.
- Migration plan: Replace `color.withOpacity(x)` with `color.withValues(alpha: x)` throughout. Can be done incrementally.

**`qr_flutter: ^4.1.0` — imported but may be unused:**
- The `qr_flutter` package is declared in `pubspec.yaml` but no `QrImageView` or `QrImage` widget was found in any screen (the app scans QR codes, it doesn't generate them).
- Files: `pubspec.yaml:14`
- Impact: Adds to APK/IPA size unnecessarily.
- Migration plan: Verify with `flutter pub deps` and remove if unused.

---

*Concerns audit: 2026-05-05*
