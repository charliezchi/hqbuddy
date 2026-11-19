# 用 .hqip 无界面生成 VLA + VIO

复制 `templates/vla/vla_vio.hqip`。它适合 IST158，默认配置一个 16 位 LA、1024 拍、触发前 128 拍，以及一个 9 位读回和一个 5 位驱动。VIO 驱动初值是全零，`generate_net:False` 生成受保护的 Verilog RTL。

| 改什么 | 修改位置 |
| --- | --- |
| 模块名 | `output_module=dual_debug_ip`。工程中的实例化使用同名模块 |
| 采样宽度 | 修改 `probe_port_0:16:Sample and Trigger` 中的 `16` |
| 深度和触发前采样 | 修改 `sample_depth` 和 `trig_pos`，保持 `trig_pos < sample_depth` |
| 输出宽度或初值 | 同时修改 `probe_out0:5:5'h00` 中的端口宽度和 Verilog 初值位宽 |
| 只要 VIO 驱动 | 设 `input_count=0`，保留 `probe_in={}` 空块，删除 `probe_in0:9` |
| 器件 | 修改 `[IP] device=` 为工程的完整料号，可用 `hqbuddy -get_device` 查看 |

在 hqbuddy 仓库运行以下 PowerShell。它把配置写到新目录，调用官方生成器的 `-gen`，等待同名 RTL 写完，再用官方工具生成保护段并核对端口。改模块名或位宽时同步改脚本中的文件名和最后的端口核对条件。

```powershell
$root = (hqbuddy -root | Select-Object -Last 1).Trim().Replace('\', '/')
$template = Get-Content -LiteralPath 'templates/vla/vla_vio.hqip' -Raw
$out = Join-Path $env:TEMP ('vla_ip_' + [guid]::NewGuid().ToString('N'))
New-Item -ItemType Directory -Path $out | Out-Null
$hqip = Join-Path $out 'dual_debug_ip.hqip'
$rtl = Join-Path $out 'dual_debug_ip.v'
Set-Content -LiteralPath $hqip -Value $template.Replace('@HQFPGA_ROOT@', $root) -Encoding ascii
New-Item -ItemType File -Path (Join-Path $out '.debug.txt') | Out-Null

$gen = "$root/build/ipcreator/sup_files/ipdepot/vla/_ipgen_/hq_vla_ins.exe"
$engine = "$root/build/win_x64/bin/hqfpga.exe"
$arguments = '-lang eng -gen "{0}" -hq_exe "{1}"' -f $hqip.Replace('\', '/'), $engine
$process = Start-Process -FilePath $gen -ArgumentList $arguments -WorkingDirectory $out -WindowStyle Hidden -PassThru
$deadline = (Get-Date).AddSeconds(30)
do {
    Start-Sleep -Milliseconds 200
    $ready = (Test-Path -LiteralPath $rtl) -and
             (Select-String -LiteralPath $rtl -Quiet -Pattern 'pragma protect end\s*$')
} until ($ready -or (Get-Date) -ge $deadline)
if (!$ready) { throw "VLA generation failed: $out" }
if (!$process.HasExited) { Stop-Process -Id $process.Id -ErrorAction SilentlyContinue }

$encrypt = "$root/build/common/util/hq_ipencrypt.exe"
$keys = "$root/build/common/util/keys.txt"
& $encrypt -f $rtl -po -r -pk $keys
if ($LASTEXITCODE -ne 0 -or
    !(Select-String -LiteralPath $rtl -Quiet -Pattern 'pragma protect end_protected')) {
    throw "VLA protection failed: $rtl"
}

$text = Get-Content -LiteralPath $rtl -Raw
if ($text -notmatch 'module\s+dual_debug_ip\(' -or $text -notmatch 'input\s+\[15:0\]\s+probe0') {
    throw "Generated RTL does not match the template: $rtl"
}
Get-Item -LiteralPath $hqip, $rtl
```

生成器会回写输出目录里的 .hqip。临时目录中的 `.debug.txt` 关闭生成器内置的异步加密，由脚本显式调用同一套官方加密工具并检查产物。原始模板可以重复使用。官方 `-gen` 是无界面入口，`-modify` 用于打开配置向导。双颗调试中采用单 LA、单窗口，以匹配 hqbuddy 联合采集的支持范围。
