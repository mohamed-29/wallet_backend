# Technology Stack

**Analysis Date:** 2026-05-05

## Languages

**Primary:**
- Dart 3.5+ — all application logic, UI, and services (`lib/`)

**Secondary:**
- Kotlin — Android platform layer (`android/app/`)
- Swift 5.0 — iOS platform layer (`ios/`)

## Runtime

**Environment:**
- Flutter SDK (Dart SDK constraint: `^3.5.0` per `pubspec.yaml`)

**Package Manager:**
- pub (Flutter/Dart's built-in package manager)
- Lockfile: `pubspec.lock` (present, committed)

## Frameworks

**Core:**
- Flutter (Material Design) — cross-platform mobile UI framework
  - `uses-material-design: true` in `pubspec.yaml`
  - Locked to portrait orientation (`DeviceOrientation.portraitUp`, `portraitDown`)

**State Management:**
- provider `^6.1.2` (locked: `6.1.2`) — `ChangeNotifierProvider` wrapping a global `User` model in `lib/main.dart`

**Testing:**
- flutter_test (Flutter SDK built-in) — unit and widget testing
- No test files detected in `lib/` or a `test/` directory

**Build/Dev:**
- Flutter Gradle Plugin — Android build via `android/app/build.gradle.kts`
- Kotlin Android Gradle Plugin — `android/app/build.gradle.kts`

## Key Dependencies

| Package | Version (pubspec.yaml) | Resolved (lock) | Purpose |
|---------|------------------------|-----------------|---------|
| `http` | `^1.1.0` | `1.6.0` | REST API calls to ivend backend |
| `flutter_secure_storage` | `^9.0.0` | `9.2.4` | Encrypted storage for JWT tokens |
| `mobile_scanner` | `^7.0.0` | `7.2.0` | Camera-based QR code scanning |
| `qr_flutter` | `^4.1.0` | (transitive, unused in code) | QR image generation (declared but no imports found) |
| `geolocator` | `^13.0.2` | `13.0.4` | Device GPS for nearby machine distances |
| `url_launcher` | `^6.3.0` | (locked via transitive) | Opening WhatsApp support links and Google Maps URLs |
| `provider` | `^6.1.2` | `6.1.2` | App-wide state management |

## Dev Dependencies

| Package | Version | Purpose |
|---------|---------|---------|
| `flutter_lints` | `^4.0.0` (locked: `4.0.0`) | Flutter-recommended lint rules |
| `flutter_test` | Flutter SDK | Testing framework |

## Configuration

**Lint:**
- `analysis_options.yaml` — extends `package:flutter_lints/flutter.yaml`

**Build (Android):**
- `android/app/build.gradle.kts` — namespace `com.example.ivendapplication`
- `compileSdk`, `minSdk`, `targetSdk` delegated to Flutter Gradle plugin defaults
- Java 17 / Kotlin JVM target 17
- Release builds currently use debug signing keys (not production-ready)

**Build (iOS):**
- Deployment target: iOS 13.0
- Bundle ID: `com.example.ivendapplication`
- Swift 5.0

## Custom Assets

**Fonts (bundled in `assets/fonts/`):**
- Inter (variable — regular + italic)
- Outfit (variable)
- Montserrat (variable — regular + italic)

## Platform Requirements

**Development:**
- Flutter SDK >= 3.5.0
- Dart SDK >= 3.5.0 (bundled with Flutter)
- Android: Java 17, Kotlin, Android SDK
- iOS: Xcode, Swift 5.0

**Production:**
- Android: minSdk from Flutter plugin defaults (typically API 21+)
- iOS 13.0+
- Targets: Android and iOS (web/Linux/macOS/Windows directories scaffolded but not actively used)

---

*Stack analysis: 2026-05-05*
