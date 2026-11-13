# 已有 IP 的配置与生成

## 无界面生成

在预期输出目录或临时工作目录中执行。以 FT111226 的 Shark 单口 EBR 为例：

```powershell
$root = (hqbuddy -root | Select-Object -Last 1).Trim()
$creator = Join-Path $root 'build/ipcreator'
$part = 'SK7Z-80-D1-8U100CI'
$xml = Join-Path $creator 'sup_files/ipdepot/ebr_shark/ebr_sp/ebr_sp.xml'
hqbuddy -gen_hqip $xml -device $part
$hqip = (Resolve-Path 'ipcore_dir/EBR_SP/xsIP_EBR_SP.hqip').Path
$env:PROJ_DEVICE = $part
$env:IP_DEVICE = $part
& "$creator/ipcr_chkmeta.exe" $xml -ini $hqip -lang eng
hqbuddy -ipgen $hqip -lang eng
```

逐步检查退出码。器件优先取目标工程的 `hqbuddy -get_device <工程.hqprj>`。也可用 `-gen_hqip --ip <唯一名称前缀> -device <料号>`，变体重名时给明确 XML 路径。安装的 hqbuddy 选项以实际版本为准。 `-gen_hqip` 会写默认文件，用临时工作目录生成新配置可避免覆盖已有定制实例。上述环境变量用于依赖器件条件的检查，建议在本次任务的子 shell 内设置。

`-gen_hqip` 生成的是起点，`--set group.key=value` 覆盖键值，随后由 IP Creator 检查器做完整校验。保存并重用同一份实例的 `.hqip` 时直接编辑目标键，再重新检查。

| 区段 | 内容 |
|---|---|
| `[General]` | XML 中的完整层级键，例如 `GROUP.KEY`。保留同名 `.ii` 带入的内部配置 |
| `[File]` | `output_module` 为生成模块名。通用 Python 后端读取可选的 `output_file`，未提供时取 `.hqip` 同名 `.v` |
| `[IP]` | `device` 为完整器件料号，`meta_file` 指向对应变体 XML |

按 `active_cond`、`<values><cond>`、`range` 和规则检查组合。布尔值遵循该 IP 的原有序列化形式，常见为 `TRUE/FALSE`。检查器警告某值被忽略时，先区分预期的禁用项／内部键与用户要求生效的参数。可加 `-vo <单独的 stub.v>` 检查接口，实际产物另由生成器写出。

## 按描述文件选择后端

读 XML 同目录的 `_ipgen_.desc`。普通后端用 `[IPGEN] EXE`，相对路径从 XML 目录解析，`<ROOT>` 指 IP Creator 目录。 `HQFPGA=YES` 时传同版本 HqFpga 的绝对路径。普通调用契约：

```powershell
& $generator -meta_xml $xml -ini_file $hqip -lang eng
# 按描述文件追加 -hq_exe $hqExe 或 -opts <OPTS 中的各参数>
```

- **普通、无额外参数**：用 `hqbuddy -ipgen <实例.hqip>`。它从 `meta_file` 截取 `/build/` 后的路径，映射到当前 HqFpga 安装，并以实例目录为子进程工作目录。临时库 XML 或外部 XML 用上面的直接调用。
- **普通、有 `OPTS`**：`ipcreator.exe -gen <实例.hqip> -lang eng -hq_exe <路径>` 会按描述转发 `-opts`，也可直接调用后端并传入。源码版 hqbuddy 3.46.2 的 `-ipgen` 不转发 `OPTS`。
- **`INDEPENDENT=YES`**：用 `ipcreator.exe -gen <实例.hqip> -lang eng`，按需加 `-hq_exe`。它调用 `INDEPENDENT_EXE -gen <实例.hqip>` 并转发 `INDEPENDENT_EXE_OPTS`。首次配置用其 GUI 或后端支持的专用入口获取原生配置，再走重生成。直接使用独立程序时以其参数和产物约定为准。
- IP Creator 的普通 `gen_ip()` 还会根据 XML 生成适用的实例模板。hqbuddy 直接执行后端，附件是否产出由该后端决定。检查实际输出和日志，必要时从原生入口生成。

检查新文件的模块名、端口方向／位宽、所需约束、初始化文件、仿真文件。按任务需要用生成文件做最小展开或仿真。涉及工程集成时，用实际生成的 HDL 和配套约束加入项目。

## 排查顺序

- 找不到 XML 或 EXE：核对选定版本、XML 变体路径和 `_ipgen_.desc`。预览 XML 有元数据时即可显示，生成还需要描述文件、后端及其依赖。
- 目标器件或值无效：核对 `[IP] device` 和 XML 的 `<devices>`、条件分支及有效值。用已知合法的配置对照生成。
- 进程结束但文件缺失：对照 `[File]`、工作目录、后端日志以及临时综合目录。用独立输出路径避免把上次结果当成本次产物。原生 `-gen` 失败时可能清理同名输出，重生成前保留需要的现有产物。

源码定位：`ipcreator.py::auto_genip`，`upkgs/ipgen_common.py::{redirect_mxml,resolve_ipgen_exe,gen_ip,gen_ip_independent}`，`ipcr_chkmeta.py`。hqbuddy 入口见 `hqbuddy/hqip_gen.py` 和 `hqbuddy/ipgen.py`。
