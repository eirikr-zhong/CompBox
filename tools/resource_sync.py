#!/usr/bin/env python3
"""Validate, package, and publish CompBox resource configurations."""

from __future__ import annotations

import argparse
import hashlib
import json
import os
import re
import sys
import tempfile
import unicodedata
from pathlib import Path
from typing import Any, Iterable, Mapping, Optional

try:
    import yaml
except ImportError as error:  # pragma: no cover - exercised by CLI environments
    raise RuntimeError("resource_sync requires PyYAML; install tools/requirements.txt") from error


RESOURCE_ROOT = Path("resource")
ASSET_ROOT = Path("assets/resource")
RESOURCE_JSON_PATH = Path("config/resources.json")
MANIFEST_PATH = Path("manifest.json")
SUPPORTED_LANGUAGES = {"zh", "en"}
SUPPORTED_FIELD_TYPES = {"text", "integer", "decimal", "enum"}
SUPPORTED_VALUE_TYPES = {"resistance", "capacitance", "inductance", "percentage"}
SUPPORTED_NFC_ROLES = {"value", "tolerance", "secondary", "text"}
I18N_REFERENCE = re.compile(r"^@i18n\.([A-Za-z0-9][A-Za-z0-9._-]*)$")
LATEST_RELEASE_KEY = "asset.json"


class ResourceValidationError(ValueError):
    pass


def _read_yaml(path: Path) -> Mapping[str, Any]:
    try:
        parsed = yaml.safe_load(path.read_text(encoding="utf-8"))
    except yaml.YAMLError as error:
        raise ResourceValidationError(f"Invalid YAML in {path}: {error}") from error
    if not isinstance(parsed, dict):
        raise ResourceValidationError(f"{path} must contain a YAML object")
    _validate_nfc(parsed, str(path))
    return parsed


def _validate_nfc(value: Any, description: str) -> None:
    if isinstance(value, str):
        if unicodedata.normalize("NFC", value) != value:
            raise ResourceValidationError(f"{description} must use NFC Unicode normalization")
    elif isinstance(value, Mapping):
        for key, child in value.items():
            _validate_nfc(key, f"{description} key")
            _validate_nfc(child, f"{description}.{key}")
    elif isinstance(value, list):
        for index, child in enumerate(value):
            _validate_nfc(child, f"{description}[{index}]")


def _require_string(value: Any, description: str) -> str:
    if not isinstance(value, str) or not value.strip():
        raise ResourceValidationError(f"{description} must be a non-empty string")
    return value


def _validate_translations(document: Mapping[str, Any]) -> Mapping[str, Mapping[str, str]]:
    translations = document.get("translations")
    if not isinstance(translations, dict) or not translations:
        raise ResourceValidationError("translations must be a non-empty object")
    result: dict[str, Mapping[str, str]] = {}
    for key, value in translations.items():
        translation_key = _require_string(key, "translation key")
        if not isinstance(value, dict):
            raise ResourceValidationError(f"translation {translation_key} must be an object")
        languages = set(value)
        missing = SUPPORTED_LANGUAGES - languages
        unsupported = languages - SUPPORTED_LANGUAGES
        if missing:
            raise ResourceValidationError(
                f"translation {translation_key} is missing languages: {sorted(missing)}"
            )
        if unsupported:
            raise ResourceValidationError(
                f"translation {translation_key} has unsupported languages: {sorted(unsupported)}"
            )
        result[translation_key] = {
            language: _require_string(value.get(language), f"translation {translation_key}.{language}")
            for language in sorted(SUPPORTED_LANGUAGES)
        }
    return result


def _validate_i18n_reference(
    value: Any, description: str, translations: Mapping[str, Mapping[str, str]]
) -> str:
    reference = _require_string(value, description)
    match = I18N_REFERENCE.fullmatch(reference)
    if match is None:
        raise ResourceValidationError(f"{description} must be an @i18n.<key> reference")
    key = match.group(1)
    if key not in translations:
        raise ResourceValidationError(f"{description} references missing translation: {key}")
    return reference


