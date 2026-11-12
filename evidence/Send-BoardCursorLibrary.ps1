$ErrorActionPreference='Stop'
$compressedFile=Join-Path $PSScriptRoot 'libwms-cursor-screen-id.so.gz'
# Rockchip's console switches to its debugger when it receives the literal
# sequence f-i-q. Remove the letter i from the transmitted encoding.
$encodedLibrary=[Convert]::ToBase64String([IO.File]::ReadAllBytes($compressedFile)).Replace('i','@')
$transferPort=[System.IO.Ports.SerialPort]::new('COM4',1500000,[System.IO.Ports.Parity]::None,8,[System.IO.Ports.StopBits]::One)
$transferPort.ReadBufferSize=1048576
$transferPort.WriteTimeout=10000
$transferCapture=[Text.StringBuilder]::new()
try {
    $transferPort.Open()
    $transferPort.DiscardInBuffer()
    $transferPort.Write("`rtr @ i <<'CURSOR_B64_EOF' | base64 -d > /data/local/tmp/libwms-cursor-screen-id.so.gz`r")
    Start-Sleep -Milliseconds 300
    [void]$transferCapture.Append($transferPort.ReadExisting())
    for($transferOffset=0; $transferOffset -lt $encodedLibrary.Length; $transferOffset+=608) {
        $transferChunk=[Text.StringBuilder]::new()
        for($lineOffset=$transferOffset; $lineOffset -lt [Math]::Min($transferOffset+608,$encodedLibrary.Length); $lineOffset+=76) {
            [void]$transferChunk.Append($encodedLibrary.Substring($lineOffset,[Math]::Min(76,$encodedLibrary.Length-$lineOffset)))
            [void]$transferChunk.Append("`r")
        }
        $transferPort.Write($transferChunk.ToString())
        Start-Sleep -Milliseconds 15
        $receivedChunk=$transferPort.ReadExisting()
        [void]$transferCapture.Append($receivedChunk)
        if($receivedChunk -match 'Welcome to irq debugger') { throw 'Console entered debugger during transfer' }
    }
    $transferPort.Write("CURSOR_B64_EOF`r")
    Start-Sleep -Milliseconds 700
    $transferPort.Write("echo TRANSFER_CHECK; sha256sum /data/local/tmp/libwms-cursor-screen-id.so.gz; gzip -t /data/local/tmp/libwms-cursor-screen-id.so.gz && gzip -dc /data/local/tmp/libwms-cursor-screen-id.so.gz > /data/local/tmp/libwms-cursor-screen-id.so; sha256sum /data/local/tmp/libwms-cursor-screen-id.so; echo TRANSFER_DONE`r")
    for($transferRead=0; $transferRead -lt 300; $transferRead++) {
        Start-Sleep -Milliseconds 10
        [void]$transferCapture.Append($transferPort.ReadExisting())
    }
} finally {
    if($transferPort.IsOpen) { $transferPort.Close() }
    $transferPort.Dispose()
}
$transferRaw=$transferCapture.ToString()
$transferRaw | Set-Content -LiteralPath (Join-Path $PSScriptRoot 'library-transfer-safe.raw.txt') -Encoding UTF8
Get-FileHash -LiteralPath $compressedFile -Algorithm SHA256
$transferRaw.Substring([Math]::Max(0,$transferRaw.Length-3000)) -split '\r?\n' | Where-Object { $_ -notmatch '^\[\s*\d+\.\d+\]' }
