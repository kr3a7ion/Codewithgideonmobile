# CodeWithGideon

Flutter reconstruction of the original React/Vite mobile prototype in this repo.

## What Is Included

- `flutter_riverpod` for app and feature state
- `go_router` for navigation and the 4-tab shell
- A reusable design system that matches the original deep-blue, teal, and orange brand palette
- Rebuilt entry, dashboard, classes, live session, recorded lessons, assessments, community, and profile flows
- Native-ready package hooks for web handoff, file upload, sharing, motion, and typography

## Key Structure

```text
lib/src/
  app/                  App root and router
  core/
    data/               Mock conversion data based on the original prototype
    state/              Riverpod providers and controllers
    theme/              Colors, gradients, shadows, and typography
    widgets/            Shared controls, shell, and bottom navigation
  features/
    entry/
    home/
    classes/
    live/
    recorded/
    assessments/
    community/
    profile/
```

## Packages Added

- `flutter_riverpod`
- `go_router`
- `google_fonts`
- `flutter_animate`
- `gap`
- `intl`
- `smooth_page_indicator`
- `url_launcher`
- `share_plus`
- `file_picker`

## Run It

```bash
flutter pub get
flutter run
```

## Recommended Next Improvements

- Replace mock data with real repositories and API contracts.
- Move `TextEditingController` state out of a few overlay builds into dedicated controller widgets for tighter runtime behavior.
- Add golden tests for key screens to protect the conversion fidelity.
- Add native icons, splash assets, and final branding polish for Android and iOS release builds.
