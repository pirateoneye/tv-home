param(
    [string]$BackupPath,
    [string]$AdbPath = (Join-Path $PSScriptRoot '../../../_tools/android/platform-tools/adb.exe'),
    [switch]$Yes
)

$ErrorActionPreference = 'Stop'
if (-not $BackupPath) {
    $BackupPath = (Read-Host 'Backup folder').Trim('"')
}
$state = Get-Content -LiteralPath (Join-Path $BackupPath 'restore-state.json') -Raw | ConvertFrom-Json
if (-not (Test-Path -LiteralPath $AdbPath)) {
    $AdbPath = (Get-Command adb -ErrorAction Stop).Source
}

function Invoke-TvAdb {
    param([string[]]$Arguments)
    & $AdbPath -s $state.serial @Arguments
    if ($LASTEXITCODE -ne 0) { throw "ADB failed: $($Arguments -join ' ')" }
}

Write-Host "Restore original Home: $($state.home)"
Write-Host 'Packages are restored or disabled, never uninstalled. App data is kept.'
if (-not $Yes -and (Read-Host 'Continue? [y/N]') -notmatch '^(y|yes)$') { return }
& $AdbPath connect $state.serial
if ($LASTEXITCODE -ne 0) { throw 'Cannot connect to TV. Enable USB debugging and approve this computer.' }

$commands = @{ 0 = 'default-state'; 1 = 'enable'; 2 = 'disable'; 3 = 'disable-user'; 4 = 'disable-until-used' }
foreach ($package in $state.packages) {
    if ($state.changedPackages -contains $package.name) {
        $operation = $commands[[int]$package.enabled]
        if (-not $operation) { throw "Unknown saved package state: $($package.enabled)" }
        Invoke-TvAdb @('shell', "pm $operation --user $($state.user) $($package.name)")
    }
}
Invoke-TvAdb @('shell', "cmd package set-home-activity --user $($state.user) $($state.home)")
Invoke-TvAdb @('shell', 'input keyevent KEYCODE_HOME')
if (-not $state.launcherInstalledBefore) {
    Invoke-TvAdb @('shell', "pm revoke --user $($state.user) $($state.launcherPackage) android.permission.ACCESS_FINE_LOCATION")
    Invoke-TvAdb @('shell', "pm disable-user --user $($state.user) $($state.launcherPackage)")
}
Invoke-TvAdb @('shell', 'cmd package resolve-activity --brief -a android.intent.action.MAIN -c android.intent.category.HOME')
Write-Host 'Original Home restored. Press Home on the remote.'
