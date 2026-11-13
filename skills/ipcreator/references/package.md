# 通用 HDL IP 封装

适用于有权打包且已可用目标 HqFpga 综合的 RTL。以 `ipcreator/ipgen/ipgen_hdl_ip/ipgen_hdl_ip.py` 为实现依据，现有 `sup_files/ipdepot/PSRAM_Controller/PSRAM_Controller` 可对照普通描述文件和参数写法。对现有 IP 增加配置项时，先核对后端和 RTL 是否消费该配置。

多文件 RTL 的归档目录、综合清单和解包验证见 [.enc 源包](enc-source.md)。

## 文件与生成契约

```text
<IP目录>/
  demo.xml
  demo.enc
  _ipgen_.desc
  head.v
  trans_lang.chs     按需提供本地化
  demo.dgm           按需提供框图
  demo.ii            按需提供内部默认配置
  opt.tcl            按需补充综合选项或源文件清单
  lo.tcl             按需在 RTL 综合后运行
  pp.tcl             按需在映射后处理网表
```

```ini
[IPGEN]
EXE=<ROOT>/ipgen_hdl_ip.exe
HQFPGA=YES
```

- 后端按 `.hqip` 内的 `[IP] meta_file` 找源包与旁文件。 `demo.enc` 的基名和归档内顶层目录跟 XML 文件基名一致。后端解包后在 `demo/top/` 选顶层文件，`Functional_Selection` 的值为文件基名，也要与 RTL 模块名一致。单顶层也可以显式填写以避免依赖文件顺序。
- 通用后端默认把生成的 wrapper 和选中的顶层文件加入 `vlog_files`。子模块通过明确的 `include` 路径或随包的 `opt.tcl` 补充。 `opt.tcl` 在 `design.analyze` 之前执行，路径以综合脚本所在临时根目录为基准，如 `src/demo/rtl/...`。依赖 HDL、头文件和必要的静态资源都放进源包。
- `head.v` 提供输出文件头。FT111226 实测即使临时使用明文输出也会读取它，最小样例可用一行 Verilog 注释。
- `.enc` 是 `hqencrypt` 的源包。输出网表的加密由另一阶段处理。源码中的 `ENC_OFF` 按配置项是否存在开启明文路径。只在需要检查自有 IP 的明文测试版本时添加，发布时遵循 IP 自身的交付要求。

## 参数与接口

把要传入 RTL 的 XML 完整键放进隐藏的 `SYS_PARAMS` 枚举。 `SYS_PARAMS` 的枚举列表就是参数白名单。后端从已校验的配置取当前值，跳过不生效的项，去掉直接所属组的前缀，并为对应 RTL 参数生成 `defparam`。枚举编码的例子：

```xml
<cfg name="Functional_Selection" hide="1">
    <values type="enum" default="invert_demo"><value>invert_demo</value></values>
</cfg>
<cfg name="SYS_PARAMS" hide="1">
    <values type="enum"><value>LOGIC.INVERT</value></values>
</cfg>
<cfg_group name="LOGIC" desc="Logic">
    <cfg name="INVERT" desc="Output polarity">
        <values type="enum" default="0">
            <value desc="Pass through">0</value>
            <value desc="Invert">1</value>
        </values>
    </cfg>
</cfg_group>
<port name="a"><dir>input</dir></port>
<port name="y"><dir>output</dir></port>
```

当 `LOGIC.INVERT=1` 时，RTL 顶层收到数值 `INVERT=1`。后端按 Verilog 文本拼接值，字符串参数要检查生成的实际字面量，文件类型有专用加引号处理。预处理宏、只读配置及其他生成器保留项见 [meta XML 语法与特殊设置](meta-xml.md)。

界面派生状态留在 XML。固定但必须生效的值可由稳定的 RTL 默认值提供，或建立可传参的隐藏配置，生成后核对实际覆盖。 只读属性用于界面，参数是否下发由 `SYS_PARAMS` 和活动条件控制。固定项可直接加入 `SYS_PARAMS`，生成时核对实际字面量。以 PSRAM 的 `MEMORY.TCEM_NS` 为例，生成值应为 4000。

后端按 XML 活动端口生成同名连线 `.port(port)`，端口方向、`bus_range`、条件必须与同一配置下的封装顶层匹配。XML 与内部 RTL 名称不同，或必须把禁用接口输入绑常量时，写适配顶层。对于 PSRAM Preview，保留外部 `o_psram_clk`、`o_psram_ce`、`io_psram_dq`、`io_psram_dm`，由适配顶层连接 core2 的内部命名。两种接口分别展开验证。 `.dgm` 用于 GUI 显示。

## 在临时库构建与验证

假设 `$stage` 下已有 `package/demo/top/invert_demo.v`，并在 `$stage` 准备好 XML、`head.v` 与 `out`。在源包父目录调用 `hqencrypt`。FT111226 的 `-id` 只接目录名。

```powershell
Push-Location "$stage/package"
try {
    & "$creator/hqencrypt.exe" -id demo -np 1 -o "$stage/demo.enc"
    if ($LASTEXITCODE -ne 0) { throw 'IP source packaging failed' }
} finally {
    Pop-Location
}

$xml = "$stage/demo.xml"
$hqip = "$stage/out/demo.hqip"
$hqExe = Join-Path $root 'build/win_x64/bin/hqfpga.exe'
$part = 'SK7Z-80-D1-8U100CI'
$env:PROJ_DEVICE = $part
$env:IP_DEVICE = $part
@"
[General]
LOGIC.INVERT=1
[File]
output_module=demo_out
[IP]
device=$part
meta_file=$($xml.Replace('\', '/'))
"@ | Set-Content -Encoding utf8NoBOM $hqip
& "$creator/ipcr_chkmeta.exe" $xml -ini $hqip -lang eng
if ($LASTEXITCODE -ne 0) { throw 'IP configuration invalid' }
& "$creator/ipgen_hdl_ip.exe" -meta_xml $xml -ini_file $hqip -hq_exe $hqExe -lang eng
if ($LASTEXITCODE -ne 0) { throw 'IP generation failed' }
Get-Item -LiteralPath "$stage/out/demo.v"
```

`$root` 和 `$creator` 的获取见 [配置与生成](generate.md)。先准备指向临时 XML 的 `.hqip`，检查每步退出码和新文件。 `-np 1` 用于本地自有 RTL 的开发源包。通用后端按器件综合 wrapper，映射时使用 `-no_ioins`，导出网表，按配置加密并整理产物。遇到 HDL 综合故障时可加 `-debug`，从日志找到保留的临时目录，检查 `.rtlsyn.tcl`、`.rtlsyn.log`、`.wrapper.v` 和源文件。报错后残留的输出文件可能只有文件头。

至少验证默认与一个非默认参数组合、条件端口、顶层参数映射、网表的最小展开或功能。随后把整套文件放到选定版本的 ipdepot 对应目录，更新实例的 `meta_file`，从真实入口重生成。涉及 GUI 安装时确认设备筛选、分类与中文显示。保持专用生成器自身的产物契约。

FT111226 实测以 Shark 80K 生成 EBR，也用上述通用 HDL 后端对自有反相器做了两组参数生成。两份输出分别实现直通和反相，验证了 XML 完整键到 RTL 参数的映射。
