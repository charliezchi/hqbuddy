# 通用 HDL 后端的 .enc 源包

## 组织输入

以 `demo.xml` 为例，构建目录与库目录分开：

```text
stage/
├── package/                         打包命令的工作目录
│   └── demo/                        归档内根目录，等于 XML 文件基名
│       ├── top/
│       │   └── demo_top.v           顶层文件，模块名也为 demo_top
│       └── rtl/
│           ├── child.v              独立综合源
│           └── sub/
│               └── helper.vh         按 RTL 的实际引用放置头文件
└── variant/                         将整套文件发布到选定库
    ├── demo.xml
    ├── demo.enc                     hqencrypt 的输出
    ├── _ipgen_.desc
    ├── head.v
    └── opt.tcl                      多文件示例的综合源清单
```

在 XML 中把 `Functional_Selection` 的缺省值或活动值设为 `demo_top`。后端在 `demo/top/` 中按文件基名选择，建议显式指定。多个功能模式时，每个模式的顶层文件和同名模块都放在该目录。避免一个基名对应多个文件。子模块、头文件和综合期使用的文本资源可以放在各自子目录。打包器递归收集输入文件，使用干净的 staging 树，只放实际要分发的源文件和资源。源码打包流程以文本读取文件，使用 UTF-8，二进制资源通过后端明确支持的交付机制另行提供。

后端解包后只自动将生成的 wrapper 和选中的顶层源加入 `vlog_files`。单独编译的子模块要由同目录 `opt.tcl` 加入：

```tcl
lappend vlog_files src/demo/rtl/child.v
```

这里的 `src/` 是后端临时工作目录下的解包位置。头文件要通过实际的 include 路径可达，初始化文本也要按综合时的工作目录解析。已通过 include 纳入的模块保持单一入口。存在多个功能模式时，源清单可按实际依赖组织，分别生成各模式验证。

## 打包与回读

```powershell
$root = (hqbuddy -root | Select-Object -Last 1).Trim()
$pack = Join-Path $root 'build/ipcreator/hqencrypt.exe'
# $stage 为上述 stage 的绝对路径，variant 目录已创建
Push-Location "$stage/package"
try {
    & $pack -id demo -np 1 -o "$stage/variant/demo.enc"
    if ($LASTEXITCODE -ne 0) { throw 'IP source packaging failed' }
} finally {
    Pop-Location
}
& $pack -f "$stage/variant/demo.enc" -od "$stage/unpacked"
if ($LASTEXITCODE -ne 0) { throw 'IP source unpack failed' }
Get-ChildItem "$stage/unpacked/demo" -Recurse -File
```

FT111226 的 `-id` 接受当前目录下的单个目录名。 `-np 1` 适用于自有 RTL 的开发源包，关闭打包阶段的源文件 AES 保护。发布需要源文件保护时，使用授权的工具和密钥配置核对 `-np 0` 的打包路径。最终网表的加密由生成器另行处理。校验解包后的文件清单与内容，文本换行可由打包器规范化。随后按 [通用 HDL IP 封装](package.md) 用真实目标器件生成网表。

FT111226 实测用 `-np 1` 打包并回读了顶层、独立子模块、根目录和嵌套目录的文本资源。使用 `opt.tcl` 加入独立子模块后，日志确认该文件参与综合，产物实现了子模块的反相逻辑。
