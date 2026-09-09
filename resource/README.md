# Resource Source

This directory contains the editable runtime-resource source for CompBox. The
Flutter app loads the generated `assets/resource/config/resources.json`; do not
edit that file or its `manifest.json` by hand.

## Files

- `config/categories.yaml`: component categories, icons, their field lists, and
  category-level NFC value dictionaries.
- `config/fields.yaml`: field definitions, field-level NFC metadata, and
  dictionaries such as package, tolerance, connector type, and LED colour.
- `config/i18n.yaml`: every runtime label in Chinese (`zh`) and English (`en`).
- `icons/`: SVG icons referenced by categories. Keep the matching bundled files
  in `assets/resource/icons/` in sync when an icon changes.

## Editing Rules

- Labels and category names must use quoted `"@i18n.<key>"` references. These
  are logical references, not YAML anchors.
- Every referenced key must exist in `i18n.yaml`, and each translation must
  contain exactly non-empty `zh` and `en` values.
- Save all YAML text using Unicode NFC normalization.
- Category IDs, field IDs, NFC category codes, NFC field codes, and dictionary
  codes are compatibility data written to NFC tags. Do not renumber, reuse, or
  alter existing meanings after release; add new entries instead.
- Numeric category values declare their base `unit`, selectable `units`, and a
  `defaultUnitId`. Each selectable unit has a positive multiplier relative to
  the base unit; the base unit itself must use multiplier `1`. Unit selection
  is an input/display preference, while stored inventory and NFC values remain
  normalized to the base unit.
- Category icons must be relative SVG paths under this directory.

## Generate and Validate

Install the release-tool dependencies once, then rebuild the runtime package
after every resource change:

```sh
python3 -m pip install -r tools/requirements.txt
python3 tools/resource_sync.py prepare
python3 -m unittest tools/test_resource_sync.py
```

`prepare` validates references, translation languages, NFC Unicode, NFC codes,
dictionary constraints, category-field relationships, and writes only the
compact resource package plus release manifest. Use `--dry-run` to validate
without writing generated files.

```sh
python3 tools/resource_sync.py prepare --dry-run
```
