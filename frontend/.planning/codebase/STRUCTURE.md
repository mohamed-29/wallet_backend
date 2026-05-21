<!-- refreshed: 2026-05-05 -->
# Codebase Structure

**Analysis Date:** 2026-05-05

## Directory Layout

```
ivendapplication/
├── lib/                        # All Dart application source
│   ├── main.dart               # App entry point, route table, Provider setup
│   ├── models/                 # Data models and DTOs
│   │   ├── user_model.dart     # User ChangeNotifier + global currentUser
│   │   ├── transaction_model.dart  # TransactionModel + global mockTransactions
│   │   ├── vending_location.dart   # VendingLocation value object
│   │   └── notification_model.dart # NotificationModel (mutable isRead)
│   ├── services/               # Network and storage services (all static methods)
│   │   ├── user_service.dart   # Auth, token lifecycle, authenticated HTTP helpers
│   │   ├── api_service.dart    # QR payment endpoint
│   │   ├── transactions_service.dart  # Orders + wallet ledger merge
│   │   ├── locations_service.dart     # Machine locations fetch
│   │   ├── notifications_service.dart # Notifications fetch + mark-read
│   │   └── promotions_service.dart    # Promotions fetch
│   ├── screens/                # One file per screen
│   │   ├── splash_screen.dart       # Animated intro + routing gate
│   │   ├── onboarding_screen.dart   # First-run onboarding
│   │   ├── auth/
│   │   │   ├── sign_in_screen.dart
│   │   │   ├── sign_up_screen.dart
│   │   │   └── forgot_password_screen.dart
│   │   └── home/               # Post-auth screens (tab children + nav shell)
│   │       ├── home_screen.dart         # Bottom-nav IndexedStack shell
│   │       ├── dashboard_screen.dart    # Tab 0: wallet + recent activity
│   │       ├── qr_screen.dart           # Tab 1: camera QR scan + payment
│   │       ├── locations_screen.dart    # Tab 2: vending machine map/list
│   │       ├── help_screen.dart         # Tab 3: help/support
│   │       ├── profile_screen.dart      # Tab 4: user profile
│   │       ├── notifications_screen.dart # Pushed from dashboard bell icon
│   │       ├── edit_profile_screen.dart  # Pushed from profile screen
│   │       ├── top_up_screen.dart        # Pushed from balance card
│   │       └── transactions_screen.dart  # Named route /transactions
│   ├── theme/
│   │   └── app_theme.dart      # AppColors, AppFonts, AppTheme.lightTheme
│   └── widgets/
│       └── glass_card.dart     # GlassCard, GlassCardDark reusable widgets
├── assets/
│   ├── fonts/                  # Inter, Outfit, Montserrat variable TTFs
│   └── data/                   # (empty — previously used for static JSON fixtures)
├── android/                    # Android platform project
├── ios/                        # iOS platform project
├── pubspec.yaml                # Dependencies and asset declarations
├── pubspec.lock                # Locked dependency versions
├── analysis_options.yaml       # Dart linting config (flutter_lints)
└── .planning/
    └── codebase/               # GSD planning documents
```

## Directory Purposes

**`lib/models/`:**
- Purpose: Data structures used across the app
- Contains: One `ChangeNotifier` (`User`), immutable value objects, one mutable notification object
- Key files: `user_model.dart` (global `currentUser`), `transaction_model.dart` (global `mockTransactions`)
- Note: `user_model.dart` imports `user_service.dart` for the `UserData` DTO type

**`lib/services/`:**
- Purpose: All I/O — REST API calls and secure token storage
- Contains: Static-method-only classes; no instantiation needed
- Key files: `user_service.dart` (auth hub, `authGet`/`authPost` helpers used by other services)
- Note: `PromotionsService` duplicates `baseUrl` and rolls its own auth header; all others delegate to `UserService`

**`lib/screens/auth/`:**
- Purpose: Unauthenticated flows
- Contains: Sign in, sign up, forgot password
- Accessed via: Named routes `/signin`, `/signup`, `/forgot-password`

**`lib/screens/home/`:**
- Purpose: All authenticated screens
- Contains: The bottom-nav shell (`home_screen.dart`) and all its tab children, plus screens pushed modally (notifications, edit profile, top-up)
- Note: `transactions_screen.dart` is accessed via named route `/transactions`, not a tab

**`lib/widgets/`:**
- Purpose: Shared UI building blocks
- Contains: Only `glass_card.dart` currently — `GlassCard` (light glassmorphism) and `GlassCardDark` (dark glassmorphism)

**`lib/theme/`:**
- Purpose: Central design token registry
- Contains: `AppColors` (all hex values), `AppFonts` (font family name constants), `AppTheme.lightTheme` (complete Material 3 theme)
- Key constants: `AppColors.orange` (`0xFFF47B20`), `AppColors.navy` (`0xFF1F2937`)

