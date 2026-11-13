---
name: ipcreator
description: Generate and regenerate XiST HqFpga IP from meta XML and .hqip, or package owned RTL as a new IP Creator catalog entry. Use for IP Creator XML syntax and special settings, hqbuddy -gen_hqip and -ipgen, _ipgen_.desc, SYS_PARAMS, ipgen_hdl_ip, and debugging configuration, wrapper, or generator failures.
---

# HqFpga IP Creator

先确定目标器件、HqFpga 版本和模块名。用 `hqbuddy -root` 找当前版本，IP Creator 位于该目录的 `build/ipcreator`，库位于其 `sup_files/ipdepot`。同一次生成使用该版本的 XML、后端和 HqFpga。

- **生成或修改已有 IP**：按 [已有 IP 的配置与生成](references/generate.md) 选择元数据、写入 `.hqip`、校验并生成。优先用 hqbuddy 的非交互入口。有独立生成器或额外后端参数时按描述文件使用原生入口。
- **把自有 RTL 做成可生成的库 IP**：按 [通用 HDL IP 封装](references/package.md) 建 XML、参数与端口契约、源包和后端描述。先在临时目录验证，再安装到目标库。
- **开发或移植 IP 界面**：按 [界面开发流程与目录结构](references/ui-development.md) 准备库目录、分类、XML、中文和框图，并验证真实库入口。
- **编写或修改 XML**：查 [meta XML 语法与特殊设置](references/meta-xml.md)，核对值类型、条件、端口、规则、隐藏项和生成器保留配置。用目标版本的 `ipcr_chkmeta` 校验，`-vo` 输出用于核对模块和端口。

枚举的 `<value>` 文本是传参值，`desc` 及 `trans_lang.chs` 控制显示。每次正式生成检查新产物、模块名和有效端口。新封装还要用至少一个非默认配置确认 RTL 行为随配置改变。
