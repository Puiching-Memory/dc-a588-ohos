$ErrorActionPreference = 'Stop'
$imageRoot = (Resolve-Path -LiteralPath (Join-Path $PSScriptRoot '..\..')).Path
$imageSource = Join-Path $PSScriptRoot 'sceneboard-r2-staging'
$imageTarget = Join-Path $imageRoot 'images'
$imageEvidence = Join-Path $PSScriptRoot 'sceneboard-preinstall-r2\evidence'
$imageNames = @('boot.img', 'system.img', 'vendor.img', 'sys_prod.img', 'chip_prod.img', 'parameter.txt')

function Read-ImageManifest([string]$Path) {
    $entries = @{}
    foreach ($line in Get-Content -LiteralPath $Path) {
        if ([string]::IsNullOrWhiteSpace($line)) { continue }
        if ($line -notmatch '^([0-9a-fA-F]{64})(?:\s+|\\t)(.+)$') { throw "Invalid checksum entry: $line" }
        $name = [IO.Path]::GetFileName($Matches[2])
        if ($entries.ContainsKey($name)) { throw "Duplicate checksum entry: $name" }
        $entries[$name] = $Matches[1].ToLowerInvariant()
    }
    return $entries
}

$imageOld = Read-ImageManifest (Join-Path $imageTarget 'SHA256SUMS.txt')
$imageNew = Read-ImageManifest (Join-Path $imageEvidence 'images.sha256')
if ($imageNew.Count -ne $imageNames.Count) { throw 'Unexpected incoming manifest size' }
foreach ($name in $imageNames) {
    if (-not $imageNew.ContainsKey($name)) { throw "Missing new checksum: $name" }
    $hash = (Get-FileHash -LiteralPath (Join-Path $imageSource $name) -Algorithm SHA256).Hash.ToLowerInvariant()
    if ($hash -ne $imageNew[$name]) { throw "Incoming image checksum mismatch: $name" }
}

$imageBackup = Join-Path $imageRoot ('backups\images-before-sceneboard-r2-' + (Get-Date -Format 'yyyyMMdd-HHmmss'))
New-Item -ItemType Directory -Path $imageBackup | Out-Null
foreach ($name in $imageNames + @('SHA256SUMS.txt', 'README-烧录说明.md')) {
    $original = Join-Path $imageTarget $name
    if (Test-Path -LiteralPath $original -PathType Leaf) {
        Copy-Item -LiteralPath $original -Destination (Join-Path $imageBackup $name)
    }
}
foreach ($name in $imageNames) {
    $backup = Join-Path $imageBackup $name
    if (Test-Path -LiteralPath $backup -PathType Leaf) {
        $hash = (Get-FileHash -LiteralPath $backup -Algorithm SHA256).Hash.ToLowerInvariant()
        if ($hash -ne $imageOld[$name]) { throw "Backup checksum mismatch: $name" }
    }
}

$imageVerified = foreach ($name in $imageNames) {
    Copy-Item -LiteralPath (Join-Path $imageSource $name) -Destination (Join-Path $imageTarget $name) -Force
    $hash = (Get-FileHash -LiteralPath (Join-Path $imageTarget $name) -Algorithm SHA256).Hash.ToLowerInvariant()
    if ($hash -ne $imageNew[$name]) { throw "Destination checksum mismatch: $name" }
    $imageOld[$name] = $hash
    [pscustomobject]@{file=$name; sha256=$hash; verified=$true}
}
$imageLines = foreach ($name in ($imageOld.Keys | Sort-Object)) { '{0}  {1}' -f $imageOld[$name],$name }
$imageLines | Set-Content -LiteralPath (Join-Path $imageTarget 'SHA256SUMS.txt') -Encoding ASCII
$imageReport = [pscustomobject]@{revision='sceneboard-preinstall-20261105-r2'; target=$imageTarget; backup=$imageBackup; verified=$imageVerified}
$imageReport | ConvertTo-Json -Depth 5 | Set-Content -LiteralPath (Join-Path $imageEvidence 'local-delivery.json') -Encoding UTF8
$imageReport | ConvertTo-Json -Depth 5
