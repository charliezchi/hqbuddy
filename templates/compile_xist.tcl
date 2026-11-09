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
# 4. 脚本会自动修改 Modelsim/QuestaSim 根目录的 modelsim.ini 中的 XiST_* 映射
# ===================================================================================

# ===================================================================================
# Description     : 自动编译智多晶 Modelsim/QuestaSim 仿真库
#
# Author          : ZhangChi
# Created On      : 2026/8/7
# Revision        : 1.6.beta
#
# Revision History:
#   1.0.beta (2026/1/8)  ZhangChi
#       - 初始版本，支持 seal/sealion 目录下 .v 文件自动编译
#   1.1.beta (2026/6/4)  ZhangChi
#       - 修复库存在性检查逻辑：原 `lsearch -exact [vmap] $lib_name` 因 vmap 返回
#         格式化文本而非 Tcl 列表，导致匹配失败并触发 ONERROR 退出。
#         改用 `catch {vmap $lib_name}` 查询特定库，通过返回码判断库是否存在。
#       - 更新使用方法
#   1.2.beta (2026/6/17)  ZhangChi
#       - 缺失源目录时改为跳过而非退出，提升兼容性
#   1.3.beta (2026/6/17)  ZhangChi
#       - 支持 ModelSim 和 QuestaSim
#       - 编译完成后自动更新 modelsim.ini 中的 XiST 映射
#   1.4.beta (2026/8/6)  ZhangChi
#       - 编译源文件类型扩展为 .v / .vp
#   1.5.beta (2026/8/7)  ZhangChi
#       - 增加 +define+SIM 宏定义，加速 DDRCTRL 仿真
#   1.6.beta (2026/11/10) ZhangChi
#       - 各器件家族独立编库：XiST_SEAL / XiST_SEALION / XiST_SHARK
#       - 修复家族间同名异内容模块（如 xsLUT4）在同一库中互相覆盖的问题
#       - 旧的单库 XiST 映射自动清除（旧库目录保留在磁盘上，可手动删除）
#   1.7.beta (2026/11/10) ZhangChi
#       - seal/shark 家族库补编 sealion 目录的公共 UDT 原语（xsDFF_K* 等——
#         seal 仿真目录只有 xsDFFSA_* 变体，缺公共模型会导致网表仿真缺模块）
#       - 编译顺序：公共（sealion）在前、家族目录在后，同名模块家族版生效
#   1.8.beta (2026/11/10) ZhangChi
#       - 单文件编译失败不再中断整库（如 shark xsMIPI_CTRL.v 含 SystemVerilog
#         语法，按 .v 编译报错）——逐文件 catch，失败自动以 -sv 重试，仍失败
#         才跳过并汇总计数
# ===================================================================================

# -----------------------------
# 0. 出错即退出
# -----------------------------
onerror {quit -f}

# -----------------------------
# 1. 基本参数：家族目录 -> 库名（XiST_<大写家族名>）
# -----------------------------
set families {seal sealion shark}

# sealion 目录除器件模型外还承载公共 UDT 原语（如 xsDFF_K1C1E1），seal/shark
# 目录只放家族特调模型（如 xsDFFSA_*、部分 xsLUT4 变体）。因此 seal/shark 家族库
# 先编 sealion（公共），再编家族目录——同名模块后者生效，器件用自家模型。
set compile_order(seal) {sealion seal}
set compile_order(sealion) {sealion}
set compile_order(shark) {sealion shark}

# 脚本所在目录（XIST）
set xist_dir [pwd]

# -----------------------------
# 2. 切换到 ModelSim/QuestaSim 安装根目录
# -----------------------------
set ms_root [file dirname [file dirname [info nameofexecutable]]]
cd $ms_root
puts "Switched to ModelSim/QuestaSim root: $ms_root"

# -----------------------------
# 3. 清除旧的单库 XiST 映射（1.5 及以前的做法，已被家族分库取代）
# -----------------------------
set legacy_exists [catch {vmap XiST} legacy_msg]
if {$legacy_exists == 0} {
    puts "Legacy library XiST found, unmapping (old lib dir kept on disk)..."
    catch { vmap -del XiST }
}

