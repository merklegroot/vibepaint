# macOS downloads

VibePaint macOS builds are **not** Apple Developer–signed or notarized. That’s fine for open-source distribution; Gatekeeper just needs a one-time confirmation the first time you open the app.

## Install

1. Download `VibePaint-<version>-macos.dmg` from [Releases](https://github.com/merklegroot/vibepaint/releases).
2. Open the disk image.
3. Drag **VibePaint** into **Applications**.
4. Eject the disk image.

## First launch (Gatekeeper)

macOS will usually block an unsigned app from the internet. Use either method:

### Right-click → Open (simplest)

1. In **Applications**, **right-click** (or Control-click) **VibePaint**
2. Choose **Open**
3. In the dialog, click **Open** again

After that, normal double-clicks work.

### System Settings

1. Try to open the app once (it may fail)
2. Open **System Settings → Privacy & Security**
3. Scroll to the message about VibePaint being blocked
4. Click **Open Anyway**, then confirm

## App zip alternative

If you prefer not to use a DMG, download `VibePaint-<version>-macos.app.zip`, unzip it, move `VibePaint.app` to Applications, then use **right-click → Open** as above.

## Build from source

```bash
flutter pub get
flutter run -d macos
```

Release `.app` + DMG locally:

```bash
flutter build macos --release
scripts/macos/package_dmg.sh \
  build/macos/Build/Products/Release/VibePaint.app \
  VibePaint-local-macos.dmg
```
