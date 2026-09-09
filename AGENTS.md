# Repository Guidelines

## Project Structure & Module Organization

This is a compact Flutter inventory prototype. Application UI, demo models, and
page state currently live in `lib/main.dart`. Localized source strings are in
`lib/l10n/app_en.arb` and `lib/l10n/app_zh.arb`; generated localization classes
also live in `lib/l10n/`. Widget tests belong in `test/`, currently
`test/widget_test.dart`. The Android host project is under `android/`; change it
only for platform-specific behavior, manifest configuration, or Gradle setup.

Keep feature changes close to their UI and state. Split `main.dart` only when a
feature becomes independently reusable or difficult to navigate. Do not add
runtime assets for design-reference images unless the product needs them.

## Build, Test, and Development Commands

- `flutter pub get` resolves project dependencies.
- `flutter run -d <device-id>` builds and launches the app on a selected device.
- `flutter test` runs all widget tests.
- `flutter analyze` applies the configured Flutter lints.
- `dart format lib test` formats Dart sources before review.
- `flutter gen-l10n` regenerates localization classes after editing an ARB file.
- `python3 tools/resource_sync.py prepare` validates YAML resources and builds
  `assets/resource/config/resources.json` plus its manifest.
- `dart run build_runner build` regenerates `*.g.dart` files after changing a
  `json_serializable` model.

Run analysis and tests before handing off a change. Build artifacts under
`build/` are generated and should not be edited.

## Resource Configuration

`resource/config/categories.yaml`, `fields.yaml`, and `i18n.yaml` are the
editable runtime-resource source. Read `resource/README.md` before changing
them. All resource display text must be an `@i18n.<key>` reference resolved by
`i18n.yaml`; it is not a YAML anchor. Keep YAML text NFC-normalized and provide
exactly `zh` and `en` for every translation.

NFC category codes, field codes, and dictionary codes are persisted on physical
tags. Never renumber, reuse, or change their meaning in a released resource;
add a new code instead. Do not hand-edit generated
`assets/resource/config/resources.json`, `assets/resource/manifest.json`, or
`lib/data/resource_models.g.dart`.

After changing YAML resources, run `python3 tools/resource_sync.py prepare`,
`python3 -m unittest tools/test_resource_sync.py`, `flutter test`, and
`flutter analyze`. After changing `lib/data/resource_models.dart`, run
`dart run build_runner build` and include the generated `*.g.dart` file.

## Coding Style & Naming Conventions

Use Dart's standard two-space indentation and let `dart format` decide wrapping.
Use `PascalCase` for types, `camelCase` for members, and leading underscores for
library-private widgets and helpers. Prefer `const` widgets where possible.
Use stable, descriptive widget keys for controls exercised by tests, for example
`Key('nfc-save-button')`. Follow the existing Material 3 color and spacing
patterns rather than introducing a second design system.

## Localization and Testing

Add every application UI string to both ARB files, then run `flutter gen-l10n`.
Runtime resource labels belong in `resource/config/i18n.yaml`. Do not manually
edit `app_localizations*.dart`, as generation overwrites it.

Write `testWidgets` tests for new interactions. Use descriptive test names,
exercise behavior through keys or visible text, and cover both initial and
changed state. NFC flows should remain local-only: tests must not require NFC
hardware, persistence, or the demo inventory to change.

## Commits and Pull Requests

Recent commits use short, imperative summaries such as `Compact home inventory
layout`. Keep commits focused and describe the user-visible change. Pull
requests should explain behavior, list validation commands, link relevant
issues, and include screenshots for visual or Android-facing changes. Mention
localization or generated-file updates explicitly.
