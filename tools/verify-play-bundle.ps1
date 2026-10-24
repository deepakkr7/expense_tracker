param([string]$BundlePath = 'build/app/outputs/bundle/release/app-release.aab')
$ErrorActionPreference = 'Continue'
& (Join-Path $PSScriptRoot 'verify-native-alignment.ps1') -BundlePath $BundlePath
if (-not $?) { throw 'Native alignment verification failed.' }
$ErrorActionPreference = 'Continue'
$taskVerification = (& jarsigner -verify $BundlePath 2>&1) -join "`n"
if ($LASTEXITCODE -ne 0 -or $taskVerification -notmatch 'jar verified') { throw 'Bundle signature verification failed.' }
$taskBundleCertificate = (& keytool '-J-Duser.language=en' -printcert -jarfile $BundlePath 2>&1) -join "`n"
if ($LASTEXITCODE -ne 0) { throw 'Could not read bundle signer.' }
$taskBundleHash = ([regex]::Match($taskBundleCertificate,'SHA256:\s*([A-Fa-f0-9:]+)')).Groups[1].Value.Replace(':','')
$taskProperties = @{}
Get-Content -LiteralPath android/key.properties -ErrorAction Stop | ForEach-Object {
    if ($_ -match '^([^#=]+)=(.*)$') { $taskProperties[$matches[1].Trim()] = $matches[2] }
}
$env:SPENDWISE_VERIFY_PASSWORD = $taskProperties['storePassword']
try {
    $taskUploadCertificate = (& keytool '-J-Duser.language=en' -list -v -keystore android/upload-keystore.jks -alias $taskProperties['keyAlias'] -storepass:env SPENDWISE_VERIFY_PASSWORD 2>&1) -join "`n"
    if ($LASTEXITCODE -ne 0) { throw 'Could not read upload certificate.' }
    $taskUploadHash = ([regex]::Match($taskUploadCertificate,'SHA256:\s*([A-Fa-f0-9:]+)')).Groups[1].Value.Replace(':','')
} finally { Remove-Item Env:/SPENDWISE_VERIFY_PASSWORD -ErrorAction SilentlyContinue }
if (-not $taskBundleHash -or $taskBundleHash -ne $taskUploadHash) { throw 'Bundle signer does not match the upload certificate.' }
Write-Output 'Bundle signature is valid and matches the upload certificate.'
[xml]$taskManifest = Get-Content -Raw -LiteralPath build/app/intermediates/merged_manifests/release/processReleaseManifest/AndroidManifest.xml
$taskAndroidNs = 'http://schemas.android.com/apk/res/android'
if ($taskManifest.manifest.GetAttribute('package') -ne 'com.bytesforges.spendwise') { throw 'Unexpected application ID.' }
$taskTarget = [int]$taskManifest.manifest.'uses-sdk'.GetAttribute('targetSdkVersion',$taskAndroidNs)
if ($taskTarget -lt 36) { throw 'Target SDK must be at least 36.' }
foreach ($taskPermission in $taskManifest.manifest.'uses-permission') {
    $taskName = $taskPermission.GetAttribute('name',$taskAndroidNs)
    if ($taskName -match '^android.permission.(ACCESS_FINE_LOCATION|ACCESS_COARSE_LOCATION|ACCESS_BACKGROUND_LOCATION|USE_EXACT_ALARM|SCHEDULE_EXACT_ALARM|FOREGROUND_SERVICE_LOCATION)$') {
        throw "Unexpected restricted permission: $taskName"
    }
}
Write-Output "Verified package com.bytesforges.spendwise, target API $taskTarget, no location/exact-alarm permissions, and no bundled .env."