# -----------------------------
# 4. 逐家族：存在则删除重建，创建并编译
# -----------------------------
set failed_count 0
foreach dir $families {
    set lib_name "XiST_[string toupper $dir]"
    set abs_dir [file join $xist_dir $dir]

    if {![file isdirectory $abs_dir]} {
        puts "WARNING: source directory not found, skip family: $abs_dir"
        continue
    }

    set lib_exists [catch {vmap $lib_name} vmap_msg]
    if {$lib_exists == 0} {
        puts "Library $lib_name exists, deleting..."
        catch { vmap -del $lib_name }
        catch { vdel -all -lib $lib_name }
    } else {
        puts "Library $lib_name does not exist yet."
    }

    puts "Creating library $lib_name"
    vlib $lib_name
    vmap $lib_name $lib_name

    foreach cdir $compile_order($dir) {
        set abs_dir [file join $xist_dir $cdir]

        if {![file isdirectory $abs_dir]} {
            puts "WARNING: source directory not found, skip: $abs_dir"
            continue
        }

        puts "Compiling directory: $abs_dir"

        set vfiles [glob -nocomplain "$abs_dir/*.v" "$abs_dir/*.vp"]

        if {[llength $vfiles] == 0} {
            puts "WARNING: no .v/.vp files found in $abs_dir"
        }

        foreach vfile $vfiles {
            puts "  vlog $vfile"
            if {[catch {vlog +define+SIM -work $lib_name $vfile} err]} {
                # FT110526 起部分模型（如 shark xsMIPI_CTRL.v）含 SystemVerilog
                # 语法，按 .v 编译报错时改用 -sv 重试
                if {[catch {vlog +define+SIM -sv -work $lib_name $vfile} err2]} {
                    puts "  WARNING: compile failed (also tried -sv), file skipped: $vfile"
                    puts "    $err2"
                    incr failed_count
                } else {
                    puts "  compiled with -sv (SystemVerilog syntax)"
                }
            }
        }
    }
}

if {$failed_count > 0} {
    puts "WARNING: $failed_count file(s) failed to compile and were skipped."
}

puts "XiST family libraries compilation completed (XiST_SEAL / XiST_SEALION / XiST_SHARK)."

# -----------------------------
# 5. 更新 modelsim.ini 中的 XiST_* 映射
# -----------------------------
set ini_path [file join $ms_root "modelsim.ini"]

if {![file exists $ini_path]} {
    puts "WARNING: modelsim.ini not found at $ini_path"
    puts "Please add the following lines manually:"
    puts "  XiST_SEAL = \$MODEL_TECH/../XiST_SEAL"
    puts "  XiST_SEALION = \$MODEL_TECH/../XiST_SEALION"
    puts "  XiST_SHARK = \$MODEL_TECH/../XiST_SHARK"
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
            puts "  XiST_SEAL = \$MODEL_TECH/../XiST_SEAL"
            puts "  XiST_SEALION = \$MODEL_TECH/../XiST_SEALION"
            puts "  XiST_SHARK = \$MODEL_TECH/../XiST_SHARK"
        } else {
            set in_fp [open $ini_path r]
            set content [read $in_fp]
            close $in_fp

            # 移除旧的单库 XiST 映射（如存在）
            set content [regsub -line {^XiST\s*=.*$\n?} $content ""]

            # 逐家族：已存在则替换，否则插入 [Library] 节头之后
            foreach dir $families {
                set lib_name "XiST_[string toupper $dir]"
                set mapping "$lib_name = \$MODEL_TECH/../$lib_name"

                if {[regexp -line "^$lib_name\\s*=.*\$" $content]} {
                    set content [regsub -line "^$lib_name\\s*=.*\$" $content $mapping]
                    puts "Updated modelsim.ini: $mapping"
                } elseif {[regexp -line {^\[Library\]\s*$} $content]} {
                    set content [regsub -line {^\[Library\]\s*$} $content "\[Library\]\n$mapping"]
                    puts "Updated modelsim.ini: $mapping"
                } else {
                    # 无 [Library] 节：追加到文件末尾（只在第一个家族时补节头）
                    if {$dir eq "seal"} {
                        set in_fp [open $ini_path a]
                        puts $in_fp ""
                        puts $in_fp "\[Library\]"
                        puts $in_fp $mapping
                        close $in_fp
                        set in_fp [open $ini_path r]
                        set content [read $in_fp]
                        close $in_fp
                    } else {
                        set in_fp [open $ini_path a]
                        puts $in_fp $mapping
                        close $in_fp
                    }
                    puts "Updated modelsim.ini: $mapping"
                }
            }

            set in_fp [open $ini_path w]
            puts -nonewline $in_fp $content
            close $in_fp
        }
    }
}

# -----------------------------
# 6. 批处理模式退出
# -----------------------------
quit
