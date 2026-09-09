# Publishing Android releases with GitHub

CompBox publishes a directly installable Android APK from GitHub Actions. The
APK is signed in the temporary Actions runner with the same private key used for
every release. GitHub stores encrypted copies of the build credentials, but it
must not be the only place where the key is backed up.

## Before the first public release

1. Replace the current `com.example.comp_box` application ID with a permanent,
   globally unique ID. Changing it later makes Android treat the app as a
   different application.
2. Decide whether the current keystore is the permanent production signing key.
   If it has not signed a public build yet, replace development-grade passwords
   before the first release.
3. Store the final keystore, alias, passwords, and recovery instructions in an
   encrypted offline backup. Losing the key prevents direct GitHub APK installs
   from receiving normally signed updates.
4. Keep `android/key.properties` and all `*.jks` files out of Git. The existing
   `android/.gitignore` already excludes them.

The workflow expects the keystore at
`android/app/compbox-upload-keystore.jks`. Its decoded `key.properties` must use
this relative path. Start from `android/key.properties.example` if needed:

```properties
storePassword=<keystore-password>
keyPassword=<key-password>
keyAlias=<key-alias>
storeFile=compbox-upload-keystore.jks
```

## Configure GitHub Actions secrets

Create these repository secrets:

- `ANDROID_KEYSTORE_BASE64`: base64-encoded keystore file.
- `ANDROID_KEY_PROPERTIES_BASE64`: base64-encoded `android/key.properties`.

With GitHub CLI authenticated for this repository, macOS and Linux can create
both secrets without writing additional plaintext files:

```sh
base64 < android/app/compbox-upload-keystore.jks \
  | tr -d '\n' \
  | gh secret set ANDROID_KEYSTORE_BASE64

base64 < android/key.properties \
  | tr -d '\n' \
  | gh secret set ANDROID_KEY_PROPERTIES_BASE64
```

Confirm that only the secret names are visible:

```sh
gh secret list
```

Repository administrators and anyone able to change a trusted release workflow
can cause those secrets to be used. Protect the release branch, require review
for workflow changes, and restrict repository administration accordingly.

## Publish a release

Update `version` in `pubspec.yaml`, merge the change into `dev`, then create and
push an annotated version tag:

```sh
git switch dev
git pull --ff-only
git tag -a v1.0.0 -m "CompBox v1.0.0"
git push origin v1.0.0
```

The `Release Android APK` workflow then:

1. Generates and validates the runtime resources.
2. Runs the Python tests, Flutter tests, and static analysis.
3. Restores the signing files from GitHub Secrets.
4. Builds the signed release APK.
5. Publishes the APK and its SHA-256 checksum to the matching GitHub Release.

The tag should point at the exact commit intended for release. Do not move or
reuse an already published version tag.

## Verify a downloaded APK

Compare the APK against the published checksum, then inspect its signing
certificate with the Android SDK build tools:

```sh
sha256sum -c CompBox-v1.0.0-android.apk.sha256
apksigner verify --verbose --print-certs CompBox-v1.0.0-android.apk
```

Record the production certificate's SHA-256 digest somewhere independent of
GitHub so users can compare future releases against the original signer.

## GitHub Releases and Google Play

For GitHub distribution, the workflow's key directly signs the APK installed on
the device, so every GitHub update must use that same key.

Google Play normally separates the app signing key from the upload key. If the
same package must update cleanly between GitHub and Play installations, plan the
signing identity before the first release: either provide Play with the same app
signing key used for GitHub APKs, or use different application IDs for the two
distribution channels. A Google-generated Play signing key will not match an APK
signed independently by this workflow.
