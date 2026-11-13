# SPDX-License-Identifier: Apache-2.0
[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)][string]$ToolDirectory,
    [string]$ImageDirectory = (Join-Path $PSScriptRoot '..\..\images'),
    [switch]$Force
)
$ErrorActionPreference = 'Stop'
$toolPath = (Resolve-Path -LiteralPath $ToolDirectory).Path
$imagePath = (Resolve-Path -LiteralPath $ImageDirectory).Path
if (-not (Test-Path -LiteralPath $toolPath -PathType Container) -or
    -not (Test-Path -LiteralPath $imagePath -PathType Container)) {
    throw 'ToolDirectory and ImageDirectory must be directories.'
}
$output = Join-Path $toolPath 'config.cfg'
if ((Test-Path -LiteralPath $output) -and -not $Force) {
    throw 'config.cfg already exists; use -Force to replace it after saving your settings.'
}
$bytes = [IO.File]::ReadAllBytes((Join-Path $PSScriptRoot 'config.cfg'))
# Archived RKDevTool 3.37 format: 29-byte header, 14 fixed 610-byte rows;
# each row has a 260-code-unit UTF-16LE path field at offset 82.
if ($bytes.Length -ne 8569 -or [Text.Encoding]::ASCII.GetString($bytes, 0, 3) -ne 'CFG') {
    throw 'Unexpected config template format.'
}
$names = @('MiniLoaderAll.bin', 'parameter.txt', 'uboot.img', 'boot.img',
    'system.img', 'vendor.img', 'sys_prod.img', 'chip_prod.img',
    'updater.img', 'eng_system.img', 'userdata.img')
$seen = @{}
for ($row = 0; $row -lt 14; $row++) {
    $offset = 29 + $row * 610 + 82
    $entry = [Text.Encoding]::Unicode.GetString($bytes, $offset, 520).Split([char]0)[0]
    if ($entry.Length -eq 0) { continue }
    $name = [IO.Path]::GetFileName($entry)
    if ($names -notcontains $name -or $entry -cne ('..\..\images\' + $name) -or $seen.ContainsKey($name)) {
        throw "Unexpected path in template row ${row}: $entry"
    }
    $seen[$name] = $true
    $replacement = [Text.Encoding]::Unicode.GetBytes((Join-Path $imagePath $name))
    if ($replacement.Length -gt 518) { throw "Image path exceeds 259 UTF-16 code units: $name" }
    [Array]::Clear($bytes, $offset, 520)
    [Array]::Copy($replacement, 0, $bytes, $offset, $replacement.Length)
}
if ($seen.Count -ne $names.Count) { throw 'Incomplete config template.' }
[IO.File]::WriteAllBytes($output, $bytes)
Write-Output "Created $output; image directory: $imagePath"
Write-Output 'Verify image checksums, selected rows and addresses in RKDevTool before writing.'
