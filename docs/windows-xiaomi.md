# Windows / Xiaomi installation

## Controls

- **Home** returns to the dock, including from inside YouTube, Netflix, or Apple TV.
- **Left / Right**, then **OK**, opens YouTube, Netflix, or Apple TV.
- **Down** opens the remaining apps; **Back** returns to the dock.
- **Menu** opens Inputs: AV, HDMI 1, HDMI 2, and Live TV on the tested Xiaomi model.
- The Wi-Fi pill opens network settings; Settings opens the Android TV settings app.
- Twelve bundled nature photographs crossfade every ten minutes while Home is visible. Returning after the interval advances the photo; leaving Home cancels the timer.

Automatic rotation was exercised on the TV using a temporary ten-second build: before/after screenshots showed different nature photographs without leaving Home. The installed delivery build restores the ten-minute interval.

Home was tested from both YouTube and Netflix on the final setup. Netflix's protected screen returned no screenshot bytes during the final check; its foreground activity and the subsequent Home return were observed directly. Home screenshots were captured successfully.

Apple TV 17.0.0 was installed from Google Play (`com.android.vending`) and added to the dock. Its activity opens and Home returns correctly; content playback and account sign-in were not verified. The app was still displaying its loading screen during the captured check.

## Profile and scope

The tested target is Xiaomi MiTV-MOSR4, Android 11 / API 30, user 0. These launcher packages remain disabled:

- `com.google.android.apps.tv.launcherx`
- `com.google.android.tungsten.setupwraith`

Setting `com.mihir.tvhome/.MainActivity` as Home without disabling those packages was tested from inside YouTube and returned to Google TV instead. Disabling both and setting Home again made Home return to the new launcher.

The later lightweight profile additionally disables these 11 existing packages:

| Package | Scope |
|---|---|
| `com.miui.tv.analytics` | Xiaomi analytics |
| `com.xiaomi.statistic` | Statistics/upload service, confirmed by its installed manifest |
| `fusion.android.tv.demo` | Store demo |
| `android.autoinstalls.config.xiaomi.amelie` | Automatic app-install configuration |
| `com.xiaomi.android.tvsetup.partnercustomizer` | Setup promotions/customization |
| `com.mediatek.android.leanbacklauncher.partnercustomizer` | Stock-launcher customization |
| `com.google.android.feedback` | Feedback reporting |
| `com.mitv.tvhome.atv` | PatchWall |
| `com.mitv.tvhome.michannel` | Xiaomi content channels |
| `com.mitv.tvhome.oemtab` | Xiaomi content tab |
| `com.mitv.tvhome.mitvplus` | Xiaomi TV+ |

Chromecast, Miracast, USB media, voice search, Live TV, Play Store, system updates, and existing streaming apps remain enabled. Existing app data was not cleared and no package was uninstalled. The Google ambient screensaver did not retain its attempted disabled state and is left enabled; it is not counted as removed bloatware. The personal-photo build was removed on request; the final build uses only the 12 original nature wallpapers.

The dock configuration is `launcher/res/values/config.xml`. The Xiaomi TV app is `com.mitv.livetv`; the manifest declares visibility for it. Small docks keep compact, centered cards instead of stretching two apps across the screen.

## Observed resource use

Three force-stop/cold-start samples on the same TV, two seconds after each launch, with default nature wallpapers before and after cleanup:

| Metric | Before, median (range) | Final, median (range) |
|---|---|---|
| Available RAM | 412.4 MiB (409.4–413.1) | 592.8 MiB (590.8–594.4) |
| Launcher PSS | 61.1 MiB (59.8–87.6) | 41.0 MiB (41.0–50.7) |
| Cold start | 895 ms (839–1743) | 800 ms (773–2361) |

These are local observations, not proof of lag-free playback or an isolated causal benchmark. Apple TV was installed between measurements and Android's background/cached process population varied. The slower final worst-case cold start remains visible in the range. Storage had about 1.6 GiB free; low storage was not established as the cause. A historical CPU window showed a racing game consuming about 110% of one core, while current Home samples were mostly idle; that old window does not prove sustained CPU overload.

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

For the expanded cleanup, use `backup/debloat-20261022-205038/Restore-TV.cmd`. This backup restores the pre-cleanup launcher APK and package states and disables the newly installed Apple TV app. Its restore path was executed on the TV and the saved enabled states were checked before cleanup was reapplied. Use the earlier `backup/20261022-200726/Restore-TV.cmd` to return to the original Google TV launcher. Both restore operations preserve application data and never uninstall packages.

Keep the backup folder, `tools/restore.ps1`, the portable ADB executable, and `launcher/debug.keystore`. Do not publish backups, screenshots, ADB keys, or the signing key. APK updates must use the same signing key.
