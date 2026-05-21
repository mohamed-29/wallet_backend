# Coding Conventions

**Analysis Date:** 2026-05-05

## Language & Toolchain

- **Language:** Dart (SDK `^3.5.0`)
- **Framework:** Flutter (Material 3, `useMaterial3: true`)
- **Linting:** `flutter_lints ^4.0.0` via `analysis_options.yaml` — single line: `include: package:flutter_lints/flutter.yaml`. No custom rules added on top.
- **Formatting:** Standard `dart format` (no explicit Prettier/custom config). Flutter default 2-space indentation.

## Naming Conventions

**Files:**
- `snake_case` for all Dart files. Pattern: `<noun>_<noun>.dart`
- Screens: `<feature>_screen.dart` — e.g., `sign_in_screen.dart`, `dashboard_screen.dart`
- Services: `<noun>_service.dart` — e.g., `user_service.dart`, `transactions_service.dart`
- Models: `<noun>_model.dart` — e.g., `transaction_model.dart`, `notification_model.dart`
- Widgets: `<noun>.dart` — e.g., `glass_card.dart`
- Theme: `app_theme.dart`

**Classes:**
- `PascalCase` for all public classes — e.g., `UserService`, `TransactionModel`, `GlassCard`
- Private (file-local) helper classes: prefixed with `_` — e.g., `_SplashScreenState`, `_FieldLabel`, `_VendingMachinePainter`, `_Blob`, `_Product`
- State classes: `_<WidgetName>State` — e.g., `_SignInScreenState`

**Variables & Fields:**
- `camelCase` for local variables, instance fields, parameters
- Private instance fields prefixed with `_` — e.g., `_token`, `_loading`, `_formKey`
- Public getters expose private fields: `String get name => _name;`
- Constants: `camelCase` for static consts — e.g., `static const String baseUrl`, `static const double _expandedHeight`
- Section-separating `static const` values use SCREAMING_SNAKE_CASE only for true compile-time intent labels (not found; camelCase used throughout)

**Methods/Functions:**
- `camelCase` — e.g., `refreshAccessToken()`, `loadFromUserData()`, `_signIn()`
- Private methods prefixed with `_` — e.g., `_fetchData()`, `_onScroll()`, `_paintMachine()`
- Factory constructors named descriptively: `fromJson`, `fromOrderJson`, `fromBackendJson`, `listFromJson`

**Enums:**
- `PascalCase` for enum type, `camelCase` for values — e.g., `TransactionType { purchase, pointsEarned, pointsRedeemed, topUp }`

## Import Organization

**Order (observed consistently):**
1. Dart core libraries — `dart:convert`, `dart:ui`, `dart:math as math`
2. Flutter framework — `package:flutter/material.dart`, `package:flutter/foundation.dart`, `package:flutter/services.dart`
3. Third-party packages — `package:http/http.dart as http`, `package:provider/provider.dart`, `package:flutter_secure_storage/...`
4. Local relative imports — `'../../theme/app_theme.dart'`, `'../models/user_model.dart'`, `'user_service.dart'`

Relative paths are used for all local imports (no path aliases). Parent-traversal depth matches directory depth (e.g., screens use `../../`, services use `../`).

## File & Directory Structure Conventions

```
lib/
  main.dart               # App entry point and route table
  models/                 # Pure data classes with fromJson factories
  screens/
    auth/                 # Authentication screens
    home/                 # Post-auth screens
    <screen>.dart         # Top-level screens (splash, onboarding)
  services/               # Static-method API service classes
  theme/                  # AppColors, AppFonts, AppTheme
  widgets/                # Reusable UI components
```

## Widget Patterns

**StatefulWidget structure:**
```dart
class MyScreen extends StatefulWidget {
  const MyScreen({super.key});

  @override
  State<MyScreen> createState() => _MyScreenState();
}

class _MyScreenState extends State<MyScreen>
    with SingleTickerProviderStateMixin {
  // controllers declared with late final
  late final AnimationController _ctrl;
  // form keys, scroll controllers declared without late
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() { super.initState(); /* setup */ }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) { ... }
}
```

**StatelessWidget structure:**
```dart
class GlassCard extends StatelessWidget {
  final Widget child;
  final double borderRadius;

  const GlassCard({
    super.key,
    required this.child,
    this.borderRadius = 24,
  });

  @override
  Widget build(BuildContext context) { ... }
}
```

**Private helper widgets:** Small, single-use widgets are defined as private classes at the bottom of the file rather than extracted to separate files — e.g., `_FieldLabel` in `sign_in_screen.dart`, `_Blob` and `_Product` in `splash_screen.dart`.

## Service Class Pattern

All service classes use **only static methods** — never instantiated:
```dart
class UserService {
  static const String baseUrl = 'https://mobile.ivend.cloud/api/v1';
  static String? _token;           // private static state

  static Future<bool> login(...) async { ... }
  static Future<UserData> fetch() async { ... }
}
```

Services in `lib/services/` follow this pattern: `UserService`, `TransactionsService`, `LocationsService`, `NotificationsService`, `PromotionsService`, `ApiService`.

## Model Class Pattern

