# Code with Gideon — Mobile

Flutter client for [Code with Gideon](https://codewithgideon.com), a coding education platform: course catalog, cohort-based classes, live and recorded sessions, assessments, mentor requests, community spaces, and Paystack payments.

---

## Screenshots

<!-- Add 4-5 device screenshots to docs/ and reference them here.
     Dashboard, class list, recorded player, and payment flow are the ones worth showing. -->

| Dashboard | Classes | Recorded player |
|---|---|---|
| ![Dashboard](docs/dashboard.png) | ![Classes](docs/classes.png) | ![Player](docs/player.png) |

---

## Architecture

Feature-first. Each feature owns its data, models, state and presentation, so a feature can be read — or removed — without tracing threads through a shared layer.

```
lib/src/
├── app/                    App root, go_router configuration, 4-tab shell
├── core/
│   ├── config/             Payment configuration
│   ├── network/            API client, typed exceptions, connectivity provider
│   ├── services/           Notifications, playback security
│   ├── state/              App-wide Riverpod providers, settings
│   ├── theme/              Colors, gradients, typography
│   └── widgets/            Shared scaffold, controls, bottom nav, state widgets
└── features/
    ├── entry/              Onboarding, auth
    ├── home/               Student dashboard
    ├── catalog/            Courses and learning paths
    ├── classes/            Class listing, filters, live sessions
    ├── cohorts/            Cohort membership, sessions, messages
    ├── recorded/           Recorded lesson playback
    ├── community/          Community spaces, mentor requests
    ├── payment/            Paystack checkout
    ├── student/            Profile, pending payments
    ├── profile/            Account and settings
    └── resources/          Downloadable resources
```

**State:** Riverpod 3 throughout — no `setState` for anything crossing a widget boundary.
**Navigation:** go_router, declarative routes with a persistent shell.
**Data:** repository classes per feature, so screens never touch Firestore or HTTP directly.

---

## Stack

| Concern | Package |
|---|---|
| State | flutter_riverpod 3 |
| Routing | go_router |
| Backend | firebase_core, firebase_auth, cloud_firestore, cloud_functions |
| Payments | flutter_paystack_plus |
| Video | youtube_player_flutter + a native playback-security channel |
| Chat | flutter_chat_ui, flutter_chat_types |
| Notifications | flutter_local_notifications |
| Connectivity | connectivity_plus |
| Local storage | shared_preferences |
| UI | google_fonts, flutter_svg, phosphor_flutter, flutter_animate |

---

## Engineering notes

**Native playback hardening.** Paid course video needs some protection against casual screen capture, and Flutter has no cross-platform API for it. `PlaybackSecurityService` sits on a `MethodChannel` with implementations on both sides — Kotlin in `MainActivity.kt`, Swift in `AppDelegate.swift` — toggled around the player lifecycle. Platform exceptions are swallowed deliberately: it's best-effort hardening, and an unsupported platform should degrade rather than crash.

**Payments through Cloud Functions.** Paystack initialization goes server-side rather than embedding secret keys in the client. The app receives a checkout reference and verifies against the backend.

**Repositories over direct calls.** Every feature reaches data through a repository. That kept the swap from seeded demo data to live Firestore a per-feature change rather than a rewrite — which is exactly what's happening now (see Status).

**Typed error surface.** `ApiException` plus shared state widgets, so loading, empty and error states are consistent across screens instead of reinvented per view.

---

## Status

In active development. The UI is complete across all flows. Backend integration is landing feature by feature: catalog, cohorts, community and payments run against Firestore and Cloud Functions, while the remaining repositories still resolve against seeded demo data through `ApiClient.simulateRequest` until their endpoints are finished.

The app began as a React/Vite prototype used to settle the design, then was rebuilt in Flutter as the production client. Early commits reflect that origin.

---

## Running it

```bash
cd codewithgideon
flutter pub get
flutter run
```

Firebase configuration is not committed. To run against a live backend, add your own `google-services.json` (Android) and `GoogleService-Info.plist` (iOS), and set the Paystack public key in `lib/src/core/config/payment_config.dart`.

```bash
flutter test          # widget and screen smoke tests
```

---

## About

Built by **Gideon** ([@kr3a7ion](https://github.com/kr3a7ion)) — Flutter developer, Abuja, Nigeria.

Open to remote roles and relocation with visa sponsorship. [codewithgideon.com](https://codewithgideon.com)
