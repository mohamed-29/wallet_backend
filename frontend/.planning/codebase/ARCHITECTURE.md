<!-- refreshed: 2026-05-05 -->
# Architecture

**Analysis Date:** 2026-05-05

## System Overview

```text
┌─────────────────────────────────────────────────────────────────┐
│                        Presentation Layer                        │
│                    lib/screens/  lib/widgets/                    │
├──────────┬──────────┬──────────┬──────────┬────────────────────┤
│  Auth    │ Splash / │  Home /  │   QR     │  Locations /       │
│  Screens │ Onboard  │Dashboard │  Screen  │  Notifications     │
│ auth/*.  │ *_screen │ home/*.  │ qr_screen│  locations_screen  │
└────┬─────┴────┬─────┴────┬─────┴────┬─────┴──────────┬─────────┘
     │          │          │          │                 │
     ▼          ▼          ▼          ▼                 ▼
┌─────────────────────────────────────────────────────────────────┐
│                       Service Layer                              │
│                        lib/services/                             │
│  UserService  TransactionsService  ApiService  LocationsService  │
│  NotificationsService   PromotionsService                        │
└────────────────────────────────┬────────────────────────────────┘
                                 │ HTTP (dart:http)
                                 ▼
┌─────────────────────────────────────────────────────────────────┐
│              Backend REST API                                     │
│              https://mobile.ivend.cloud/api/v1                   │
└─────────────────────────────────────────────────────────────────┘
         │
         ▼ (provider ChangeNotifier)
┌─────────────────────────────────────────────────────────────────┐
│                      State / Model Layer                         │
│                        lib/models/                               │
│   User (ChangeNotifier)   TransactionModel   VendingLocation     │
│   NotificationModel       UserData (DTO)                         │
└─────────────────────────────────────────────────────────────────┘
```

## Component Responsibilities

| Component | Responsibility | File |
|-----------|----------------|------|
| `IvendApp` | Root widget, route table, Provider setup | `lib/main.dart` |
| `UserService` | Auth (login/register/logout), token storage, authenticated HTTP helpers | `lib/services/user_service.dart` |
| `ApiService` | QR payment call (`payQR`) | `lib/services/api_service.dart` |
| `TransactionsService` | Fetch and merge orders + wallet ledger into activity feed | `lib/services/transactions_service.dart` |
| `LocationsService` | Fetch vending machine locations | `lib/services/locations_service.dart` |
| `NotificationsService` | Fetch and mark-read notifications | `lib/services/notifications_service.dart` |
| `PromotionsService` | Fetch promotions list | `lib/services/promotions_service.dart` |
| `User` | ChangeNotifier holding all mutable user state (balance, name, points) | `lib/models/user_model.dart` |
| `TransactionModel` | Immutable transaction value object with factory parsers | `lib/models/transaction_model.dart` |
| `VendingLocation` | Immutable machine location value object | `lib/models/vending_location.dart` |
| `NotificationModel` | Mutable notification (isRead can change) | `lib/models/notification_model.dart` |
| `SplashScreen` | Animated vending machine intro, routing gate | `lib/screens/splash_screen.dart` |
| `HomeScreen` | Bottom-nav shell with `IndexedStack` for 5 tabs | `lib/screens/home/home_screen.dart` |
| `DashboardScreen` | Collapsing header, wallet balance, recent 2 transactions | `lib/screens/home/dashboard_screen.dart` |
| `QrScreen` | Camera QR scanner, payment confirmation flow | `lib/screens/home/qr_screen.dart` |
| `GlassCard` | Reusable glassmorphism container (BackdropFilter) | `lib/widgets/glass_card.dart` |
| `AppTheme` / `AppColors` / `AppFonts` | Central design tokens and Material theme | `lib/theme/app_theme.dart` |

## Pattern Overview

**Overall:** Layered Flutter monolith with Provider reactive state.

**Key Characteristics:**
- Screens call service statics directly — no repository abstraction layer
- Single `ChangeNotifier` (`User`) propagated app-wide via `ChangeNotifierProvider`
- Global mutable variables (`currentUser`, `mockTransactions`) act as in-memory cache
- All HTTP transport goes through `UserService.authGet` / `UserService.authPost` which handle JWT Bearer token injection and automatic token-refresh on 401

## Layers

