$ErrorActionPreference = 'Continue'
$taskRoot = Split-Path -Parent $PSScriptRoot
$taskAppId = '1:325788297793:android:cab278cb7c9a4e1f3274c0'
$taskProperties = @{}
Get-Content -LiteralPath (Join-Path $taskRoot 'android/key.properties') | ForEach-Object {
    if ($_ -match '^([^#=]+)=(.*)$') { $taskProperties[$matches[1].Trim()] = $matches[2] }
}
$taskFingerprints = @()
function Register-SpendWiseCertificate([string]$Keystore, [string]$Alias, [string]$Password, [string]$Label) {
    $env:SPENDWISE_CERT_PASSWORD = $Password
    try {
        $taskCertificateOutput = (& keytool '-J-Duser.language=en' -list -v -keystore $Keystore -alias $Alias -storepass:env SPENDWISE_CERT_PASSWORD 2>&1) -join "`n"
        if ($LASTEXITCODE -ne 0) { throw "Could not read the $Label certificate." }
        foreach ($taskAlgorithm in @('SHA1','SHA256')) {
            $taskMatch = [regex]::Match($taskCertificateOutput, "$taskAlgorithm`:\s*([A-Fa-f0-9:]+)")
            if (-not $taskMatch.Success) { throw "Missing $taskAlgorithm fingerprint." }
            $taskHash = $taskMatch.Groups[1].Value.Replace(':','')
            & firebase apps:android:sha:create $taskAppId $taskHash --project emergio-f2ef7 *> (Join-Path $taskRoot ".cache/register-$Label-$taskAlgorithm.txt")
            if ($LASTEXITCODE -ne 0) { throw "Could not register $Label $taskAlgorithm; inspect the local registration log." }
            $script:taskFingerprints += [pscustomobject]@{certificate=$Label;algorithm=$taskAlgorithm;fingerprint=$taskHash}
            Write-Output "Registered $Label $taskAlgorithm certificate."
        }
    } finally { Remove-Item Env:/SPENDWISE_CERT_PASSWORD -ErrorAction SilentlyContinue }
}
Register-SpendWiseCertificate -Keystore (Join-Path $taskRoot 'android/upload-keystore.jks') -Alias $taskProperties['keyAlias'] -Password $taskProperties['storePassword'] -Label 'upload'
$taskDebugKeystore = Join-Path $env:USERPROFILE '.android/debug.keystore'
if (Test-Path -LiteralPath $taskDebugKeystore) {
    Register-SpendWiseCertificate -Keystore $taskDebugKeystore -Alias 'androiddebugkey' -Password 'android' -Label 'debug'
}
$taskFingerprints | ConvertTo-Json | Set-Content -LiteralPath (Join-Path $taskRoot '.cache/signing-fingerprints.json')