Models are immutable data containers with `factory` constructors for JSON parsing:
```dart
class TransactionModel {
  final String id;
  // ... all fields final

  const TransactionModel({required this.id, ...});

  factory TransactionModel.fromJson(Map<String, dynamic> json) { ... }
  factory TransactionModel.fromOrderJson(Map<String, dynamic> json) { ... }  // backend-specific variant
  static List<TransactionModel> listFromJson(String source) { ... }
}
```

Multiple `factory` constructors are used when a model maps to different backend shapes (e.g., orders vs. ledger entries in `transaction_model.dart`).

`NotificationModel` deviates slightly — it is **mutable** (`isRead` has no `final`) because it is toggled in-place in the UI.

## State Management

- **Provider** (`^6.1.2`) used for the global `User` object
- `User extends ChangeNotifier` in `lib/models/user_model.dart`
- Global singleton: `final User currentUser = User();` defined at module level in `user_model.dart`
- Global list: `List<TransactionModel> mockTransactions = [];` defined at module level in `transaction_model.dart`
- Provider is wired in `main.dart` via `ChangeNotifierProvider.value(value: currentUser, ...)`
- Individual screens consume via `Provider.of<User>(context, listen: false)` for writes, `context.watch` pattern not present — screens trigger refreshes via `setState` after async fetches

## Error Handling Patterns

**Service methods:** Wrap entire body in `try/catch`, catch `Object e`, log with `debugPrint`, return a safe default (`false`, `[]`, `null`):
```dart
static Future<List<TransactionModel>> fetch() async {
  try {
    // ...
  } catch (e) {
    debugPrint('Transactions Fetch Error: $e');
  }
  return [];
}
```

**Screens (async actions):** Guard with `if (mounted)` before `setState` or `Navigator` calls after `await`:
```dart
Future<void> _signIn() async {
  setState(() => _loading = true);
  try {
    final success = await UserService.login(...);
    if (success) {
      if (mounted) { setState(() => _loading = false); Navigator.pushReplacementNamed(...); }
    }
  } catch (e) {
    if (mounted) { setState(() => _loading = false); ScaffoldMessenger.of(context).showSnackBar(...); }
  }
}
```

**One inconsistency:** `dashboard_screen.dart:72` uses bare `print('Fetch Error: $e')` instead of `debugPrint`. All other error logging uses `debugPrint`.

**Token expiry:** Handled transparently in `UserService.authGet` / `authPost` — auto-refresh on HTTP 401 before retrying.

## Logging

- Use `debugPrint(...)` for all debug/diagnostic output (strips in release builds)
- Pattern: `debugPrint('<ClassName> Error: $e')` or `debugPrint('<action> response: ${response.statusCode} ${response.body}')`
- One deviation: `print(...)` in `dashboard_screen.dart` — should be `debugPrint`

## Comments

**`///` doc comments:** Used on public-ish methods that need intent explanation — e.g., factory constructors, non-obvious service methods:
```dart
/// Parse a wallet ledger entry (CREDIT only — top-ups and refunds).
factory TransactionModel.fromBackendJson(Map<String, dynamic> json) { ... }

/// Fetch only the wallet balance (lighter call for post-payment refresh).
static Future<double?> fetchBalance() async { ... }
```

**`//` inline comments:** Used liberally for section markers inside long `build()` methods, using an em-dash separator style:
```dart
// ── Glass display area ───────────────────────────────────────────────────
// Background blobs
// Sign up
```

**Inline trailing comments:** Used for field semantics:
```dart
final String status; // PAID, COMPLETED, FAILED, REFUNDED, or empty for ledger entries
```

## Theme Usage

All colors, fonts, and text styles come from `lib/theme/app_theme.dart`:
- `AppColors.<name>` — never raw hex in screen files (hex is only in `app_theme.dart` and `splash_screen.dart`'s CustomPainter)
- `AppFonts.inter`, `AppFonts.outfit`, `AppFonts.montserrat` — constant font family strings
- `AppTheme.lightTheme` — single theme wired in `MaterialApp`
- Theme is Material 3 (`useMaterial3: true`) with custom `ColorScheme` seeded from `AppColors.orange`

## Navigation

Named routes only. All route strings defined in `main.dart`:
- `'/'` → `SplashScreen`
- `'/onboarding'` → `OnboardingScreen`
- `'/signin'`, `'/signup'`, `'/forgot-password'`
- `'/home'` → `HomeScreen`
- `'/transactions'` → `TransactionsScreen`

Navigation calls: `Navigator.pushReplacementNamed(context, '/route')` for auth transitions, `Navigator.pushNamed(context, '/route')` for forward navigation.

## Async Patterns

- `Future.wait([...])` for parallel API calls (used in `main.dart`, `dashboard_screen.dart`, `transactions_service.dart`)
- Results cast explicitly: `final userData = results[0] as UserData;`
- All service fetch methods are `static Future<T>` returning safe defaults on error

## Constants

- `baseUrl` is duplicated: defined in both `UserService` and `PromotionsService` (and `ApiService` references `UserService.authPost`). Centralisation is partial — `PromotionsService` makes raw `http.get` calls bypassing the auth-retry wrapper.

---

*Convention analysis: 2026-05-05*
