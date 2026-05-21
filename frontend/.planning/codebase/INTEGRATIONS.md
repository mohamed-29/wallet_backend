# External Integrations

**Analysis Date:** 2026-05-05

## APIs & External Services

**ivend Backend API (primary):**
- Base URL: `https://mobile.ivend.cloud/api/v1`
- Protocol: REST, JSON over HTTPS
- Auth: JWT Bearer token (`Authorization: Bearer <token>`)
- Client: Dart `http` package (`lib/services/user_service.dart`, `lib/services/promotions_service.dart`)
- Token refresh: automatic on 401 using `/auth/token/refresh/` (`lib/services/user_service.dart:refreshAccessToken`)

**Endpoints consumed:**

| Endpoint | Method | Service file | Purpose |
|----------|--------|--------------|---------|
| `/auth/login/` | POST | `lib/services/user_service.dart` | Phone + password login, returns access + refresh JWT |
| `/auth/register/` | POST | `lib/services/user_service.dart` | New user registration |
| `/auth/token/refresh/` | POST | `lib/services/user_service.dart` | Silent JWT refresh |
| `/users/` | GET | `lib/services/user_service.dart` | Fetch user profile (first element of list) |
| `/wallet/balance/` | GET | `lib/services/user_service.dart` | Wallet balance in cents |
| `/wallet/history/` | GET | `lib/services/transactions_service.dart` | Ledger entries (CREDIT only used) |
| `/payment/my-orders/` | GET | `lib/services/transactions_service.dart` | Purchase order history |
| `/payment/pay-qr/` | POST | `lib/services/api_service.dart` | Trigger vending machine dispense via scanned QR |
| `/machine-locations/` | GET | `lib/services/locations_service.dart` | All vending machine locations with lat/lng |
| `/notifications/` | GET | `lib/services/notifications_service.dart` | User notification list |
| `/notifications/{id}/mark_read/` | POST | `lib/services/notifications_service.dart` | Mark notification as read |
| `/promotions/` | GET | `lib/services/promotions_service.dart` | Active promotion codes |

## Data Storage

**Databases:**
- None — no local database (SQLite, Hive, etc.) detected
- All persistent data is fetched from the remote backend API

**Secure Token Storage:**
- `flutter_secure_storage` `9.2.4`
- Keys stored: `auth_token` (JWT access), `refresh_token` (JWT refresh), `is_first_time` (onboarding flag)
- Implementation: `lib/services/user_service.dart` (`_storage` static instance)
- Platform backends: Keychain (iOS/macOS), Keystore (Android), libsecret (Linux), DPAPI (Windows)

**File Storage:**
- Local filesystem: not used
- Bundled assets: fonts only (`assets/fonts/`)

**Caching:**
- None — no caching layer detected. Data is held in Dart variables and global state during the app session only

## Authentication & Identity

**Auth Provider:**
- Custom backend (`https://mobile.ivend.cloud/api/v1/auth/`)
- Credentials: phone number + password
- Token scheme: JWT access + refresh tokens
- Token storage: `flutter_secure_storage` (device secure enclave)
- Session behaviour: access token auto-refreshed on 401; full logout clears both tokens

## Device & Hardware Integrations

**Camera / QR Scanning:**
- `mobile_scanner` `7.2.0`
- Used in: `lib/screens/home/qr_screen.dart`
- Scans ivend proprietary QR format: `ivend://pay?machine=&slot=&price=&order_id=`
- Torch/flashlight control via `MobileScannerController`

**Geolocation:**
- `geolocator` `13.0.4`
- Used in: `lib/screens/home/locations_screen.dart`
- Purpose: calculate distances to vending machines using Haversine formula
- Permissions: runtime location permission requested

## Third-Party Deep Links / URL Launch

**WhatsApp Support:**
- URL pattern: `https://wa.me/<phoneNumber>`
- Used in: `lib/screens/home/help_screen.dart`
- Package: `url_launcher`

**Google Maps:**
- URL pattern: `https://www.google.com/maps/search/?api=1&query=<lat>,<lng>&query_place_id=<name>`
- Used in: `lib/screens/home/locations_screen.dart`
- Package: `url_launcher`
- Opens native Maps app or browser — no Maps SDK embedded

## Monitoring & Observability

**Error Tracking:**
- None — no Sentry, Firebase Crashlytics, or similar SDK detected

**Logs:**
- `debugPrint()` calls throughout service files (stripped from release builds by Flutter)
- No structured logging or remote log shipping

## CI/CD & Deployment

**Hosting (backend):**
- `mobile.ivend.cloud` — backend domain (no infrastructure config in this repo)

**CI Pipeline:**
- None detected — no `.github/workflows/`, `.gitlab-ci.yml`, `Fastfile`, or similar in repository

**App signing:**
- Android: currently using debug signing for release builds (`android/app/build.gradle.kts`)
- iOS: Xcode managed (standard Flutter setup)

## Environment Configuration

**Required secrets/env vars:**
- No `.env` files detected in the repository
- API base URL is hardcoded as a constant in three files:
  - `lib/services/user_service.dart` → `static const String baseUrl = 'https://mobile.ivend.cloud/api/v1'`
  - `lib/services/api_service.dart` → same constant
  - `lib/services/promotions_service.dart` → same constant

**No injection mechanism** for environment-specific configuration (dev/staging/prod) is currently implemented.

## Webhooks & Callbacks

**Incoming webhooks:**
- None detected

**Outgoing webhooks:**
- None detected

---

*Integration audit: 2026-05-05*
