param(
    [Parameter(Mandatory=$true)][string]$Command,
    [Parameter(Mandatory=$true)][string]$Name,
    [int]$Seconds=5,
    [switch]$Interrupt
)
$ErrorActionPreference='Stop'
$probePort=[System.IO.Ports.SerialPort]::new('COM4',1500000,[System.IO.Ports.Parity]::None,8,[System.IO.Ports.StopBits]::One)
$probePort.ReadTimeout=1000
$probePort.WriteTimeout=3000
$probePort.ReadBufferSize=1048576
$probeText=[System.Text.StringBuilder]::new()
try {
    $probePort.Open()
    $probePort.DiscardInBuffer()
    if ($Interrupt) { $probePort.Write([string][char]3); Start-Sleep -Milliseconds 300 }
    $probePort.Write("`r")
    Start-Sleep -Milliseconds 200
    $probePort.Write("echo PROBE_BEGIN; $Command; echo PROBE_END`r")
    $probeTimer=[System.Diagnostics.Stopwatch]::StartNew()
    while($probeTimer.Elapsed.TotalSeconds -lt $Seconds) {
        Start-Sleep -Milliseconds 10
        [void]$probeText.Append($probePort.ReadExisting())
    }
} finally {
    if($probePort.IsOpen) { $probePort.Close() }
    $probePort.Dispose()
}
$probeRaw=$probeText.ToString()
$probeRaw | Set-Content -LiteralPath (Join-Path $PSScriptRoot "$Name.raw.txt") -Encoding UTF8
$probeLines=$probeRaw -split '\r?\n'
$probeClean=$probeLines | Where-Object { $_ -notmatch '^\[\s*\d+\.\d+\]' }
$probeClean | Set-Content -LiteralPath (Join-Path $PSScriptRoot "$Name.txt") -Encoding UTF8
$probeClean
