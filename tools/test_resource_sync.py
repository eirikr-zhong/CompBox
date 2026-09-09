import hashlib
import importlib.util
import json
import tempfile
import unittest
from pathlib import Path


MODULE_PATH = Path(__file__).with_name("resource_sync.py")
SPEC = importlib.util.spec_from_file_location("resource_sync", MODULE_PATH)
resource_sync = importlib.util.module_from_spec(SPEC)
assert SPEC.loader is not None
SPEC.loader.exec_module(resource_sync)


class FakeR2Client:
    def __init__(self):
        self.puts = []

    def put_object(self, **kwargs):
        self.puts.append(kwargs)


def write_resource(root: Path) -> None:
    (root / "config").mkdir(parents=True, exist_ok=True)
    (root / "icons").mkdir(exist_ok=True)
    (root / "icons/resistor.svg").write_text("<svg/>", encoding="utf-8")
    (root / "config/i18n.yaml").write_text(
        "translations:\n  field.name: {zh: 名称, en: Name}\n  category.resistor: {zh: 电阻, en: Resistor}\n",
        encoding="utf-8",
    )
    (root / "config/fields.yaml").write_text(
        "fields:\n  - id: name\n    type: text\n    label: \"@i18n.field.name\"\n    required: true\n    nfc: {code: 1, role: text}\n",
        encoding="utf-8",
    )
    (root / "config/categories.yaml").write_text(
        "categories:\n  - id: resistor\n    name: \"@i18n.category.resistor\"\n    icon: icons/resistor.svg\n    fieldIds: [name]\n    nfc: {code: 1}\n",
        encoding="utf-8",
    )


class ResourceSyncTest(unittest.TestCase):
    def test_prepare_builds_one_compact_package_and_manifest_hash(self):
        with tempfile.TemporaryDirectory() as temporary_directory:
            root = Path(temporary_directory)
            source = root / "resource"
            assets = root / "assets/resource"
            write_resource(source)

            manifest = resource_sync.prepare(source, assets)

            package_path = assets / "config/resources.json"
            self.assertTrue(package_path.is_file())
            self.assertFalse((assets / "config/categories.json").exists())
            self.assertEqual(
                [entry["path"] for entry in manifest["files"]], ["config/resources.json"]
            )
            package_bytes = package_path.read_bytes()
            self.assertNotIn(b", ", package_bytes)
            self.assertEqual(
                manifest["files"][0]["sha256"], hashlib.sha256(package_bytes).hexdigest()
            )
            self.assertEqual(
                json.loads(package_bytes),
                {
                    "categories": [
                        {
                            "id": "resistor",
                            "name": "@i18n.category.resistor",
                            "icon": "icons/resistor.svg",
                            "fieldIds": ["name"],
                            "nfc": {"code": 1},
                        }
                    ],
                    "fields": [
                        {
                            "id": "name",
                            "type": "text",
                            "label": "@i18n.field.name",
                            "required": True,
                            "nfc": {"code": 1, "role": "text"},
                        }
                    ],
                    "translations": {
                        "field.name": {"en": "Name", "zh": "名称"},
                        "category.resistor": {"en": "Resistor", "zh": "电阻"},
                    },
                },
            )
            self.assertEqual(
                json.loads((assets / "manifest.json").read_text(encoding="utf-8")), manifest
            )

    def test_prepare_rejects_invalid_i18n_and_non_nfc_text(self):
        with tempfile.TemporaryDirectory() as temporary_directory:
            source = Path(temporary_directory) / "resource"
            write_resource(source)
            (source / "config/fields.yaml").write_text(
                "fields:\n  - id: name\n    type: text\n    label: \"@i18n.missing\"\n    required: true\n    nfc: {code: 1, role: text}\n",
                encoding="utf-8",
            )
            with self.assertRaisesRegex(resource_sync.ResourceValidationError, "missing translation"):
                resource_sync.validate_resource(source)

            write_resource(source)
            (source / "config/i18n.yaml").write_text(
                "translations:\n  field.name: {zh: 'e\u0301', en: Name}\n  category.resistor: {zh: 电阻, en: Resistor}\n",
                encoding="utf-8",
            )
            with self.assertRaisesRegex(resource_sync.ResourceValidationError, "NFC Unicode"):
                resource_sync.validate_resource(source)

    def test_publish_updates_latest_release_after_resource_and_manifest(self):
        with tempfile.TemporaryDirectory() as temporary_directory:
            root = Path(temporary_directory)
            source = root / "resource"
            assets = root / "assets/resource"
            write_resource(source)
            resource_sync.prepare(source, assets)
            client = FakeR2Client()

            version = resource_sync.publish(assets, "parts", client)

            keys = [put["Key"] for put in client.puts]
            self.assertEqual(keys[-1], resource_sync.LATEST_RELEASE_KEY)
            self.assertEqual(len(keys), 3)
            self.assertTrue(all(key.startswith(f"releases/{version}/") for key in keys[:-1]))
            current = json.loads(client.puts[-1]["Body"])
            self.assertEqual(current["version"], version)

    def test_publish_dry_run_does_not_write_objects(self):
        with tempfile.TemporaryDirectory() as temporary_directory:
            root = Path(temporary_directory)
            source = root / "resource"
            assets = root / "assets/resource"
            write_resource(source)
            resource_sync.prepare(source, assets)
            client = FakeR2Client()

            resource_sync.publish(assets, "parts", client, dry_run=True)

            self.assertEqual(client.puts, [])


if __name__ == "__main__":
    unittest.main()
