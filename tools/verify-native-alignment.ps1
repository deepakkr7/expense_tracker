param([string]$BundlePath = 'build/app/outputs/bundle/release/app-release.aab')
$ErrorActionPreference = 'Stop'
Add-Type -AssemblyName System.IO.Compression.FileSystem
$taskBundle = [System.IO.Compression.ZipFile]::OpenRead((Resolve-Path -LiteralPath $BundlePath))
$taskRows = @()
try {
    if (@($taskBundle.Entries | Where-Object { $_.FullName -match '(^|/)\.env$' }).Count -gt 0) {
        throw 'A bundled .env file was found.'
    }
    foreach ($taskEntry in $taskBundle.Entries) {
        if ($taskEntry.FullName -notmatch '/lib/(arm64-v8a|x86_64)/.*\.so$') { continue }
        $taskStream = $taskEntry.Open()
        $taskBuffer = New-Object System.IO.MemoryStream
        try { $taskStream.CopyTo($taskBuffer); $taskBytes = $taskBuffer.ToArray() }
        finally { $taskStream.Dispose(); $taskBuffer.Dispose() }
        if ($taskBytes[0] -ne 127 -or $taskBytes[1] -ne 69 -or $taskBytes[4] -ne 2 -or $taskBytes[5] -ne 1) {
            throw "Unsupported ELF format: $($taskEntry.FullName)"
        }
        $taskHeaderOffset = [BitConverter]::ToUInt64($taskBytes,32)
        $taskHeaderSize = [BitConverter]::ToUInt16($taskBytes,54)
        $taskHeaderCount = [BitConverter]::ToUInt16($taskBytes,56)
        $taskMinimumAlignment = [UInt64]::MaxValue
        $taskAligned = $true
        $taskLoadCount = 0
        for ($taskIndex = 0; $taskIndex -lt $taskHeaderCount; $taskIndex++) {
            $taskOffset = [int]($taskHeaderOffset + $taskIndex * $taskHeaderSize)
            if ([BitConverter]::ToUInt32($taskBytes,$taskOffset) -ne 1) { continue }
            $taskLoadCount++
            $taskFileOffset = [BitConverter]::ToUInt64($taskBytes,$taskOffset+8)
            $taskVirtualAddress = [BitConverter]::ToUInt64($taskBytes,$taskOffset+16)
            $taskAlignment = [BitConverter]::ToUInt64($taskBytes,$taskOffset+48)
            $taskMinimumAlignment = [Math]::Min($taskMinimumAlignment,$taskAlignment)
            if ($taskAlignment -lt 16384 -or ($taskFileOffset % 16384) -ne ($taskVirtualAddress % 16384)) {
                $taskAligned = $false
            }
        }
        if ($taskLoadCount -eq 0) { throw 'ELF has no loadable segments.' }
        $taskRows += [pscustomobject]@{library=$taskEntry.FullName;minimumAlignment=$taskMinimumAlignment;supports16KbElfAlignment=$taskAligned}
    }
} finally { $taskBundle.Dispose() }
if ($taskRows.Count -eq 0) { throw 'No 64-bit native libraries found.' }
$taskRows | Export-Csv -LiteralPath .cache/native-alignment.csv -NoTypeInformation
$taskRows | Format-Table -AutoSize
if (@($taskRows | Where-Object { -not $_.supports16KbElfAlignment }).Count -gt 0) {
    throw 'One or more native libraries fail 16 KB ELF alignment.'
}
Write-Output 'All inspected 64-bit ELF load segments meet 16 KB alignment. Runtime and generated APK ZIP alignment still require verification.'
