# Windows / Xiaomi installation

## Controls

- **Home** returns to the dock, including from inside YouTube or Netflix.
- **Left / Right**, then **OK**, opens YouTube or Netflix.
- **Down** opens the remaining apps; **Back** returns to the dock.
- **Menu** opens Inputs: AV, HDMI 1, HDMI 2, and Live TV on the tested Xiaomi model.
- The Wi-Fi pill opens network settings; Settings opens the Android TV settings app.
- Twelve bundled nature photographs crossfade every ten minutes while Home is visible. Returning after the interval advances the photo; leaving Home cancels the timer.

Automatic rotation was exercised on the TV using a temporary ten-second build: before/after screenshots showed different nature photographs without leaving Home. The installed delivery build restores the ten-minute interval.

Home was tested from both YouTube and Netflix on the final setup. Netflix's protected screen returned no screenshot bytes during the final check; its foreground activity and the subsequent Home return were observed directly. Home screenshots were captured successfully.

## Profile and scope

The tested target is Xiaomi MiTV-MOSR4, Android 11 / API 30, user 0. Only these existing packages are disabled:

- `com.google.android.apps.tv.launcherx`
- `com.google.android.tungsten.setupwraith`

Setting `com.mihir.tvhome/.MainActivity` as Home without disabling those packages was tested from inside YouTube and returned to Google TV instead. Disabling both and setting Home again made Home return to the new launcher.

This is **launcher-only mode**, not a full telemetry or manufacturer-content debloat. All other packages remain in their previous enabled states. Chromecast, Miracast, USB media, voice search, Live TV, Play Store, updates, and streaming apps were not disabled. Existing app data was not cleared and no package was uninstalled.

The dock configuration is `launcher/res/values/config.xml`. The Xiaomi TV app is `com.mitv.livetv`; the manifest declares visibility for it. Small docks keep compact, centered cards instead of stretching two apps across the screen.

## Build

Requires JDK 17 and Android SDK platform 34 / build-tools 34 on the computer only:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File launcher/build.ps1 -JavaHome "C:\path\to\jdk-17" -Sdk "C:\path\to\Android\Sdk"
```

Output: `launcher/build/tvhome.apk`. No Gradle, Python package, or third-party Android runtime is needed. The APK includes all wallpapers and requests no Internet permission. Its location permission is used to read the Wi-Fi network name; without the ADB grant Android may show an unavailable network name.

The Windows build explicitly uses UTF-8, recreates APK entries with forward slashes through the JDK archive writer, and stores resources uncompressed before zip alignment and signing. Windows `aapt2` assets otherwise retained backslashes: Android reported `wallpapers\\01.jpg` at the asset root and an empty `wallpapers` directory despite the JPEGs being inside the APK. JDK 25 with build-tools 34 also produced an internal D8 exception; JDK 17 built the installed APK successfully.

## Backup and restore

The pre-change backup is under `backup/20261022-200726/`, ignored by Git. It contains:

- Original package inventory, per-user enabled states, Home resolver and candidate activities.
- System, secure, and global settings snapshots, stored locally only.
- The original launcher APK and split APKs, plus setupwraith's APK.
- Before/after screenshots, restore state, and an interactive `Restore-TV.cmd` shortcut.

This is a settings/package backup, not a root-level image or backup of private streaming-app data. It is sufficient for the changes made: package enabled states, Home selection, and the newly granted launcher permission.

Double-click `Restore-TV.cmd` in that backup folder and answer `y`, or run:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File tools/restore.ps1 -BackupPath "backup\20261022-200726"
```

The TV must be awake and ADB-authorized. If its address changes, update `serial` in the local `restore-state.json`. Pass `-AdbPath` if the portable ADB executable moved.

Restore returns each changed existing package to its saved state, including Android's original `default` state rather than forcing `enabled`. It selects the original Home, revokes the new launcher's location grant, and disables the new launcher. Nothing is uninstalled. The restore script was executed on the TV and both original package states and Google TV Home were observed; the requested launcher setup was then reapplied.

Keep the backup folder, `tools/restore.ps1`, the portable ADB executable, and `launcher/debug.keystore`. Do not publish backups, screenshots, ADB keys, or the signing key. APK updates must use the same signing key.
