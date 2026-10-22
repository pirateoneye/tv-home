param(
    [string]$Sdk = (Join-Path $PSScriptRoot '../../../_tools/android/sdk'),
    [string]$JavaHome = $env:JAVA_HOME
)

$ErrorActionPreference = 'Stop'
$java = if ($JavaHome) { Join-Path $JavaHome 'bin/java.exe' } else { 'java' }
$javac = if ($JavaHome) { Join-Path $JavaHome 'bin/javac.exe' } else { 'javac' }
$keytool = if ($JavaHome) { Join-Path $JavaHome 'bin/keytool.exe' } else { 'keytool' }
$jar = if ($JavaHome) { Join-Path $JavaHome 'bin/jar.exe' } else { 'jar' }
$tools = Join-Path $Sdk 'android-14'
if (-not (Test-Path -LiteralPath $tools)) { $tools = Join-Path $Sdk 'build-tools/34.0.0' }
$androidJar = Join-Path $Sdk 'android-34/android.jar'
if (-not (Test-Path -LiteralPath $androidJar)) { $androidJar = Join-Path $Sdk 'platforms/android-34/android.jar' }
if (-not (Test-Path -LiteralPath $androidJar)) { throw 'Android SDK platform 34 is required.' }
$build = Join-Path $PSScriptRoot 'build'
$stage = Join-Path $build ('stage-' + [guid]::NewGuid().ToString('N'))
$generated = Join-Path $stage 'gen'
$classes = Join-Path $stage 'classes'
$dex = Join-Path $stage 'dex'
New-Item -ItemType Directory -Path $generated, $classes, $dex -Force | Out-Null

function Invoke-BuildTool {
    param([string]$File, [string[]]$Arguments)
    & $File @Arguments
    if ($LASTEXITCODE -ne 0) { throw "Build failed: $File" }
}

try {
    Invoke-BuildTool (Join-Path $tools 'aapt2.exe') @('compile', '--dir', (Join-Path $PSScriptRoot 'res'), '-o', "$stage/res.zip")
    Invoke-BuildTool (Join-Path $tools 'aapt2.exe') @('link', '-o', "$stage/base.apk", '-I', $androidJar, '--manifest', (Join-Path $PSScriptRoot 'AndroidManifest.xml'), '--java', $generated, '-A', (Join-Path $PSScriptRoot 'assets'), '--min-sdk-version', '30', '--target-sdk-version', '30', "$stage/res.zip")
    $javaFiles = @(Get-ChildItem (Join-Path $PSScriptRoot 'src'), $generated -Filter '*.java' -Recurse | ForEach-Object FullName)
    Invoke-BuildTool $javac (@('-encoding', 'UTF-8', '-nowarn', '-Xlint:-options', '--release', '11', '-classpath', $androidJar, '-d', $classes) + $javaFiles)
    $classFiles = @(Get-ChildItem $classes -Filter '*.class' -Recurse | ForEach-Object FullName)
    Invoke-BuildTool $java (@('-cp', (Join-Path $tools 'lib/d8.jar'), 'com.android.tools.r8.D8', '--min-api', '30', '--lib', $androidJar, '--output', $dex) + $classFiles)
    Add-Type -AssemblyName 'System.IO.Compression.FileSystem'
    $package = Join-Path $stage 'package'
    [System.IO.Compression.ZipFile]::ExtractToDirectory("$stage/base.apk", $package)
    Copy-Item -LiteralPath "$dex/classes.dex" -Destination "$package/classes.dex"
    Invoke-BuildTool $jar @('cfM0', "$stage/unsigned.apk", '-C', $package, '.')
    Invoke-BuildTool (Join-Path $tools 'zipalign.exe') @('-f', '4', "$stage/unsigned.apk", "$stage/aligned.apk")
    $keystore = Join-Path $PSScriptRoot 'debug.keystore'
    if (-not (Test-Path -LiteralPath $keystore)) {
        Invoke-BuildTool $keytool @('-genkeypair', '-keystore', $keystore, '-storepass', 'android', '-keypass', 'android', '-alias', 'tvhome', '-keyalg', 'RSA', '-keysize', '2048', '-validity', '10000', '-dname', 'CN=tvhome')
    }
    Invoke-BuildTool $java @('-jar', (Join-Path $tools 'lib/apksigner.jar'), 'sign', '--ks', $keystore, '--ks-pass', 'pass:android', '--out', "$stage/tvhome.apk", "$stage/aligned.apk")
    Invoke-BuildTool $java @('-jar', (Join-Path $tools 'lib/apksigner.jar'), 'verify', "$stage/tvhome.apk")
    Copy-Item -LiteralPath "$stage/tvhome.apk" -Destination "$build/tvhome.apk" -Force
    Write-Host "APK: $build\tvhome.apk"
} finally {
    Remove-Item -LiteralPath $stage -Recurse -Force
}
