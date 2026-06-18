# ===================================================================================
#                          COPYRIGHT NOTICE
# Copyright (c) 2025       XI'AN Intelligence Silicon Tech Co. Ltd.
# ALL RIGHTS RESERVED
# This confidential and proprietary software may be used only as authorized
# by a licensing agreement from XI'AN Intelligence Silicon Tech Co. Ltd. The entire
# notice above must be reproduced on all authorized copies and copies may
# only be made to the extent permitted by a licensing agreement from
# XI'AN Intelligence Silicon Tech Co. Ltd.
#
# XI'AN Intelligence Silicon Tech Co. Ltd.      TEL : +86-29-88860013
# XI'AN Software Park, XI'AN China              email: xist@isilicontek.com
# ZIP CODE 710075                               web  : http://www.xisilicontek.com
# ===================================================================================

# ===================================================================================
# 使用方法：
# 0. 确认 Modelsim/QuestaSim 根目录的 modelsim.ini 不是只读文件
# 1. 将 compile_xist.tcl 复制到 %HQ%\build\common\sim\verilog\XIST 文件夹下
# 2. 在 XIST 文件夹下打开终端，推荐使用 PowerShell
# 3. 命令行运行 vsim -c -do .\compile_xist.tcl
# 4. 脚本会自动修改 Modelsim/QuestaSim 根目录的 modelsim.ini 中的 XiST 映射
# ===================================================================================

# ===================================================================================
# Description     : 自动编译智多晶 Modelsim/QuestaSim 仿真库
#                    
# Author          : ZhangChi
# Created On      : 2026/6/4
# Revision        : 1.3.beta
#
# Revision History:
#   1.0.beta (2026/1/8)  ZhangChi
#       - 初始版本，支持 seal/sealion 目录下 .v 文件自动编译
#   1.1.beta (2026/6/4)  ZhangChi
#       - 修复库存在性检查逻辑：原 `lsearch -exact [vmap] $lib_name` 因 vmap 返回
#         格式化文本而非 Tcl 列表，导致匹配失败并触发 ONERROR 退出。
#         改用 `catch {vmap $lib_name}` 查询特定库，通过返回码判断库是否存在。
#       - 更新使用方法
#   1.2.beta (2026/6/17)  HqBuddy
#       - 增加 shark 目录支持
#       - 缺失源目录时改为跳过而非退出，提升兼容性
#   1.3.beta (2026/6/17)  HqBuddy
#       - 支持 ModelSim 和 QuestaSim
#       - 编译完成后自动更新 modelsim.ini 中的 XiST 映射
# ===================================================================================

# -----------------------------
# 0. 出错即退出
# -----------------------------
onerror {quit -f}

# -----------------------------
# 1. 基本参数
# -----------------------------
set lib_name XiST

# 脚本所在目录（XIST）
set xist_dir [pwd]

# 需要编译的子目录
set src_dirs {
    seal
    sealion
    shark
}

# -----------------------------
# 2. 切换到 ModelSim/QuestaSim 安装根目录
# -----------------------------
set ms_root [file dirname [file dirname [info nameofexecutable]]]
cd $ms_root
puts "Switched to ModelSim/QuestaSim root: $ms_root"

# -----------------------------
# 3. 如果 XiST 已存在，删除
# -----------------------------
set lib_exists [catch {vmap $lib_name} vmap_msg]
if {$lib_exists == 0} {
    puts "Library $lib_name exists, deleting..."
    catch { vmap -del $lib_name }
    catch { vdel -all -lib $lib_name }
} else {
    puts "Library $lib_name does not exist yet."
}

# -----------------------------
# 4. 创建并映射 XiST 库
# -----------------------------
puts "Creating library $lib_name"
vlib $lib_name
vmap $lib_name $lib_name

# -----------------------------
# 5. 编译 seal / sealion / shark 下所有 .v
# -----------------------------
foreach dir $src_dirs {
    set abs_dir [file join $xist_dir $dir]

    if {![file isdirectory $abs_dir]} {
        puts "WARNING: source directory not found: $abs_dir"
        continue
    }

    puts "Compiling directory: $abs_dir"

    set vfiles [glob -nocomplain "$abs_dir/*.v"]

    if {[llength $vfiles] == 0} {
        puts "WARNING: no .v files found in $abs_dir"
    }

    foreach vfile $vfiles {
        puts "  vlog $vfile"
        vlog -work $lib_name $vfile
    }
}

puts "XiST library compilation completed."

# -----------------------------
# 6. 更新 modelsim.ini 中的 XiST 映射
# -----------------------------
set ini_path [file join $ms_root "modelsim.ini"]

if {![file exists $ini_path]} {
    puts "WARNING: modelsim.ini not found at $ini_path"
    puts "Please add the following line manually:"
    puts "  XiST = \$MODEL_TECH/../XiST"
} else {
    # Check if file is read-only on Windows
    if {$tcl_platform(platform) == "windows"} {
        set attrs [file attributes $ini_path]
        set is_readonly 0
        foreach attr $attrs {
            if {[lindex $attr 0] == "-readonly" && [lindex $attr 1] == 1} {
                set is_readonly 1
                break
            }
        }
        if {$is_readonly} {
            puts "WARNING: modelsim.ini is read-only: $ini_path"
            puts "Please remove the read-only attribute and re-run, or add manually:"
            puts "  XiST = \$MODEL_TECH/../XiST"
        } else {
            set in_fp [open $ini_path r]
            set content [read $in_fp]
            close $in_fp

            # Replace existing XiST mapping or append to [Library] section
            if {[regexp -line {^XiST\s*=.*$} $content]} {
                set new_content [regsub -line {^XiST\s*=.*$} $content "XiST = \$MODEL_TECH/../XiST"]
                set in_fp [open $ini_path w]
                puts -nonewline $in_fp $new_content
                close $in_fp
                puts "Updated modelsim.ini: XiST = \$MODEL_TECH/../XiST"
            } else {
                # Append after [Library] section header
                if {[regexp -line {^\[Library\]\s*$} $content]} {
                    set new_content [regsub -line {^\[Library\]\s*$} $content "\[Library\]\nXiST = \$MODEL_TECH/../XiST"]
                    set in_fp [open $ini_path w]
                    puts -nonewline $in_fp $new_content
                    close $in_fp
                    puts "Updated modelsim.ini: XiST = \$MODEL_TECH/../XiST"
                } else {
                    # Append at the end
                    set in_fp [open $ini_path a]
                    puts $in_fp ""
                    puts $in_fp "[Library]"
                    puts $in_fp "XiST = \$MODEL_TECH/../XiST"
                    close $in_fp
                    puts "Updated modelsim.ini: XiST = \$MODEL_TECH/../XiST"
                }
            }
        }
    }
}

# -----------------------------
# 7. 批处理模式退出
# -----------------------------
quit
