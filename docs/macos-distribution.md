# macOS distribution

VibePaint ships macOS builds as a signed/notarized **DMG** when Apple credentials are configured in GitHub Actions. Without those secrets, CI still produces a DMG and `.app.zip`, but Gatekeeper will warn on first launch.

## Install (end users)

1. Download `VibePaint-<version>-macos.dmg` from [Releases](https://github.com/merklegroot/vibepaint/releases).
2. Open the disk image.
3. Drag **VibePaint** into **Applications**.
4. Eject the disk image.
5. Launch from Applications (or Spotlight).

### Gatekeeper / “app can’t be opened”

If the build was **signed and notarized**, double-click should work normally.

If the build was **not notarized** (or your machine is offline the first time), macOS may block it:

1. **System Settings → Privacy & Security**
2. Find the message about VibePaint being blocked
3. Click **Open Anyway**
4. Confirm **Open**

Alternatively: right-click the app → **Open** → **Open**.

## Developer Identity setup (signing + notarization)

You need an [Apple Developer Program](https://developer.apple.com/programs/) membership.

### 1. Create a Developer ID Application certificate

1. In [Certificates, Identifiers & Profiles](https://developer.apple.com/account/resources/certificates/list), create **Developer ID Application**.
2. Install it in Keychain Access on a Mac.
3. Export as `.p12` (include the private key). Set an export password.

Encode for GitHub:

```bash
base64 -i DeveloperID.p12 | pbcopy   # macOS
```

### 2. Notarization credentials (pick one)

**Preferred — App Store Connect API key**

1. [Users and Access → Integrations → Team Keys](https://appstoreconnect.apple.com/access/integrations/api)
2. Create a key with **Developer** access; download `AuthKey_XXXXXX.p8` once.
3. Note the **Key ID** and **Issuer ID**.

```bash
base64 -i AuthKey_XXXXXX.p8 | pbcopy
```

**Alternative — Apple ID + app-specific password**

1. Create an [app-specific password](https://appleid.apple.com/account/manage).
2. Note your Team ID (Membership details in the developer account).

### 3. GitHub repository secrets

| Secret | Purpose |
| --- | --- |
| `MACOS_CERTIFICATE` | Base64 `.p12` of Developer ID Application |
| `MACOS_CERTIFICATE_PWD` | `.p12` password |
| `MACOS_CERTIFICATE_NAME` | Exact identity string, e.g. `Developer ID Application: Your Name (TEAMID)` |
| `MACOS_CI_KEYCHAIN_PWD` | Any strong random password for the temporary CI keychain |
| `APPLE_API_KEY_BASE64` | Base64 `.p8` (preferred notarization) |
| `APPLE_API_KEY_ID` | API key id |
| `APPLE_API_ISSUER_ID` | Issuer UUID |
| `APPLE_ID` | Optional if using Apple ID notarization instead of API key |
| `APPLE_APP_SPECIFIC_PASSWORD` | Optional with `APPLE_ID` |
| `APPLE_TEAM_ID` | Optional with `APPLE_ID` |

Find the identity string on a Mac that has the cert installed:

```bash
security find-identity -v -p codesigning
```

### 4. Verify a local release build

```bash
flutter build macos --release
export MACOS_CERTIFICATE=… MACOS_CERTIFICATE_PWD=… MACOS_CERTIFICATE_NAME=…
export MACOS_CI_KEYCHAIN_PWD='temporary-ci-password'
# plus APPLE_API_* or APPLE_ID / APPLE_APP_SPECIFIC_PASSWORD / APPLE_TEAM_ID
scripts/macos/sign_and_notarize.sh build/macos/Build/Products/Release/VibePaint.app
scripts/macos/package_dmg.sh build/macos/Build/Products/Release/VibePaint.app VibePaint-local.dmg
scripts/macos/sign_and_notarize.sh VibePaint-local.dmg
```

## App configuration notes

- Bundle ID: `com.merklegroot.vibepaint` (`macos/Runner/Configs/AppInfo.xcconfig`)
- Category: Graphics Design (`LSApplicationCategoryType`)
- Sandbox + user-selected file read/write (for Open/Save via `file_picker`)
- Hardened Runtime enabled in the Xcode project (required for notarization)
- App icons: regenerate with `dart run flutter_launcher_icons` after changing `assets/app_icon.png`

## Scripts

| Script | Role |
| --- | --- |
| `scripts/macos/sign_and_notarize.sh` | Import cert, codesign nested code + app, notarize, staple |
| `scripts/macos/package_dmg.sh` | Build DMG with Applications symlink (`create-dmg` or `hdiutil`) |
| `macos/dmg/background.png` | Optional drag-to-Applications background for `create-dmg` |