def _relative_resource_path(value: Any, description: str) -> Path:
    path_text = _require_string(value, description)
    path = Path(path_text)
    if path.is_absolute() or ".." in path.parts:
        raise ResourceValidationError(f"{description} must be relative to resource/")
    return path


def _nfc_code(value: Any, description: str, maximum: int = 255) -> int:
    if not isinstance(value, int) or isinstance(value, bool) or not 1 <= value <= maximum:
        raise ResourceValidationError(
            f"{description} must be an integer from 1 through {maximum}"
        )
    return value


def _validate_nfc_dictionary(
    value: Any,
    description: str,
    translations: Mapping[str, Mapping[str, str]],
) -> None:
    if value is None:
        return
    if not isinstance(value, list):
        raise ResourceValidationError(f"{description} must be a list")
    ids: set[str] = set()
    codes: set[int] = set()
    for entry in value:
        if not isinstance(entry, dict):
            raise ResourceValidationError(f"{description} entries must be objects")
        entry_id = _require_string(entry.get("id"), f"{description}.id")
        if entry_id in ids:
            raise ResourceValidationError(f"{description} has duplicate id: {entry_id}")
        ids.add(entry_id)
        code = _nfc_code(entry.get("code"), f"{description}.{entry_id}.code")
        if code in codes:
            raise ResourceValidationError(f"{description} has duplicate code: {code}")
        codes.add(code)
        _validate_i18n_reference(entry.get("label"), f"{description}.{entry_id}.label", translations)


def _validate_value_type(value: Any, description: str) -> str:
    value_type = _require_string(value, description)
    if value_type not in SUPPORTED_VALUE_TYPES:
        raise ResourceValidationError(
            f"{description} must be one of {sorted(SUPPORTED_VALUE_TYPES)}"
        )
    return value_type


def _validate_preset_series(
    value: Any,
    description: str,
    translations: Mapping[str, Mapping[str, str]],
) -> None:
    if value is None:
        return
    if not isinstance(value, list):
        raise ResourceValidationError(f"{description} must be a list")
    ids: set[str] = set()
    for entry in value:
        if not isinstance(entry, dict):
            raise ResourceValidationError(f"{description} entries must be objects")
        entry_id = _require_string(entry.get("id"), f"{description}.id")
        if entry_id in ids:
            raise ResourceValidationError(f"{description} has duplicate id: {entry_id}")
        ids.add(entry_id)
        _validate_i18n_reference(entry.get("label"), f"{description}.{entry_id}.label", translations)
        values = entry.get("values")
        if not isinstance(values, list) or not values or any(
            not isinstance(item, (int, float)) or isinstance(item, bool) or item <= 0
            for item in values
        ):
            raise ResourceValidationError(f"{description}.{entry_id}.values must be positive numbers")
        if values != sorted(values) or len(values) != len(set(values)):
            raise ResourceValidationError(f"{description}.{entry_id}.values must be sorted and unique")
        min_exponent = entry.get("minExponent")
        max_exponent = entry.get("maxExponent")
        if not isinstance(min_exponent, int) or not isinstance(max_exponent, int) or min_exponent > max_exponent:
            raise ResourceValidationError(f"{description}.{entry_id} has invalid exponent limits")
        maximum = entry.get("maximum")
        if not isinstance(maximum, (int, float)) or isinstance(maximum, bool) or maximum <= 0:
            raise ResourceValidationError(f"{description}.{entry_id}.maximum must be positive")


