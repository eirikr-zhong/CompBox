# CompBox

CompBox is an Android-first Flutter app for organizing electronic components in
physical storage boxes. It keeps a searchable local inventory and uses NFC tags
as compact, offline snapshots of each box's compartments.

## Features

- Search and filter components by category, location, and recorded attributes.
- Initialize, read, edit, clear, and rewrite multi-compartment NFC tags.
- Store the scanned inventory locally in SQLite without a cloud dependency.
- Export and import the complete local inventory as a backup file.
- Use a bilingual English and Chinese component catalog generated from YAML.
- Validate compact NFC payloads with versioning and CRC-16/CCITT checksums.

## Requirements

- Flutter with a Dart SDK compatible with `^3.13.0`.
- Android SDK and an Android device or emulator.
- An NFC-capable Android device and writable NDEF tags for NFC workflows.

## Run locally

```sh
flutter pub get
flutter run -d <device-id>
```

The generated resource bundle is committed to the repository, so it is not
necessary to rebuild resources before the first run.

## Validation

```sh
python3 -m unittest tools/test_resource_sync.py
flutter test
flutter analyze
```

## GitHub releases

The repository includes a tag-triggered workflow that validates the project,
builds a signed Android APK, generates a SHA-256 checksum, and attaches both
files to a GitHub Release. The signing keystore and properties file stay out of
Git and are restored from encrypted GitHub Actions secrets during the build.

See [`docs/releasing.md`](docs/releasing.md) for signing setup, release commands,
key backup requirements, and the difference between GitHub and Google Play
distribution.

## Project layout

- `lib/main.dart` contains the current application UI and page state.
- `lib/data/` contains local persistence, backups, NFC snapshots, and resources.
- `resource/` contains the editable component catalog and its source icons.
- `assets/resource/` contains the generated runtime resource package.
- `test/` contains widget and data-layer tests.
- `tools/` contains the resource validation and publishing utilities.

## Resources

`resource/config/categories.yaml`, `fields.yaml`, and `i18n.yaml` are the
manually maintained source for component categories, field definitions, and
translated resource text. Display text is always an `@i18n.<key>` reference;
this is a logical resource reference, not a YAML anchor. Do not edit the
generated configuration in `assets/resource/` directly. Generate the compact
runtime package and its manifest from the YAML sources instead:

```sh
python3 -m pip install -r tools/requirements.txt
python3 tools/resource_sync.py prepare
```

The app loads only `assets/resource/config/resources.json`. The generated
`lib/data/resource_models.g.dart` is version-controlled; regenerate it after
changing `lib/data/resource_models.dart`:

```sh
dart run build_runner build
```

The Flutter app reads only the generated, bundled assets and does not contact
R2. To publish a prepared release for a future client updater, install
`tools/requirements.txt`, set `R2_ENDPOINT_URL`, `R2_ACCESS_KEY_ID`,
`R2_SECRET_ACCESS_KEY`, and `R2_BUCKET`, then run:

```sh
python3 tools/resource_sync.py publish
```

The publisher uploads immutable files to `releases/<sha256>/` and updates
`asset.json` last as the release pointer. Use `--dry-run` with either command
to validate the operation without writing files or uploading objects.

## NFC snapshots

CompBox writes one short, `TNF unknown` NDEF record per tag. The payload is a
compact binary snapshot with CRC-16/CCITT; it never stores JSON, Base64, or a
general-purpose compressed document on a tag. The physical tag is the offline
source of truth and SQLite holds the local scanned copy.

`resource/config/categories.yaml` owns each component type's stable NFC code,
secondary field, and common nominal-value dictionary. `fields.yaml` owns field
codes plus dictionaries for package, tolerance, connector type, and LED colour;
`i18n.yaml` owns their Chinese and English text. A dictionary match is stored as
its numeric index. An unmatched value is stored as a field-tagged UTF-8 fallback
attribute so it remains readable.

Treat every existing NFC code and dictionary index as immutable after it is
released: add new codes instead of renumbering or reusing old ones. Run
`python3 tools/resource_sync.py prepare` after changing `resource/`; its
validation rejects duplicate codes, malformed dictionary entries, and invalid
category-field role references.
