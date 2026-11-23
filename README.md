# Digital Market for Green Vegetable Transactions

**Farm to Table — Digital Market**

**Students:** Fatuma Yusuphu Kidugo & Abinel Festo Kilufi  
**Institution:** Mbeya University of Science and Technology (MUST)

## Overview

Farm to Table is a digital marketplace that connects green vegetable farmers directly with traders and consumers in Tanzania. The platform removes intermediaries by allowing farmers to publish produce listings with stock, price, unit, location and photos, while buyers can browse or search the marketplace, manage a cart, place orders and track their status.

The system supports three roles:

- **Farmer** — manages products, availability and stock; receives and processes orders.
- **Trader / Consumer** — browses products, adds items to the cart, checks out and tracks orders.
- **Shared** — profile management, image uploads and Firebase Authentication-based sign-in/sign-up.

Core flows include unit-aware quantity handling (for example, 0.5 kg steps), transactional stock decrement at checkout, automatic stock return when an order is cancelled or rejected, and role/owner-aware Firestore and Storage security rules.

## Tech Stack

- **Flutter** — cross-platform UI (Material 3, web, Android)
- **Firebase Authentication** — email/password sign-up and login
- **Cloud Firestore** — real-time product, user and order data
- **Firebase Storage** — profile and product images
- **Firebase Emulator Suite** — local Auth, Firestore, Storage and Emulator UI
- **Provider** — application state management (`AuthProvider`, `CartProvider`)
- **Dart intl / uuid / cached_network_image / image_picker** — supporting utilities

## Prerequisites

- Flutter SDK (version compatible with `environment.sdk` and `flutter` in `pubspec.yaml`)
- Dart SDK (bundled with Flutter)
- Node.js and npm (for Firebase CLI)
- Firebase CLI: `npm install -g firebase-tools`
- A Chrome/Chromium browser for the web target

## Setup

### 1. Install dependencies

```bash
flutter pub get
```

### 2. Configure Firebase

Firebase options are already generated in `lib/firebase_options.dart`. The project configured for local development is `demo-farm-to-table` (see `.firebaserc`).

To use a different Firebase project, update `.firebaserc`, `firebase.json`, and the generated `lib/firebase_options.dart` for that project.

## Running the Web Version

### Development mode (with Firebase emulators)

In one terminal, start the emulators:

```bash
firebase emulators:start
```

Emulator endpoints used by the app:

| Service | Host | Port |
| --- | --- | --- |
| Authentication | `127.0.0.1` | `9099` |
| Firestore | `127.0.0.1` | `8080` |
| Storage | `127.0.0.1` | `9199` |
| Emulator UI | `127.0.0.1` | `4000` |

Open the Emulator UI at <http://127.0.0.1:4000>.

In a second terminal, run the app in debug mode:

```bash
flutter run -d chrome
```

Debug builds automatically connect to the emulators through `_configureEmulators()` in `lib/main.dart`. A release build does **not** use emulators and talks to the configured Firebase project instead.

### Production-style web build

```bash
flutter build web --release
```

The generated files are written to `build/web`.

## Running Tests

```bash
flutter test
```

Automated `flutter test` covers model serialization, cart and quantity logic, and reusable widgets. Emulator-based validation covers authenticated UI flows, checkout/stock return behaviour, and Storage Security Rules, including expected `403` denials for unauthorised uploads.

## Firebase Rules and Indexes

| File | Purpose |
| --- | --- |
| `firestore.rules` | Role- and ownership-based access control for users, products and orders |
| `storage.rules` | Owner/role checks plus image type and 5 MB size validation |
| `firestore.indexes.json` | Firestore composite indexes |
| `firebase.json` | Emulator ports and rules/index file locations |

## Project Structure

```text
lib/
  main.dart                 Firebase init, emulator config, app root
  firebase_options.dart      Generated Firebase configuration
  models/                    UserModel, ProductModel, OrderModel
  providers/                 AuthProvider, CartProvider
  routes/                    Route helpers
  screens/                   Auth, marketplace, buyer, farmer, order and profile UIs
  services/                  Auth/user/product/order/storage services
  utils/                     Constants and quantity helpers
  widgets/                   Shared UI components
web/                         Web shell, manifest and icons
test/                        Automated tests
```

## Authors

Fatuma Yusuphu Kidugo & Abinel Festo Kilufi  
Mbeya University of Science and Technology (MUST)
