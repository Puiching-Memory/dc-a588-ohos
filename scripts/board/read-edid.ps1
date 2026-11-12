param([string]$Path)

function Parse-Edid {
    param([byte[]]$e)

    $mfgHi = $e[8]; $mfgLo = $e[9]
    $m1 = [char](64 + (($mfgHi -shr 2) -band 0x1F))
    $m2 = [char](64 + ((($mfgHi -band 0x03) -shl 3) -bor (($mfgLo -shr 5) -band 0x07)))
    $m3 = [char](64 + ($mfgLo -band 0x1F))
    $mfg = "$m1$m2$m3"

    $prod = [int]$e[10] + ([int]$e[11] -shl 8)

    $hcm = [int]$e[21]; $vcm = [int]$e[22]
    $diag = if ($hcm -gt 0 -and $vcm -gt 0) {
        [math]::Round([math]::Sqrt($hcm * $hcm + $vcm * $vcm) / 2.54, 1)
    } else { 0 }

    $timings = @()
    $name = ''
    $range = ''
    for ($o = 54; $o -lt 126; $o += 18) {
        $clk = [int]$e[$o] + ([int]$e[$o + 1] -shl 8)
        if ($clk -eq 0) {
            $tag = $e[$o + 3]
            if ($tag -eq 0xFC) {
                $s = ''
                for ($i = $o + 5; $i -lt $o + 18; $i++) {
                    if ($e[$i] -eq 10) { break }
                    $s += [char]$e[$i]
                }
                $name = $s.Trim()
            }
            elseif ($tag -eq 0xFD) {
                $range = "行频 $($e[$o+5])-${($e[$o+6])}kHz, 场频 $($e[$o+7])-${($e[$o+8])}Hz, 最大像素时钟 $($e[$o+9])MHz"
            }
            continue
        }
        $hact = [int]$e[$o + 2] + ((([int]$e[$o + 4] -band 0xF0) -shl 4))
        $hbl  = [int]$e[$o + 3] + ((([int]$e[$o + 4] -band 0x0F) -shl 8))
        $vact = [int]$e[$o + 5] + ((([int]$e[$o + 7] -band 0xF0) -shl 4))
        $vbl  = [int]$e[$o + 6] + ((([int]$e[$o + 7] -band 0x0F) -shl 8))
        $htot = $hact + $hbl
        $vtot = $vact + $vbl
        $hz = if ($htot -gt 0 -and $vtot -gt 0) {
            [math]::Round($clk * 10000.0 / ($htot * $vtot), 2)
        } else { 0 }
        $timings += [pscustomobject]@{
            Resolution = "$hact x $vact"
            RefreshHz  = $hz
            PixelClock = "$([math]::Round($clk / 100.0, 2)) MHz"
            Preferred  = ($timings.Count -eq 0)
        }
    }

    [pscustomobject]@{
        Manufacturer = $mfg
        ProductCode  = ('0x{0:X4}' -f $prod)
        MadeIn       = "$([int]$e[16]) 周 / $([int]$e[17] + 1990) 年"
        EdidVersion  = "$($e[18]).$($e[19])"
        PhysicalSize = "$hcm cm x $vcm cm"
        DiagonalInch = $diag
        MonitorName  = $name
        FreqRange    = $range
        Timings      = $timings
    }
}

$keys = Get-ChildItem 'HKLM:\SYSTEM\CurrentControlSet\Enum\DISPLAY' -ErrorAction SilentlyContinue
$seen = @{}
foreach ($k in $keys) {
    foreach ($inst in (Get-ChildItem $k.PSPath -ErrorAction SilentlyContinue)) {
        $dp = Join-Path $inst.PSPath 'Device Parameters'
        $edid = (Get-ItemProperty $dp -ErrorAction SilentlyContinue).EDID
        if (-not $edid) { continue }
        $hash = ($edid | ForEach-Object { $_.ToString('X2') }) -join ''
        if ($seen.ContainsKey($hash)) { continue }
        $seen[$hash] = $true
        $r = Parse-Edid -e $edid
        '========================================'
        "注册表项    : $($k.PSChildName) / $($inst.PSChildName)"
        "厂商        : $($r.Manufacturer)   产品码 $($r.ProductCode)"
        "型号名称    : $($r.MonitorName)"
        "生产        : $($r.MadeIn)   EDID $($r.EdidVersion)"
        "物理尺寸    : $($r.PhysicalSize)  => $($r.DiagonalInch) 英寸"
        "频率范围    : $($r.FreqRange)"
        '--- 详细时序 ---'
        $r.Timings | Format-Table -AutoSize | Out-String | Write-Host
    }
}
