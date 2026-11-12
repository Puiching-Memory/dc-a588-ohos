$ErrorActionPreference='Stop'
$wirePort=[IO.Ports.SerialPort]::new('COM4',1500000,[IO.Ports.Parity]::None,8,[IO.Ports.StopBits]::One)
$wirePort.ReadBufferSize=1048576
$wirePort.WriteTimeout=5000
$wireLog=[Text.StringBuilder]::new()
function Read-UntilMarker([string]$Marker,[int]$From=0,[int]$TimeoutSeconds=10) {
    $timer=[Diagnostics.Stopwatch]::StartNew()
    while($timer.Elapsed.TotalSeconds -lt $TimeoutSeconds) {
        [void]$wireLog.Append($wirePort.ReadExisting())
        if($wireLog.ToString().IndexOf($Marker,$From,[StringComparison]::Ordinal) -ge 0) { return }
        Start-Sleep -Milliseconds 2
    }
    throw "Timed out awaiting $Marker"
}
function Send-Command([string]$Text,[string]$Marker) {
    $from=$wireLog.Length
    $wirePort.Write("$Text`r")
    Read-UntilMarker "$Marker`r`n" $from
}
try {
    $wirePort.Open()
    $wirePort.DiscardInBuffer()
    $wirePort.Write("`r")
    Start-Sleep -Milliseconds 100
    Send-Command ': > /data/local/tmp/cursor-rx.gz; echo AUX_BEGIN' 'AUX_BEGIN'
    $auxBytes=[IO.File]::ReadAllBytes((Join-Path $PSScriptRoot 'serial_file_receiver.gz'))
    $auxText=[Convert]::ToBase64String($auxBytes).Replace('i','@')
    for($auxOffset=0; $auxOffset -lt $auxText.Length; $auxOffset+=256) {
        $auxChunk=$auxText.Substring($auxOffset,[Math]::Min(256,$auxText.Length-$auxOffset))
        Send-Command "printf '%s' '$auxChunk' | tr @ i | base64 -d >> /data/local/tmp/cursor-rx.gz; echo AUX_ACK_$auxOffset" "AUX_ACK_$auxOffset"
    }
    Send-Command 'gzip -t /data/local/tmp/cursor-rx.gz && gzip -dc /data/local/tmp/cursor-rx.gz > /data/local/tmp/cursor-rx && chmod 755 /data/local/tmp/cursor-rx; sha256sum /data/local/tmp/cursor-rx; echo AUX_DONE' 'AUX_DONE'
    if($wireLog.ToString() -notmatch '63a1fb647fa4ffe9309db066a74b1db99c02edc442044c601ef8e9642ab0a3ac') { throw 'Receiver checksum mismatch' }
    $libraryBytes=[IO.File]::ReadAllBytes((Join-Path $PSScriptRoot 'libwms-cursor-screen-id.so.gz'))
    $libraryText=[Convert]::ToBase64String($libraryBytes).Replace('i','@')
    $begin=$wireLog.Length
    $wirePort.Write("/data/local/tmp/cursor-rx /data/local/tmp/cursor-library.encoded $($libraryText.Length)`r")
    Read-UntilMarker "RAW_READY`r`n" $begin
    for($libraryOffset=0; $libraryOffset -lt $libraryText.Length; $libraryOffset+=512) {
        $libraryChunk=$libraryText.Substring($libraryOffset,[Math]::Min(512,$libraryText.Length-$libraryOffset))
        $from=$wireLog.Length
        $wirePort.Write($libraryChunk)
        $expectedOffset=$libraryOffset+$libraryChunk.Length
        Read-UntilMarker "RAW_ACK $expectedOffset`r`n" $from
    }
    Read-UntilMarker "RAW_DONE 0`r`n" $begin
    Send-Command 'tr @ i < /data/local/tmp/cursor-library.encoded | base64 -d > /data/local/tmp/cursor-library.gz; gzip -t /data/local/tmp/cursor-library.gz && gzip -dc /data/local/tmp/cursor-library.gz > /data/local/tmp/libwms-cursor-screen-id.so; sha256sum /data/local/tmp/cursor-library.gz /data/local/tmp/libwms-cursor-screen-id.so; echo LIBRARY_CHECK_DONE' 'LIBRARY_CHECK_DONE'
    if($wireLog.ToString() -notmatch 'c7055481c6e72aeedaa39a487af6e6b5f8b84fe5d73090c212e38213db7d56ab') { throw 'Library checksum mismatch' }
    'Library transfer and SHA256 verification passed.'
} finally {
    if($wirePort.IsOpen) { $wirePort.Close() }
    $wirePort.Dispose()
    $wireLog.ToString() | Set-Content -LiteralPath (Join-Path $PSScriptRoot 'library-transfer-reliable.raw.txt') -Encoding UTF8
}