**Presentation (Screens):**
- Purpose: Render UI and react to user actions
- Location: `lib/screens/`
- Contains: `StatefulWidget` and `StatelessWidget` screen classes; private widget helpers defined in same file
- Depends on: Services (direct static calls), Models (Provider or global), Theme
- Used by: Router in `lib/main.dart`

**Widget Library:**
- Purpose: Shared UI primitives reused across screens
- Location: `lib/widgets/`
- Contains: `GlassCard`, `GlassCardDark`
- Depends on: Flutter Material only

**Service Layer:**
- Purpose: All network I/O and secure storage
- Location: `lib/services/`
- Contains: Static-method classes, no instances needed
- Depends on: `http`, `flutter_secure_storage`, Models (DTOs)
- Used by: Screens (direct static calls)

**Model Layer:**
- Purpose: Data structures and deserialization
- Location: `lib/models/`
- Contains: `ChangeNotifier` (`User`), immutable value objects (`TransactionModel`, `VendingLocation`), mutable notification (`NotificationModel`)
- Depends on: Nothing (no service imports except `user_model.dart` importing `UserService` for type reference)

**Theme:**
- Purpose: Design tokens (colors, fonts, Material theme config)
- Location: `lib/theme/app_theme.dart`
- Contains: `AppColors`, `AppFonts`, `AppTheme.lightTheme`
- Depends on: Nothing

## Data Flow

### App Startup

1. `main()` calls `UserService.init()` — reads JWT tokens from `flutter_secure_storage` (`lib/services/user_service.dart:51`)
2. If token exists, `Future.wait([UserService.fetch(), TransactionsService.fetch()])` pre-loads data (`lib/main.dart:38-48`)
3. Results hydrate `currentUser` (global `User`) and `mockTransactions` (global `List<TransactionModel>`)
4. `runApp(IvendApp())` wraps app in `ChangeNotifierProvider.value(value: currentUser)`
5. `SplashScreen` runs 4.5 s animation then routes to `/onboarding`, `/home`, or `/signin` based on `UserService.isFirstTimeFlag` and `UserService.token`

### QR Payment Flow

1. User taps QR tab → `HomeScreen` activates `QrScreen` (`lib/screens/home/home_screen.dart:71`)
2. `MobileScannerController` starts camera; `onDetect` fires on barcode (`lib/screens/home/qr_screen.dart:164`)
3. `_parse()` validates `ivend://pay?` URI format, extracts `machine`, `slot`, `price`, `order_id` (`lib/screens/home/qr_screen.dart:198`)
4. `_ResultPanel._selectPayment()` calls `ApiService.payQR()` → `POST /payment/pay-qr/` (`lib/services/api_service.dart:8`)
5. On success, `UserService.fetchBalance()` refreshes wallet, `currentUser.setBalance()` triggers rebuild via `ChangeNotifier` (`lib/screens/home/qr_screen.dart:609`)

### Dashboard Refresh

1. `DashboardScreen.initState()` calls `_fetchData()` (`lib/screens/home/dashboard_screen.dart:53`)
2. `Future.wait([UserService.fetch(), TransactionsService.fetch()])` runs in parallel
3. `UserService.fetch()` hits `GET /wallet/balance/` and `GET /users/` concurrently
4. `TransactionsService.fetch()` hits `GET /payment/my-orders/` and `GET /wallet/history/` concurrently, merges and sorts newest-first
5. `Provider.of<User>(context).loadFromUserData(userData)` notifies listeners

**State Management:**
- `User` (global singleton at `lib/models/user_model.dart:110`) is the sole `ChangeNotifier`, wrapped in `ChangeNotifierProvider` at app root
- `mockTransactions` is a module-level `List<TransactionModel>` at `lib/models/transaction_model.dart:159`, updated imperatively
- Screen-local state (loading flags, scroll progress, animation controllers) lives in `State` classes

## Key Abstractions

**`UserService` as HTTP gateway:**
- Purpose: Central authenticated HTTP client — all token lifecycle management lives here
- Key methods: `authGet(path)`, `authPost(path, body)` — both auto-refresh on 401
- Location: `lib/services/user_service.dart`

**`TransactionModel` factory parsers:**
- Purpose: Two distinct backend response shapes mapped to one model
- `fromOrderJson` — parses `GET /payment/my-orders/` entries
- `fromBackendJson` — parses `GET /wallet/history/` CREDIT ledger entries
- Location: `lib/models/transaction_model.dart`