def _validate_value_units(
    value: Any,
    description: str,
    translations: Mapping[str, Mapping[str, str]],
    base_unit_id: str,
    default_unit_id: str,
) -> None:
    if not isinstance(value, list) or not value:
        raise ResourceValidationError(f"{description} must be a non-empty list")
    ids: set[str] = set()
    multipliers: set[float] = set()
    base_multiplier: float | None = None
    for entry in value:
        if not isinstance(entry, dict):
            raise ResourceValidationError(f"{description} entries must be objects")
        entry_id = _require_string(entry.get("id"), f"{description}.id")
        if entry_id in ids:
            raise ResourceValidationError(f"{description} has duplicate id: {entry_id}")
        ids.add(entry_id)
        _require_string(entry.get("symbol"), f"{description}.{entry_id}.symbol")
        multiplier = entry.get("multiplier")
        if (
            not isinstance(multiplier, (int, float))
            or isinstance(multiplier, bool)
            or multiplier <= 0
        ):
            raise ResourceValidationError(
                f"{description}.{entry_id}.multiplier must be a positive number"
            )
        numeric_multiplier = float(multiplier)
        if numeric_multiplier in multipliers:
            raise ResourceValidationError(
                f"{description} has duplicate multiplier: {numeric_multiplier}"
            )
        multipliers.add(numeric_multiplier)
        if entry_id == base_unit_id:
            base_multiplier = numeric_multiplier
        _validate_i18n_reference(
            entry.get("label"), f"{description}.{entry_id}.label", translations
        )
    if base_multiplier != 1.0:
        raise ResourceValidationError(
            f"{description} must define base unit {base_unit_id} with multiplier 1"
        )
    if default_unit_id not in ids:
        raise ResourceValidationError(
            f"{description} default unit does not exist: {default_unit_id}"
        )


