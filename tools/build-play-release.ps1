param(
    [Parameter(Mandatory = $true)][string]$ApiUrl,
    [Parameter(Mandatory = $true)][string]$PrivacyPolicyUrl
)
$ErrorActionPreference = 'Stop'
$taskRoot = Split-Path -Parent $PSScriptRoot
foreach ($taskUrl in @($ApiUrl, $PrivacyPolicyUrl)) {
    $taskUri = [Uri]$taskUrl
    if (-not $taskUri.IsAbsoluteUri -or $taskUri.Scheme -ne 'https') {
        throw 'API and privacy policy URLs must use HTTPS.'
    }
}
$taskGoogleServices = Get-Content -Raw -LiteralPath (Join-Path $taskRoot 'android/app/google-services.json') | ConvertFrom-Json
$taskClient = @($taskGoogleServices.client | Where-Object {
    $_.client_info.android_client_info.package_name -eq 'com.bytesforges.spendwise'
})
if ($taskClient.Count -eq 0) {
    throw 'Register com.bytesforges.spendwise in Firebase and replace android/app/google-services.json first.'
}
if (-not (Test-Path -LiteralPath (Join-Path $taskRoot 'android/key.properties'))) {
    throw 'Configure the upload keystore in android/key.properties first.'
}
Push-Location $taskRoot
try {
    & flutter build appbundle --release "--dart-define=SPENDWISE_API_URL=$ApiUrl" "--dart-define=PRIVACY_POLICY_URL=$PrivacyPolicyUrl"
    if ($LASTEXITCODE -ne 0) { throw 'Release build failed.' }
} finally { Pop-Location }