**`GlassCard`:**
- Purpose: Glassmorphism surface used on balance card and auth forms
- Pattern: Wraps `BackdropFilter` + `ClipRRect` + translucent `Container`
- Location: `lib/widgets/glass_card.dart`

## Entry Points

**App entry:**
- Location: `lib/main.dart`
- Triggers: Flutter `runApp`
- Responsibilities: Token init, data pre-fetch, Provider wiring, route table

**Route `/`:**
- Location: `lib/screens/splash_screen.dart` — `SplashScreen`
- Triggers: App start
- Responsibilities: 4.5 s branded animation, decides initial route

**Route `/home`:**
- Location: `lib/screens/home/home_screen.dart` — `HomeScreen`
- Triggers: Auth success or return from payment
- Responsibilities: Bottom-nav shell, `IndexedStack` of 5 tabs

## Architectural Constraints

- **Threading:** Single-threaded Dart event loop; all async operations use `Future` / `async-await`; no isolates
- **Global state:** Two module-level globals: `currentUser` (`lib/models/user_model.dart:110`) and `mockTransactions` (`lib/models/transaction_model.dart:159`). Both are written from multiple call sites
- **Token storage:** JWT access + refresh tokens stored via `flutter_secure_storage` under keys `auth_token` and `refresh_token` (`lib/services/user_service.dart:43`)
- **Base URL:** Hardcoded as `static const String baseUrl = 'https://mobile.ivend.cloud/api/v1'` in both `UserService` and `PromotionsService` (duplicated)
- **Circular imports:** `user_model.dart` imports `user_service.dart` for the `UserData` type; `user_service.dart` does not import `user_model.dart` — no true circular dependency

## Anti-Patterns

### Duplicated `baseUrl`

**What happens:** `baseUrl = 'https://mobile.ivend.cloud/api/v1'` is defined identically in `lib/services/user_service.dart:42` and `lib/services/promotions_service.dart:30`
**Why it's wrong:** A URL change requires editing two files; `PromotionsService` also bypasses `UserService.authGet` and constructs its own `Authorization` header manually
**Do this instead:** Define `baseUrl` once in `UserService` (or a shared constants file) and have all services call `UserService.authGet` / `UserService.authPost`

### Global mutable `mockTransactions`

**What happens:** `List<TransactionModel> mockTransactions = []` at module scope in `lib/models/transaction_model.dart:159` is written by both `main()` and `DashboardScreen._fetchData()`
**Why it's wrong:** Not notified via `ChangeNotifier`; `TransactionsScreen` reads it without reactivity; name "mock" is misleading — it holds live data
**Do this instead:** Move transactions into `User` (or a separate `TransactionsNotifier`) and expose via `ChangeNotifier`

### Private widget classes in screen files

**What happens:** Each screen file contains 5–15 private `_Foo` widget classes (e.g., `_DashboardHeader`, `_BalanceCard`, `_QuickStatCard`, `_TransactionTile` all in `dashboard_screen.dart`)
**Why it's wrong:** `dashboard_screen.dart` is 1 139 lines; `qr_screen.dart` is 1 243 lines — hard to navigate and test individual widgets
**Do this instead:** Extract reusable sub-widgets into `lib/widgets/` or per-feature widget subdirectories

## Error Handling

**Strategy:** Try/catch at service call sites; errors are swallowed with `debugPrint`; screens receive empty lists or `null` on failure

**Patterns:**
- Services return empty list / `null` / `false` on failure rather than throwing (except `LocationsService` which rethrows)
- `main()` wraps startup fetch in try/catch and continues to `runApp` regardless
- `DashboardScreen` uses `print('Fetch Error: $e')` (not `debugPrint`) — inconsistent

## Cross-Cutting Concerns

**Logging:** `debugPrint()` throughout services; one use of bare `print()` in `DashboardScreen._fetchData()`
**Validation:** Form validation via Flutter `Form` + `validator` callbacks in auth screens; no centralized validation library
**Authentication:** JWT Bearer token managed entirely by `UserService`; screens do not touch tokens directly; `UserService.token == null` guard used in services before making calls

---

*Architecture analysis: 2026-05-05*