def validate_resource(source_root: Path) -> Mapping[str, Any]:
    categories_path = source_root / "config/categories.yaml"
    fields_path = source_root / "config/fields.yaml"
    i18n_path = source_root / "config/i18n.yaml"
    if not categories_path.is_file() or not fields_path.is_file() or not i18n_path.is_file():
        raise ResourceValidationError(
            "config/categories.yaml, config/fields.yaml, and config/i18n.yaml are required"
        )

    categories_document = _read_yaml(categories_path)
    fields_document = _read_yaml(fields_path)
    translations = _validate_translations(_read_yaml(i18n_path))
    categories = categories_document.get("categories")
    fields = fields_document.get("fields")
    if not isinstance(categories, list) or not categories:
        raise ResourceValidationError("categories must be a non-empty list")
    if not isinstance(fields, list) or not fields:
        raise ResourceValidationError("fields must be a non-empty list")

    field_ids: set[str] = set()
    field_nfc: dict[str, Mapping[str, Any]] = {}
    nfc_field_codes: set[int] = set()
    for field in fields:
        if not isinstance(field, dict):
            raise ResourceValidationError("Every field must be an object")
        field_id = _require_string(field.get("id"), "field.id")
        if field_id in field_ids:
            raise ResourceValidationError(f"Duplicate field id: {field_id}")
        field_ids.add(field_id)
        field_type = _require_string(field.get("type"), f"field {field_id}.type")
        if field_type not in SUPPORTED_FIELD_TYPES:
            raise ResourceValidationError(
                f"field {field_id}.type must be one of {sorted(SUPPORTED_FIELD_TYPES)}"
            )
        _validate_i18n_reference(field.get("label"), f"field {field_id}.label", translations)
        if not isinstance(field.get("required"), bool):
            raise ResourceValidationError(f"field {field_id}.required must be a boolean")
        value_type = field.get("valueType")
        if value_type is not None:
            _validate_value_type(value_type, f"field {field_id}.valueType")
            if field_type != "decimal":
                raise ResourceValidationError(f"field {field_id}.valueType requires decimal type")
        options = field.get("options")
        if field_type == "enum":
            if not isinstance(options, list) or not options:
                raise ResourceValidationError(f"enum field {field_id} needs options")
            option_ids: set[str] = set()
            for option in options:
                if not isinstance(option, dict):
                    raise ResourceValidationError(f"field {field_id} has an invalid option")
                option_id = _require_string(option.get("id"), f"field {field_id}.option.id")
                if option_id in option_ids:
                    raise ResourceValidationError(
                        f"field {field_id} has duplicate option id: {option_id}"
                    )
                option_ids.add(option_id)
                _validate_i18n_reference(
                    option.get("label"), f"field {field_id}.option.label", translations
                )
        elif options is not None:
            raise ResourceValidationError(f"only enum field {field_id} may define options")

        nfc = field.get("nfc")
        if nfc is not None:
            if not isinstance(nfc, dict):
                raise ResourceValidationError(f"field {field_id}.nfc must be an object")
            code = _nfc_code(nfc.get("code"), f"field {field_id}.nfc.code")
            if code in nfc_field_codes:
                raise ResourceValidationError(f"Duplicate NFC field code: {code}")
            nfc_field_codes.add(code)
            role = _require_string(nfc.get("role"), f"field {field_id}.nfc.role")
            if role not in SUPPORTED_NFC_ROLES:
                raise ResourceValidationError(
                    f"field {field_id}.nfc.role must be one of {sorted(SUPPORTED_NFC_ROLES)}"
                )
            _validate_nfc_dictionary(
                nfc.get("dictionary"), f"field {field_id}.nfc.dictionary", translations
            )
            if role == "tolerance":
                dictionary = nfc.get("dictionary")
                if not isinstance(dictionary, list) or {
                    entry.get("code") for entry in dictionary
                } != set(range(1, 11)):
                    raise ResourceValidationError(
                        f"field {field_id}.nfc tolerance codes must be 1 through 10"
                    )
            field_nfc[field_id] = nfc

    category_ids: set[str] = set()
    category_nfc_codes: set[int] = set()
    for category in categories:
        if not isinstance(category, dict):
            raise ResourceValidationError("Every category must be an object")
        category_id = _require_string(category.get("id"), "category.id")
        if category_id in category_ids:
            raise ResourceValidationError(f"Duplicate category id: {category_id}")
        category_ids.add(category_id)
        _validate_i18n_reference(category.get("name"), f"category {category_id}.name", translations)
        icon_path = _relative_resource_path(category.get("icon"), f"category {category_id}.icon")
        if icon_path.suffix.lower() != ".svg":
            raise ResourceValidationError(f"category {category_id}.icon must point to an SVG")
        if not (source_root / icon_path).is_file():
            raise ResourceValidationError(f"category {category_id}.icon does not exist: {icon_path}")
        referenced_fields = category.get("fieldIds")
        if not isinstance(referenced_fields, list) or not referenced_fields:
            raise ResourceValidationError(f"category {category_id}.fieldIds must be a non-empty list")
        if len(referenced_fields) != len(set(referenced_fields)):
            raise ResourceValidationError(f"category {category_id}.fieldIds contains duplicates")
        for field_id in referenced_fields:
            if field_id not in field_ids:
                raise ResourceValidationError(
                    f"category {category_id} references missing field: {field_id}"
                )
            if field_id != "quantity" and field_id not in field_nfc:
                raise ResourceValidationError(
                    f"category {category_id} field {field_id} requires NFC metadata"
                )
        nfc = category.get("nfc")
        if not isinstance(nfc, dict):
            raise ResourceValidationError(f"category {category_id}.nfc must be an object")
        code = _nfc_code(nfc.get("code"), f"category {category_id}.nfc.code")
        if code in category_nfc_codes:
            raise ResourceValidationError(f"Duplicate NFC category code: {code}")
        category_nfc_codes.add(code)
        secondary_field_id = nfc.get("secondaryFieldId")
        if secondary_field_id is not None:
            secondary_field_id = _require_string(
                secondary_field_id, f"category {category_id}.nfc.secondaryFieldId"
            )
            if secondary_field_id not in referenced_fields:
                raise ResourceValidationError(
                    f"category {category_id}.nfc.secondaryFieldId must be in fieldIds"
                )
            if field_nfc.get(secondary_field_id, {}).get("role") != "secondary":
                raise ResourceValidationError(
                    f"category {category_id}.nfc.secondaryFieldId must have secondary role"
                )
        value = nfc.get("value")
        if value is not None:
            if not isinstance(value, dict):
                raise ResourceValidationError(f"category {category_id}.nfc.value must be an object")
            value_field_id = _require_string(
                value.get("fieldId"), f"category {category_id}.nfc.value.fieldId"
            )
            if value_field_id not in referenced_fields or field_nfc.get(value_field_id, {}).get("role") != "value":
                raise ResourceValidationError(
                    f"category {category_id}.nfc.value.fieldId must reference a value field"
                )
            base_unit_id = _require_string(
                value.get("unit"), f"category {category_id}.nfc.value.unit"
            )
            _validate_value_type(value.get("valueType"), f"category {category_id}.nfc.value.valueType")
            default_unit_id = _require_string(
                value.get("defaultUnitId"),
                f"category {category_id}.nfc.value.defaultUnitId",
            )
            _validate_value_units(
                value.get("units"),
                f"category {category_id}.nfc.value.units",
                translations,
                base_unit_id,
                default_unit_id,
            )
            dictionary = value.get("dictionary")
            if not isinstance(dictionary, list) or not dictionary:
                raise ResourceValidationError(
                    f"category {category_id}.nfc.value.dictionary must be a non-empty list"
                )
            _validate_nfc_dictionary(
                dictionary, f"category {category_id}.nfc.value.dictionary", translations
            )
            _validate_preset_series(
                value.get("presets"),
                f"category {category_id}.nfc.value.presets",
                translations,
            )
    return {"categories": categories, "fields": fields, "translations": translations}