**`assets/fonts/`:**
- Purpose: Bundled variable font files
- Contains: Inter (primary UI font), Outfit (brand logo), Montserrat (tagline/accent)
- Note: All are variable fonts registered in `pubspec.yaml`

## Key File Locations

**Entry Points:**
- `lib/main.dart`: App bootstrap, `main()`, `IvendApp`, route map
- `lib/screens/splash_screen.dart`: First screen shown (`/` route); decides `/onboarding`, `/signin`, or `/home`

**Route Table (defined in `lib/main.dart:66-74`):**
- `/` → `SplashScreen`
- `/onboarding` → `OnboardingScreen`
- `/signin` → `SignInScreen`
- `/signup` → `SignUpScreen`
- `/forgot-password` → `ForgotPasswordScreen`
- `/home` → `HomeScreen` (bottom-nav shell)
- `/transactions` → `TransactionsScreen`
- Screens not in route table (pushed via `Navigator.push`): `NotificationsScreen`, `EditProfileScreen`, `TopUpScreen`

**Configuration:**
- `pubspec.yaml`: Flutter SDK constraint (`^3.5.0`), all dependencies, font asset declarations
- `analysis_options.yaml`: Linting (extends `flutter_lints`)
- `devtools_options.yaml`: Flutter DevTools config

**Core Logic:**
- `lib/services/user_service.dart`: JWT auth, token refresh, `authGet`/`authPost`
- `lib/models/user_model.dart`: `User` ChangeNotifier (wallet balance, name, phone, points)

**Shared Design:**
- `lib/theme/app_theme.dart`: Import this for any color, font, or theme reference

## Naming Conventions

**Files:**
- `snake_case` for all Dart files: `dashboard_screen.dart`, `user_service.dart`, `glass_card.dart`
- Screen files suffixed `_screen.dart`
- Service files suffixed `_service.dart`
- Model files suffixed `_model.dart` (except `vending_location.dart`)

**Directories:**
- `snake_case` for all directories: `screens/`, `home/`, `auth/`

**Classes:**
- `PascalCase`: `DashboardScreen`, `UserService`, `TransactionModel`
- Private widget helpers inside screen files: prefixed with `_`: `_DashboardHeader`, `_BalanceCard`, `_QuickStatCard`
- Private state classes: `_DashboardScreenState`, `_QrScreenState`

**Enums:**
- `PascalCase` name, `camelCase` values: `TransactionType.purchase`, `_ScanState.scanning`

## Where to Add New Code

**New screen (authenticated, tab):**
- Implementation: `lib/screens/home/your_screen.dart`
- Register in `HomeScreen._HomeScreenState` `IndexedStack` children: `lib/screens/home/home_screen.dart`
- Add nav item to `HomeScreen` `bottomNavigationBar` row

**New screen (authenticated, pushed modally):**
- Implementation: `lib/screens/home/your_screen.dart`
- Push via `Navigator.push(context, MaterialPageRoute(builder: (_) => const YourScreen()))`
- Only add to route table in `lib/main.dart` if deep-linking is needed

**New screen (unauthenticated):**
- Implementation: `lib/screens/auth/your_screen.dart`
- Add named route to `lib/main.dart:66-74`

**New service:**
- Implementation: `lib/services/your_service.dart`
- Use `UserService.authGet` / `UserService.authPost` for authenticated requests
- Do NOT redeclare `baseUrl` — call the `UserService` helpers

**New model / data type:**
- Simple value object: `lib/models/your_model.dart`
- Reactive state: Extend `User` (`lib/models/user_model.dart`) or add a new `ChangeNotifier` and register it in `main.dart`

**Shared UI widget:**
- Implementation: `lib/widgets/your_widget.dart`
- Follow `GlassCard` pattern: pure `StatelessWidget`, no service calls

**New color or font constant:**
- Add to `AppColors` or `AppFonts` in `lib/theme/app_theme.dart`

## Special Directories

**`.planning/codebase/`:**
- Purpose: GSD planning documents (ARCHITECTURE.md, STRUCTURE.md, etc.)
- Generated: By GSD map-codebase agent
- Committed: Yes (tracked in git)

**`assets/data/`:**
- Purpose: Was used for static JSON fixture files; currently empty
- Generated: No
- Committed: Yes (directory tracked)

**`android/` and `ios/`:**
- Purpose: Native platform projects; modified only for plugin registration, permissions, and app config
- Key files: `android/app/src/main/AndroidManifest.xml` (permissions for camera, location), `ios/Runner/Info.plist`
- Generated: Partially (Gradle/CocoaPods files auto-generated); app-level config is hand-edited

**`build/`:**
- Purpose: Flutter build output
- Generated: Yes
- Committed: No (in `.gitignore`)

---

*Structure analysis: 2026-05-05*