def _file_hash(path: Path) -> str:
    digest = hashlib.sha256()
    with path.open("rb") as file:
        for block in iter(lambda: file.read(1024 * 1024), b""):
            digest.update(block)
    return digest.hexdigest()


def _resource_json(resource_package: Mapping[str, Any]) -> bytes:
    return (json.dumps(resource_package, ensure_ascii=False, separators=(",", ":")) + "\n").encode("utf-8")


def build_manifest(resource_json: bytes) -> Mapping[str, Any]:
    return {
        "files": [
            {
                "path": RESOURCE_JSON_PATH.as_posix(),
                "sha256": hashlib.sha256(resource_json).hexdigest(),
            }
        ]
    }


def _atomic_write(path: Path, content: bytes) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    with tempfile.NamedTemporaryFile(dir=path.parent, delete=False) as file:
        temporary_path = Path(file.name)
        file.write(content)
    temporary_path.replace(path)


def prepare(source_root: Path, asset_root: Path, dry_run: bool = False) -> Mapping[str, Any]:
    resource_package = validate_resource(source_root)
    resource_json = _resource_json(resource_package)
    manifest = build_manifest(resource_json)
    if dry_run:
        print(f"Validated 1 resource package; would write to {asset_root}")
        return manifest

    _atomic_write(asset_root / RESOURCE_JSON_PATH, resource_json)
    _atomic_write(
        asset_root / MANIFEST_PATH,
        (json.dumps(manifest, ensure_ascii=False, indent=2) + "\n").encode("utf-8"),
    )
    for legacy_name in ("categories.json", "fields.json"):
        legacy_path = asset_root / "config" / legacy_name
        if legacy_path.exists():
            legacy_path.unlink()
    print(f"Prepared 1 resource package in {asset_root}")
    return manifest


def _prepared_files(asset_root: Path) -> list[Path]:
    files = [asset_root / RESOURCE_JSON_PATH, asset_root / MANIFEST_PATH]
    missing = [path.relative_to(asset_root).as_posix() for path in files if not path.is_file()]
    if missing:
        raise ResourceValidationError(f"Prepared resources are missing: {', '.join(missing)}")
    return files


def release_hash(asset_root: Path) -> str:
    digest = hashlib.sha256()
    for path in _prepared_files(asset_root):
        relative_path = path.relative_to(asset_root).as_posix()
        digest.update(relative_path.encode("utf-8"))
        digest.update(b"\0")
        digest.update(path.read_bytes())
        digest.update(b"\0")
    return digest.hexdigest()


def _r2_client_from_environment() -> Any:
    missing = [
        name
        for name in ("R2_ENDPOINT_URL", "R2_ACCESS_KEY_ID", "R2_SECRET_ACCESS_KEY", "R2_BUCKET")
        if not os.environ.get(name)
    ]
    if missing:
        raise RuntimeError(f"Missing R2 environment variables: {', '.join(missing)}")
    try:
        import boto3
    except ImportError as error:
        raise RuntimeError("publish requires boto3; install it in the release environment") from error
    return boto3.client(
        "s3",
        endpoint_url=os.environ["R2_ENDPOINT_URL"],
        aws_access_key_id=os.environ["R2_ACCESS_KEY_ID"],
        aws_secret_access_key=os.environ["R2_SECRET_ACCESS_KEY"],
        region_name="auto",
    )


def publish(
    asset_root: Path,
    bucket: str,
    client: Any,
    dry_run: bool = False,
) -> str:
    version = release_hash(asset_root)
    prefix = f"releases/{version}"
    files = _prepared_files(asset_root)
    for path in files:
        relative_path = path.relative_to(asset_root).as_posix()
        key = f"{prefix}/{relative_path}"
        if dry_run:
            print(f"Would upload {key}")
        else:
            client.put_object(Bucket=bucket, Key=key, Body=path.read_bytes())

    current = {
        "version": version,
        "prefix": f"{prefix}/",
        "manifest": f"{prefix}/manifest.json",
    }
    if dry_run:
        print(f"Would update {LATEST_RELEASE_KEY} last")
    else:
        client.put_object(
            Bucket=bucket,
            Key=LATEST_RELEASE_KEY,
            Body=(json.dumps(current, ensure_ascii=False, separators=(",", ":")) + "\n").encode("utf-8"),
            ContentType="application/json",
        )
    print(f"Published {len(files)} files as {version}")
    return version


def main(argv: Optional[Iterable[str]] = None) -> int:
    options = argparse.ArgumentParser(add_help=False)
    options.add_argument("--source", type=Path, default=argparse.SUPPRESS)
    options.add_argument("--assets", type=Path, default=argparse.SUPPRESS)
    options.add_argument("--dry-run", action="store_true", default=argparse.SUPPRESS)
    parser = argparse.ArgumentParser(description=__doc__, parents=[options])
    commands = parser.add_subparsers(dest="command", required=True)
    commands.add_parser(
        "prepare",
        parents=[options],
        help="validate source resources and build a Flutter resource package",
    )
    commands.add_parser(
        "publish", parents=[options], help="upload prepared resources to Cloudflare R2"
    )
    arguments = parser.parse_args(argv)
    source = getattr(arguments, "source", RESOURCE_ROOT)
    assets = getattr(arguments, "assets", ASSET_ROOT)
    dry_run = getattr(arguments, "dry_run", False)
    try:
        if arguments.command == "prepare":
            prepare(source, assets, dry_run)
        else:
            validate_resource(source)
            if not assets.is_dir():
                if dry_run:
                    raise ResourceValidationError(
                        f"Prepared asset directory does not exist: {assets}. Run prepare first."
                    )
                prepare(source, assets, False)
            publish(assets, os.environ.get("R2_BUCKET", "<R2_BUCKET>"),
                    None if dry_run else _r2_client_from_environment(), dry_run)
    except (ResourceValidationError, RuntimeError) as error:
        print(f"resource_sync: {error}", file=sys.stderr)
        return 1
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
