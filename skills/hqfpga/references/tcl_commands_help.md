# HqFPGA TCL 命令全量 help 实测（hqv3_xist 3.1.1，Build FT082926，2026-09-02）

> 由 `foreach c [lsort [info commands]] { help $c }` 在 hqfpga TCL 交互中自动 dump，
> 共 **1055** 个命令：TCL 内建 91 个、应用命令 964 个（公开 742 + 内部隐藏 222，隐藏命令名以 `'` 开头，手册一律不载）。

> **查询任何命令语法**：`hqbuddy -cmd -e "help <命令名>" -q`，或交互式 `hqfpga -cmd` 中 `help <命令名>`。

> 手册蒸馏的分类地图见 commands.md；本文件是超集（含全部隐藏命令），按 Ctrl+F 查命令名即可。

## 应用命令分组索引（公开命令，按前缀）

| 前缀 | 数量 | 说明 |
|---|---|---|
| `(无前缀).` | 192 |  |
| `insight.` | 51 | HqInsight 在线逻辑分析仪/调试 |
| `nl.` | 48 | 网表（netlist）处理与优化 |
| `impl.` | 40 | 实现流程（pack/place/route/bitgen 及各器件变体） |
| `lo.` | 30 | 逻辑优化（logic optimization） |
| `obj.` | 30 | UDM 对象操控（U 命令，见 udm.md） |
| `lpp.` | 28 | 布局规划/物理综合（logic-planning） |
| `rtl.` | 25 | RTL 综合（analyze/elaborate/set 等） |
| `pl.` | 23 | 布局（place）与时钟 |
| `design.` | 22 | design.* 流程封装命令（见 cmd-design.md） |
| `udev.` | 21 | 器件结构/管脚/库查询（device） |
| `phycst.` | 20 | 物理约束（physical constraint） |
| `dv.` | 19 | 器件设置与查询（device setup） |
| `ioh.` | 15 | IO 属性查询与设置 |
| `eco.` | 14 | ECO 在线修改 |
| `ta.` | 10 | 时序分析（timing analysis） |
| `rt.` | 9 | 布线/延迟/拥塞报告（route） |
| `tarc.` | 8 | 时序 arc/derating 管理 |
| `macro.` | 7 | 宏/模块flatten/rebuild |
| `test.` | 7 |  |
| `vla.` | 5 | VLA 调试器 |
| `dsgn.` | 4 | design.* 的旧别名（rsyn/map/lo） |
| `msg.` | 4 | 消息系统控制 |
| `opcond.` | 4 | 工作条件（operating conditions） |
| `sdc.` | 4 | SDC 约束读写 |
| `tc.` | 4 | 时序约束（time constraint） |
| `vio.` | 4 | VIO 虚拟 IO |
| `xdl.` | 4 | XDL 数据读写 |
| `cfgxdata.` | 3 | 配置型 Xdata |
| `info.` | 3 |  |
| `logfile.` | 3 | 日志控制 |
| `npl.` | 3 | (少量公开) 布局规划内部命令 |
| `postsyn.` | 3 | 综合后面积优化选项 |
| `xdata.` | 3 | Xdata 规范化/删除 |
| `abc.` | 2 | ABC 逻辑优化引擎 |
| `clkrgn.` | 2 | 时钟区域偏斜 |
| `dconv.` | 2 | 数据转换（xpn2chipedit 等） |
| `drc.` | 2 | 设计规则检查 |
| `edif.` | 2 | EDIF 读写 |
| `flowcfg.` | 2 | 流程算法配置 |
| `fsm.` | 2 | FSM 优化 |
| `hqvars.` | 2 |  |
| `lang.` | 2 |  |
| `le.` | 2 |  |
| `lglz.` | 2 |  |
| `phyrule.` | 2 | 物理规则 |
| `pip.` | 2 |  |
| `preopt.` | 2 |  |
| `res.` | 2 |  |
| `sdb.` | 2 |  |
| `srchpath.` | 2 | 文件搜索路径 |
| `topview.` | 2 |  |
| `trpt.` | 2 |  |
| `ucmd.` | 2 |  |
| `upc.` | 2 |  |
| `xpn.` | 2 | XPN 网表读写 |
| `bank.` | 1 |  |
| `bs.` | 1 | bitstream 读取 |
| `ctrlsigs.` | 1 |  |
| `ddrc.` | 1 |  |
| `fault.` | 1 |  |
| `get.` | 1 |  |
| `gui.` | 1 |  |
| `hinfo.` | 1 |  |
| `hqfpga.` | 1 |  |
| `inst.` | 1 |  |
| `lb.` | 1 |  |
| `license.` | 1 |  |
| `loset.` | 1 |  |
| `netlist.` | 1 |  |
| `normxdata.` | 1 |  |
| `nview.` | 1 |  |
| `nvlg.` | 1 |  |
| `outdir.` | 1 |  |
| `pin.` | 1 |  |
| `predefined.` | 1 |  |
| `root.` | 1 |  |
| `sdf.` | 1 |  |
| `spc.` | 1 |  |
| `taset.` | 1 |  |
| `timing.` | 1 |  |
| `ucf.` | 1 |  |
| `udb.` | 1 |  |
| `xsdc.` | 1 |  |

## 无前缀的应用命令

`EvalAccept` `EvalConn` `EvalOpenProc` `EvalQuery` `EvalRead` `Eval_Server` `TstQueryConn` `addPid` `add_uns_line` `all_clocks` `all_inputs` `all_outputs` `autoDetectTopModule` `bgerror` `cd_hqorg` `check_netlist_null` `check_operation_applicable` `chkAbsPath` `chkRelativePath` `chk_comon_path` `chk_hqui_var` `chk_insight_dbgr_stat` `chk_insight_impl_stat` `chk_insight_instru_stat` `chk_keep_hier` `chk_restore_100k_drt` `chk_set_100k_drt` `chkrun_step_debug_script` `chkset_drt_from_hqvar` `clear_design` `clear_step_debug_script` `conv_sl2_eco_pcst` `create_clock` `create_generated_clock` `csv2upc` `deleteUdm` `derive_generated_clocks` `designImportExec` `diff_hqprj_hqins_file` `dir` `examine_hqins_gen_files` `examine_hqvio_gen_files` `exec4globalSet` `execImportGlobalSet` `extr_bitdata` `extr_wns` `file_is_newer` `generateRpt` `getTopModuleName` `get_bitcontent_sizes` `get_cells` `get_clocks` `get_curr_hqprj_abspath` `get_curr_hqprj_file` `get_dot_hqins_file` `get_dot_hqins_save_file` `get_effort` `get_file_upd_stat` `get_hqexe_for_ins` `get_hqins_chkok_file` `get_hqprj_save_file` `get_hqui_vlog_inc_paths` `get_multi_inst_nviews` `get_nets` `get_norm_time_th` `get_obj_loc` `get_os_info` `get_pin_external_loc_from_internal` `get_pin_internal_loc_from_external` `get_pins` `get_ports` `get_wns_stat_msgid` `get_xist_device_id` `help` `hqBitgenExec` `hqPackExec` `hqPlaceExec` `hqRouteExec` `hqRtlSysExec` `hqprj2tcl` `hqui_doJob` `hqui_get_dev_name` `hqui_jobReader` `hqui_print` `isDummyTopmName` `is_demo_dev` `is_hier_kept` `is_hq_gen_nview` `is_proj_open` `is_running_lpp_flow` `is_sk7_slice_trans_flow` `is_valid_num` `iseBitgen` `iter_basic_logic_reduce` `lassign` `ldelete` `loadConstraint` `loadPhysicalConstraint` `loadTimingConstraint` `loadUdm` `ls` `mpi_route` `mpimem` `msg` `norm_xdata.info` `outputFirstStageRptsCpFromV3` `outputSecondStageRptsCpFromV3` `output_hq_setting` `pin2csv` `pkg_mkIndex` `post_set_xise` `prep_options` `prep_set_xise` `prep_wns_value` `progBit` `put_cmd_banner` `queryTopModule` `quiet_run` `readEdifExec` `readOpt` `readPrjOpt` `refine_fmt` `removePid` `remove_pksi_seal` `report_timing_derate` `reset_timing_derate` `resolve_bitfile_names` `resolve_hqprj2ins_file_dirs` `resolve_hqprj2vio_file_dirs` `resolve_only_bit_file_name` `restore_timing_derate` `resyn` `rptXCVtiming` `rtl_loc_to_phy` `runChipEdit` `runDesignExplorer` `runHqInsDbgr` `runHqInsImpl` `runHqInstrumentor` `runIpCreator` `runNlViewer` `runProg` `runRtHeatmapViewer` `runVioDebugger` `runVlaDebugger` `run__hq__dynamic_ucmd__0` `run_hqprj2hqins_flow` `run_hqprj2hqvio_flow` `run_hqprj_flow` `sa5tosk7_trans_xpn` `saveUdm` `save_timing_derate` `set_clock_groups` `set_clock_latency` `set_clock_uncertainty` `set_false_path` `set_hierarchy_separator` `set_input_delay` `set_max_delay` `set_min_delay` `set_multicycle_path` `set_output_delay` `set_propagated_clock` `set_timing_derate` `showcmd` `svf_post_process` `tailcall` `tclLog` `tclPkgSetup` `tclPkgUnknown` `throw` `trans_lo_args` `trans_rsyn_args` `try` `ucf2upc` `udtBitGen` `unload` `unset_glbl_vars` `updAllRtlSrcFileList` `updModuleList` `wrap_cmd` `writeDesignImportClkReport` `writeRouteClkReport` `writeXstPrj` `writeXstXst` `write_Kill_List` `xist_bit2burstsvf` `xist_bit2svf` `xstRtlSysExec` `yield` `yieldto` `zlib`

## 隐藏命令（' 前缀，内部使用，谨慎调用）

`'abc.lutpack` `'abc.show` `'abc.speedup` `'array.add_ip_row` `'array.add_tile` `'array.dump` `'array.dumpbfd` `'array.get_tile` `'array.init` `'array.reset` `'array.set_tile` `'bfd.addmib` `'bfd.apply_node` `'bfd.applyeqn` `'bfd.applymib` `'bfd.assigneqn` `'bfd.changemem` `'bfd.delmib` `'bfd.dump` `'bfd.dumpbfd` `'bfd.gendsp` `'bfd.load` `'bfd.movemib` `'bfd.newtile` `'bfd.row_resize` `'blif.read` `'blif.write` `'check.msg.match` `'cktgen` `'cktop` `'cktopoh` `'delay.set` `'dsgn.clear` `'dv.prep` `'dv.test` `'ebr.report` `'eco.mindly` `'eco.pin_offset` `'eco.report_reused_cib` `'eco.rpt_conn` `'expr.cmd` `'exprcmd3` `'hierxdata.set` `'hwminx.sig1` `'hwminx.sig2` `'impl.bitgen.analyzepiptestresult` `'impl.bitgen.testpip` `'impl.bitgen.testpiplist` `'impl.fixopenup` `'impl.lut_pack` `'impl.packlc` `'insight.urjtag` `'ip.inst.mark` `'lic.add` `'lic.check` `'lic.end` `'lic.info` `'lic.start` `'lo.cntlit` `'lo.cubext2` `'lo.decomp` `'lo.eliminate` `'lo.findxor` `'lo.kernelext2` `'lo.mffc` `'lo.resub` `'lo.swallow` `'lo.tdo` `'lo.ws` `'lpp.bpl.pio2iol` `'lpp.clk_diff` `'lpp.dump_clk_txt` `'lpp.merge_const` `'lpp.sloc_to_pcloc` `'map.rpt` `'misc.buryBomb` `'misc.cfg2graph` `'misc.dumpNetlistData` `'misc.getBombString` `'misc.svg2xml` `'msg.group.op` `'msg.puts` `'my.cmd` `'nl.chkclk` `'nl.chkff` `'nl.lscombunify` `'nl.prof.sl2` `'nl.xdata.fix` `'npl.adjust_opt_params` `'npl.apply_constraints` `'npl.build_congest_table` `'npl.build_region_mgr` `'npl.ca0` `'npl.ca1.seal` `'npl.ca1.shark` `'npl.ca2.seal` `'npl.ca3` `'npl.ca4` `'npl.ca5.seal` `'npl.ca6.shark` `'npl.ca7` `'npl.ca8` `'npl.ca_init.seal` `'npl.ca_init.shark` `'npl.ca_setup_cesr_limit` `'npl.check_dev` `'npl.check_io_num` `'npl.check_mutex_ios` `'npl.check_pio` `'npl.check_placement_result` `'npl.check_tcl_vars` `'npl.clear_io_delay` `'npl.cvt_tieoff` `'npl.delete_timer` `'npl.dsp_lglz.sa5` `'npl.dsp_lglz.sk7` `'npl.dsp_lglz_debug` `'npl.dsp_unpack.seal` `'npl.dsp_unpack.shark` `'npl.end_seed` `'npl.final_chk_dcc` `'npl.final_ta` `'npl.final_ta_1` `'npl.fix_bank_vref` `'npl.handle_input_io_bankvcc` `'npl.handle_unused_io_attr` `'npl.increase_dsp_weight` `'npl.init_bank_vccio` `'npl.init_placement` `'npl.init_ta` `'npl.init_timer` `'npl.legalize_all_dsp.sl2` `'npl.load_delay_v3` `'npl.mark_gnd_vcc_nets` `'npl.place_bcell_0.sa5` `'npl.place_bcell_1.sk7` `'npl.place_bcell_2.sa5` `'npl.place_bcell_2.sk7` `'npl.place_inner_pinouts` `'npl.place_io.seal` `'npl.place_io.shark` `'npl.place_io.sl2` `'npl.place_ios_from_ippin` `'npl.place_misc_cells` `'npl.postp_alu.seal` `'npl.postp_com_clk` `'npl.postp_dsp_locs` `'npl.postp_seal_sadc_pad` `'npl.prep_dcs` `'npl.prep_mcu_clk` `'npl.prep_pcie` `'npl.prep_seal_handle_bank` `'npl.prep_seal_handle_cs` `'npl.prep_serdes_clk` `'npl.proc_pll_clki` `'npl.proc_pll_rst` `'npl.process_bankctrl` `'npl.process_sadc` `'npl.reset_default_opt_params` `'npl.restore_verbose` `'npl.run_analytic` `'npl.run_anneal` `'npl.run_eco` `'npl.run_ref` `'npl.sa_reset_move_id` `'npl.session.begin` `'npl.session.end` `'npl.set_seed` `'npl.set_seed.sl2` `'npl.set_timing_derate` `'npl.setup_bank` `'npl.setup_dev` `'npl.setup_dmap` `'npl.setup_netlist` `'npl.ta_update` `'npl.trans_slice_sk7` `'npl.write_loc` `'obj.cell.del` `'orca2init` `'pack.lut62` `'pack.report` `'pdv.test` `'pdv.test.read` `'pr.rpt` `'rt.delayCompa` `'rt.dumpArch` `'rt.genBriefDelay` `'rt.genPattern` `'rt.genResourceUsage` `'rt.gendelay` `'rt.listdelay` `'rt.loadtree` `'rt.wholeDelay` `'rtres.disable` `'spc.writel` `'swb.analyze` `'ta.setup` `'tgraph.print` `'tm.check` `'tm.correlate` `'tm.coverage` `'trcecase.check` `'ucrypt.eval` `'udev.gui.fpxml.write` `'udev.iotype.report` `'udev.pkg.report` `'udev.report` `'ui.save_inst` `'ui.save_net` `'ui_nl.write` `'util.dec2chan` `'util.encrypt` `'util.evalenc` `'util.socket` `'verbose.set` `'vte.impl` `'xdb.clear` `'xdb.path.set` `'xdb.print` `'xdb.read` `'xdb.setup` `'zr`

---

## 各命令 help 详情

## 'abc.lutpack

```
[Syntax]
   'abc.lutpack 
[Arguments]
```

## 'abc.show

```
[Syntax]
   'abc.show 
[Arguments]
```

## 'abc.speedup

```
[Syntax]
   'abc.speedup 
[Arguments]
```

## 'array.add_ip_row

```
[Syntax]
   'array.add_ip_row  <row>
[Arguments]
o row
    type: integer
    default value: None
```

## 'array.add_tile

```
[Syntax]
   'array.add_tile  <abs> <full> <height> <width>
[Arguments]
o abs
    type: string
    default value: None 
o full
    type: string
    default value: None 
o height
    type: integer
    default value: None 
o width
    type: integer
    default value: None
```

## 'array.dump

```
[Syntax]
   'array.dump  <dump_file_name>
[Arguments]
o dump_file_name
    type: string
    default value: None
```

## 'array.dumpbfd

```
[Syntax]
   'array.dumpbfd  <file_name>
[Arguments]
o file_name
    type: string
    default value: None
```

## 'array.get_tile

```
[Syntax]
   'array.get_tile  <row> <col> [-type <type_value>]
[Arguments]
o row
    type: integer
    default value: None 
o col
    type: integer
    default value: None 
o type
    type: enumerated(normal|top|bot|ip)
    default value: normal
```

## 'array.init

```
[Syntax]
   'array.init 
[Arguments]
```

## 'array.reset

```
[Syntax]
   'array.reset  <row> <col> [<rb>]
[Arguments]
o row
    type: integer
    default value: None 
o col
    type: integer
    default value: None 
o rb
    type: integer
    default value: None
```

## 'array.set_tile

```
[Syntax]
   'array.set_tile  <row> <col> <abs> [-type <type_value>]
[Arguments]
o row
    type: integer
    default value: None 
o col
    type: integer
    default value: None 
o abs
    type: string
    default value: None 
o type
    type: enumerated(normal|top|bot|ip)
    default value: normal
```

## 'bfd.addmib

```
[Syntax]
   'bfd.addmib  <tile_name> <new_tile_name> <mib_file_name> <eqn_tile_name> <eqn_mib_file_name> [<co>] [<ro>] [-tilepos <tilepos_value>]
[Arguments]
o tile_name
    type: string
    default value: None 
o new_tile_name
    type: string
    default value: None 
o mib_file_name
    type: string
    default value: None 
o eqn_tile_name
    type: string
    default value: None 
o eqn_mib_file_name
    type: string
    default value: None 
o co
    type: integer
    default value: None 
o ro
    type: integer
    default value: None 
o tilepos
    type: string
    default value: None
```

## 'bfd.apply_node

```
[Syntax]
   'bfd.apply_node  <tile_name> <new_tile_name> <node_name> [-alias <alias_value>] [-nco <nco_value>] [-nro <nro_value>]
[Arguments]
o tile_name
    type: string
    default value: None 
o new_tile_name
    type: string
    default value: None 
o node_name
    type: string
    default value: None 
o alias
    type: string
    default value: None 
o nco
    type: integer
    default value: None 
o nro
    type: integer
    default value: None
```

## 'bfd.applyeqn

```
[Syntax]
   'bfd.applyeqn  <tile_name> <new_tile_name> <eqn> [-nco <nco_value>] [-nro <nro_value>]
[Arguments]
o tile_name
    type: string
    default value: None 
o new_tile_name
    type: string
    default value: None 
o eqn
    type: string
    default value: None 
o nco
    type: integer
    default value: None 
o nro
    type: integer
    default value: None
```

## 'bfd.applymib

```
[Syntax]
   'bfd.applymib  <tile_name> <new_tile_name> <mib_file_name> [-eqn <eqn_value>] [-nco <nco_value>] [-nro <nro_value>] [-tilepos <tilepos_value>]
[Arguments]
o tile_name
    type: string
    default value: None 
o new_tile_name
    type: string
    default value: None 
o mib_file_name
    type: string
    default value: None 
o eqn
    type: string
    default value: None 
o nco
    type: integer
    default value: None 
o nro
    type: integer
    default value: None 
o tilepos
    type: string
    default value: None
```

## 'bfd.assigneqn

```
[Syntax]
   'bfd.assigneqn  <tile_name> <new_tile_name> <fuse_name> <eqn_tile_name> <eqn_fuse_name>
[Arguments]
o tile_name
    type: string
    default value: None 
o new_tile_name
    type: string
    default value: None 
o fuse_name
    type: string
    default value: None 
o eqn_tile_name
    type: string
    default value: None 
o eqn_fuse_name
    type: string
    default value: None
```

## 'bfd.changemem

```
[Syntax]
   'bfd.changemem  <tile_name> <new_tile_name> <mem_file_name> <offset_data> [-c_offset <c_offset_value>] [-eqn <eqn_value>] [-lr] [-r_offset <r_offset_value>] [-syntax <syntax_value>] [-tb]
[Arguments]
o tile_name
    type: string
    default value: None 
o new_tile_name
    type: string
    default value: None 
o mem_file_name
    type: string
    default value: None 
o offset_data
    type: integer
    default value: None 
o c_offset
    type: integer
    default value: None 
o eqn
    type: string
    default value: None 
o lr
    type: switch
    default value: None 
o r_offset
    type: integer
    default value: None 
o syntax
    type: string
    default value: None 
o tb
    type: switch
    default value: None
```

## 'bfd.delmib

```
[Syntax]
   'bfd.delmib  <tile_name> <new_tile_name> <mib_file_name>
[Arguments]
o tile_name
    type: string
    default value: None 
o new_tile_name
    type: string
    default value: None 
o mib_file_name
    type: string
    default value: None
```

## 'bfd.dump

```
[Syntax]
   'bfd.dump  <tile_name> <dump_file_name>
[Arguments]
o tile_name
    type: string
    default value: None 
o dump_file_name
    type: string
    default value: None
```

## 'bfd.dumpbfd

```
[Syntax]
   'bfd.dumpbfd  <file_name>
[Arguments]
o file_name
    type: string
    default value: None
```

## 'bfd.gendsp

```
[Syntax]
   'bfd.gendsp  <mem_file_name> [-22k]
[Arguments]
o mem_file_name
    type: string
    default value: None 
o 22k
    type: switch
    default value: None
```

## 'bfd.load

```
[Syntax]
   'bfd.load  <bfz_file_name>
[Arguments]
o bfz_file_name
    type: string
    default value: None
```

## 'bfd.movemib

```
[Syntax]
   'bfd.movemib  <tile_name> <new_tile_name> <mib_file_name> <new_mib_file_name> [-new_tilepos <new_tilepos_value>] [-old_tilepos <old_tilepos_value>]
[Arguments]
o tile_name
    type: string
    default value: None 
o new_tile_name
    type: string
    default value: None 
o mib_file_name
    type: string
    default value: None 
o new_mib_file_name
    type: string
    default value: None 
o new_tilepos
    type: string
    default value: None 
o old_tilepos
    type: string
    default value: None
```

## 'bfd.newtile

```
[Syntax]
   'bfd.newtile  <tile_name> <height> <width>
[Arguments]
o tile_name
    type: string
    default value: None 
o height
    type: integer
    default value: None 
o width
    type: integer
    default value: None
```

## 'bfd.row_resize

```
[Syntax]
   'bfd.row_resize  <tile_name> <new_tile_name> <rs> <re>
[Arguments]
o tile_name
    type: string
    default value: None 
o new_tile_name
    type: string
    default value: None 
o rs
    type: integer
    default value: None 
o re
    type: integer
    default value: None
```

## 'blif.read

```
[Syntax]
   'blif.read  <filename>
[Arguments]
o filename
    type: string
    default value: None
```

## 'blif.write

```
[Syntax]
   'blif.write  <filename>
[Arguments]
o filename
    type: string
    default value: None
```

## 'check.msg.match

```
[Syntax]
   'check.msg.match  <language0> <language1>
[Arguments]
o language0
    type: string
    default value: None 
o language1
    type: string
    default value: eng
```

## 'cktgen

```
[Syntax]
   'cktgen  <cnt>
[Arguments]
o cnt
    type: integer
    default value: None
```

## 'cktop

```
[Syntax]
   'cktop 
[Arguments]
```

## 'cktopoh

```
[Syntax]
   'cktopoh 
[Arguments]
```

## 'delay.set

```
[Syntax]
   'delay.set  <pin> <delay>
[Arguments]
o pin
    type: string
    default value: None 
o delay
    type: integer
    default value: None
```

## 'dsgn.clear

```
[Syntax]
   'dsgn.clear 
[Arguments]
```

## 'dv.prep

```
[Syntax]
   'dv.prep  <family>
[Arguments]
o family
    type: string
    default value: None
```

## 'dv.test

```
[Syntax]
   'dv.test  <name>
[Arguments]
o name
    type: string
    default value: None
```

## 'ebr.report

```
[Syntax]
   'ebr.report 
[Arguments]
```

## 'eco.mindly

```
[Syntax]
   'eco.mindly 
[Arguments]
```

## 'eco.pin_offset

```
[Syntax]
   'eco.pin_offset 
[Arguments]
```

## 'eco.report_reused_cib

```
[Syntax]
   'eco.report_reused_cib 
[Arguments]
```

## 'eco.rpt_conn

```
[Syntax]
   'eco.rpt_conn 
[Arguments]
```

## 'expr.cmd

```
[Syntax]
   'expr.cmd  <file> [-format <format_value>] [-loc <loc_value>]
[Arguments]
o file
    type: string
    default value: None 
o format
    type: enumerated(edif|svlg)
    default value: edif 
o loc
    type: recursive(type:E(clb|slice) x:I y:I)
    default value: None
```

## 'exprcmd3

```
[Syntax]
   'exprcmd3 
[Arguments]
```

## 'hierxdata.set

```
[Syntax]
   'hierxdata.set  <name> <type>
[Arguments]
o name
    type: string
    default value: None 
o type
    type: string
    default value: None
```

## 'hwminx.sig1

```
[Syntax]
   'hwminx.sig1 
[Arguments]
```

## 'hwminx.sig2

```
[Syntax]
   'hwminx.sig2 
[Arguments]
```

## 'impl.bitgen.analyzepiptestresult

```
[Syntax]
   'impl.bitgen.analyzepiptestresult  <pip_test_log_file>
[Arguments]
o pip_test_log_file
    type: string
    default value: None
```

## 'impl.bitgen.testpip

```
[Syntax]
   'impl.bitgen.testpip  <pip>
[Arguments]
o pip
    type: string
    default value: None
```

## 'impl.bitgen.testpiplist

```
[Syntax]
   'impl.bitgen.testpiplist  <pip_list_file>
[Arguments]
o pip_list_file
    type: string
    default value: None
```

## 'impl.fixopenup

```
[Syntax]
   'impl.fixopenup 
[Arguments]
```

## 'impl.lut_pack

```
[Syntax]
   'impl.lut_pack  [<nview>] [-bound <bound_value>]
[Arguments]
o nview
    type: object_reference
    default value: None 
o bound
    type: integer
    default value: None
```

## 'impl.packlc

```
[Syntax]
   'impl.packlc  [-lpp]
[Arguments]
o lpp
    type: switch
    default value: None
```

## 'insight.urjtag

```
[Syntax]
   'insight.urjtag  <cmd>
[Arguments]
o cmd
    type: string
    default value: None
```

## 'ip.inst.mark

```
[Syntax]
   'ip.inst.mark 
[Arguments]
```

## 'lic.add

```
[Syntax]
   'lic.add  <key> <expdate> <devdesc>
[Arguments]
o key
    type: string
    default value: None 
o expdate
    type: string
    default value: None 
o devdesc
    type: string
    default value: None
```

## 'lic.check

```
[Syntax]
   'lic.check  <key> [-device <device_value>]
[Arguments]
o key
    type: string
    default value: hq.base 
o device
    type: string
    default value: None
```

## 'lic.end

```
[Syntax]
   'lic.end 
[Arguments]
```

## 'lic.info

```
[Syntax]
   'lic.info  <what>
[Arguments]
o what
    type: enumerated(owner|type|key)
    default value: None
```

## 'lic.start

```
[Syntax]
   'lic.start  <owner> [-type <type_value>]
[Arguments]
o owner
    type: string
    default value: None 
o type
    type: enumerated(trial|personal|volume)
    default value: trial
```

## 'lo.cntlit

```
[Syntax]
   'lo.cntlit  [<nview>] [-hier]
[Arguments]
o nview
    type: object_reference
    default value: None 
o hier
    type: switch
    default value: None
```

## 'lo.cubext2

```
[Syntax]
   'lo.cubext2  [<nview>] [-b] [-t <t_value>]
[Arguments]
o nview
    type: object_reference
    default value: None 
o b
    type: switch
    default value: None 
o t
    type: integer
    default value: None
```

## 'lo.decomp

```
[Syntax]
   'lo.decomp  [<nview>] [-c] [-j] [-k] [-l <l_value>] [-t]
[Arguments]
o nview
    type: object_reference
    default value: None 
o c
    type: switch
    default value: None 
o j
    type: switch
    default value: None 
o k
    type: switch
    default value: None 
o l
    type: integer
    default value: None 
o t
    type: switch
    default value: None
```

## 'lo.eliminate

```
[Syntax]
   'lo.eliminate  [<nview>] [-a] [-l <l_value>] [-t <t_value>]
[Arguments]
o nview
    type: object_reference
    default value: None 
o a
    type: switch
    default value: None 
o l
    type: integer
    default value: None 
o t
    type: integer
    default value: None
```

## 'lo.findxor

```
[Syntax]
   'lo.findxor  [<nview>]
[Arguments]
o nview
    type: object_reference
    default value: None
```

## 'lo.kernelext2

```
[Syntax]
   'lo.kernelext2  [<nview>] [-a] [-b] [-o] [-t <t_value>]
[Arguments]
o nview
    type: object_reference
    default value: None 
o a
    type: switch
    default value: None 
o b
    type: switch
    default value: None 
o o
    type: switch
    default value: None 
o t
    type: integer
    default value: None
```

## 'lo.mffc

```
[Syntax]
   'lo.mffc  [<nview>] [-c <c_value>]
[Arguments]
o nview
    type: object_reference
    default value: None 
o c
    type: integer
    default value: None
```

## 'lo.resub

```
[Syntax]
   'lo.resub  [<nview>]
[Arguments]
o nview
    type: object_reference
    default value: None
```

## 'lo.swallow

```
[Syntax]
   'lo.swallow  [<nview>]
[Arguments]
o nview
    type: object_reference
    default value: None
```

## 'lo.tdo

```
[Syntax]
   'lo.tdo  [<nview>] [-f <f_value>]
[Arguments]
o nview
    type: object_reference
    default value: None 
o f
    type: integer
    default value: None
```

## 'lo.ws

```
[Syntax]
   'lo.ws  [<nview>]
[Arguments]
o nview
    type: object_reference
    default value: None
```

## 'lpp.bpl.pio2iol

```
[Syntax]
   'lpp.bpl.pio2iol 
[Arguments]
```

## 'lpp.clk_diff

```
[Syntax]
   'lpp.clk_diff 
[Arguments]
```

## 'lpp.dump_clk_txt

```
[Syntax]
   'lpp.dump_clk_txt  <fn>
[Arguments]
o fn
    type: string
    default value: None
```

## 'lpp.merge_const

```
[Syntax]
   'lpp.merge_const 
[Arguments]
```

## 'lpp.sloc_to_pcloc

```
[Syntax]
   'lpp.sloc_to_pcloc 
[Arguments]
```

## 'map.rpt

```
[Syntax]
   'map.rpt  [<rpt>] [-from <from_value>]
[Arguments]
o rpt
    type: string
    default value: None 
o from
    type: string
    default value: None
```

## 'misc.buryBomb

```
[Syntax]
   'misc.buryBomb  [-bombFile <bombFile_value>]
[Arguments]
o bombFile
    type: string
    default value:
```

## 'misc.cfg2graph

```
[Syntax]
   'misc.cfg2graph 
[Arguments]
```

## 'misc.dumpNetlistData

```
[Syntax]
   'misc.dumpNetlistData 
[Arguments]
```

## 'misc.getBombString

```
[Syntax]
   'misc.getBombString  <bombStr> [-cnt <cnt_value>] [-round <round_value>]
[Arguments]
o bombStr
    type: string
    default value: None 
o cnt
    type: integer
    default value: 1000000 
o round
    type: integer
    default value: 10
```

## 'misc.svg2xml

```
[Syntax]
   'misc.svg2xml  [-file <file_value>] [-keepOrigin <keepOrigin_value>] [-keepStyle <keepStyle_value>] [-valCaseType <valCaseType_value>]
[Arguments]
o file
    type: string
    default value: None 
o keepOrigin
    type: integer
    default value: 0 
o keepStyle
    type: integer
    default value: 0 
o valCaseType
    type: integer
    default value: 0
```

## 'msg.group.op

```
[Syntax]
   'msg.group.op  <op> <msg_group>
[Arguments]
o op
    type: enumerated(load|unload)
    default value: None 
o msg_group
    type: string
    default value: None
```

## 'msg.puts

```
[Syntax]
   'msg.puts  <msg_id> <msg_content> [-tochannel <tochannel_value>]
[Arguments]
o msg_id
    type: string
    default value: None 
o msg_content
    type: string
    default value:  
o tochannel
    type: string
    default value: None
```

## 'my.cmd

```
[Syntax]
   'my.cmd  <file> [-format <format_value>] [-loc <loc_value>]
[Arguments]
o file
    type: string
    default value: None 
o format
    type: enumerated(edif|svlg)
    default value: edif 
o loc
    type: recursive(type:E(clb|slice) x:I y:I)
    default value: None
```

## 'nl.chkclk

```
[Syntax]
   'nl.chkclk 
[Arguments]
```

## 'nl.chkff

```
[Syntax]
   'nl.chkff 
[Arguments]
```

## 'nl.lscombunify

```
[Syntax]
   'nl.lscombunify 
[Arguments]
```

## 'nl.prof.sl2

```
[Syntax]
   'nl.prof.sl2  <nview>
[Arguments]
o nview
    type: object_reference
    default value: ~
```

## 'nl.xdata.fix

```
[Syntax]
   'nl.xdata.fix 
[Arguments]
```

## 'npl.adjust_opt_params

```
[Syntax]
   'npl.adjust_opt_params 
[Arguments]
```

## 'npl.apply_constraints

```
[Syntax]
   'npl.apply_constraints 
[Arguments]
```

## 'npl.build_congest_table

```
[Syntax]
   'npl.build_congest_table 
[Arguments]
```

## 'npl.build_region_mgr

```
[Syntax]
   'npl.build_region_mgr 
[Arguments]
```

## 'npl.ca0

```
[Syntax]
   'npl.ca0 
[Arguments]
```

## 'npl.ca1.seal

```
[Syntax]
   'npl.ca1.seal 
[Arguments]
```

## 'npl.ca1.shark

```
[Syntax]
   'npl.ca1.shark 
[Arguments]
```

## 'npl.ca2.seal

```
[Syntax]
   'npl.ca2.seal 
[Arguments]
```

## 'npl.ca3

```
[Syntax]
   'npl.ca3 
[Arguments]
```

## 'npl.ca4

```
[Syntax]
   'npl.ca4 
[Arguments]
```

## 'npl.ca5.seal

```
[Syntax]
   'npl.ca5.seal 
[Arguments]
```

## 'npl.ca6.shark

```
[Syntax]
   'npl.ca6.shark 
[Arguments]
```

## 'npl.ca7

```
[Syntax]
   'npl.ca7 
[Arguments]
```

## 'npl.ca8

```
[Syntax]
   'npl.ca8 
[Arguments]
```

## 'npl.ca_init.seal

```
[Syntax]
   'npl.ca_init.seal 
[Arguments]
```

## 'npl.ca_init.shark

```
[Syntax]
   'npl.ca_init.shark 
[Arguments]
```

## 'npl.ca_setup_cesr_limit

```
[Syntax]
   'npl.ca_setup_cesr_limit 
[Arguments]
```

## 'npl.check_dev

```
[Syntax]
   'npl.check_dev 
[Arguments]
```

## 'npl.check_io_num

```
[Syntax]
   'npl.check_io_num 
[Arguments]
```

## 'npl.check_mutex_ios

```
[Syntax]
   'npl.check_mutex_ios 
[Arguments]
```

## 'npl.check_pio

```
[Syntax]
   'npl.check_pio 
[Arguments]
```

## 'npl.check_placement_result

```
[Syntax]
   'npl.check_placement_result 
[Arguments]
```

## 'npl.check_tcl_vars

```
[Syntax]
   'npl.check_tcl_vars 
[Arguments]
```

## 'npl.clear_io_delay

```
[Syntax]
   'npl.clear_io_delay 
[Arguments]
```

## 'npl.cvt_tieoff

```
[Syntax]
   'npl.cvt_tieoff 
[Arguments]
```

## 'npl.delete_timer

```
[Syntax]
   'npl.delete_timer 
[Arguments]
```

## 'npl.dsp_lglz.sa5

```
[Syntax]
   'npl.dsp_lglz.sa5 
[Arguments]
```

## 'npl.dsp_lglz.sk7

```
[Syntax]
   'npl.dsp_lglz.sk7 
[Arguments]
```

## 'npl.dsp_lglz_debug

```
[Syntax]
   'npl.dsp_lglz_debug 
[Arguments]
```

## 'npl.dsp_unpack.seal

```
[Syntax]
   'npl.dsp_unpack.seal 
[Arguments]
```

## 'npl.dsp_unpack.shark

```
[Syntax]
   'npl.dsp_unpack.shark 
[Arguments]
```

## 'npl.end_seed

```
[Syntax]
   'npl.end_seed 
[Arguments]
```

## 'npl.final_chk_dcc

```
[Syntax]
   'npl.final_chk_dcc 
[Arguments]
```

## 'npl.final_ta

```
[Syntax]
   'npl.final_ta 
[Arguments]
```

## 'npl.final_ta_1

```
[Syntax]
   'npl.final_ta_1 
[Arguments]
```

## 'npl.fix_bank_vref

```
[Syntax]
   'npl.fix_bank_vref 
[Arguments]
```

## 'npl.handle_input_io_bankvcc

```
[Syntax]
   'npl.handle_input_io_bankvcc 
[Arguments]
```

## 'npl.handle_unused_io_attr

```
[Syntax]
   'npl.handle_unused_io_attr 
[Arguments]
```

## 'npl.increase_dsp_weight

```
[Syntax]
   'npl.increase_dsp_weight 
[Arguments]
```

## 'npl.init_bank_vccio

```
[Syntax]
   'npl.init_bank_vccio 
[Arguments]
```

## 'npl.init_placement

```
[Syntax]
   'npl.init_placement 
[Arguments]
```

## 'npl.init_ta

```
[Syntax]
   'npl.init_ta 
[Arguments]
```

## 'npl.init_timer

```
[Syntax]
   'npl.init_timer 
[Arguments]
```

## 'npl.legalize_all_dsp.sl2

```
[Syntax]
   'npl.legalize_all_dsp.sl2 
[Arguments]
```

## 'npl.load_delay_v3

```
[Syntax]
   'npl.load_delay_v3 
[Arguments]
```

## 'npl.mark_gnd_vcc_nets

```
[Syntax]
   'npl.mark_gnd_vcc_nets 
[Arguments]
```

## 'npl.place_bcell_0.sa5

```
[Syntax]
   'npl.place_bcell_0.sa5 
[Arguments]
```

## 'npl.place_bcell_1.sk7

```
[Syntax]
   'npl.place_bcell_1.sk7 
[Arguments]
```

## 'npl.place_bcell_2.sa5

```
[Syntax]
   'npl.place_bcell_2.sa5 
[Arguments]
```

## 'npl.place_bcell_2.sk7

```
[Syntax]
   'npl.place_bcell_2.sk7 
[Arguments]
```

## 'npl.place_inner_pinouts

```
[Syntax]
   'npl.place_inner_pinouts 
[Arguments]
```

## 'npl.place_io.seal

```
[Syntax]
   'npl.place_io.seal 
[Arguments]
```

## 'npl.place_io.shark

```
[Syntax]
   'npl.place_io.shark 
[Arguments]
```

## 'npl.place_io.sl2

```
[Syntax]
   'npl.place_io.sl2 
[Arguments]
```

## 'npl.place_ios_from_ippin

```
[Syntax]
   'npl.place_ios_from_ippin 
[Arguments]
```

## 'npl.place_misc_cells

```
[Syntax]
   'npl.place_misc_cells 
[Arguments]
```

## 'npl.postp_alu.seal

```
[Syntax]
   'npl.postp_alu.seal 
[Arguments]
```

## 'npl.postp_com_clk

```
[Syntax]
   'npl.postp_com_clk 
[Arguments]
```

## 'npl.postp_dsp_locs

```
[Syntax]
   'npl.postp_dsp_locs 
[Arguments]
```

## 'npl.postp_seal_sadc_pad

```
[Syntax]
   'npl.postp_seal_sadc_pad 
[Arguments]
```

## 'npl.prep_dcs

```
[Syntax]
   'npl.prep_dcs 
[Arguments]
```

## 'npl.prep_mcu_clk

```
[Syntax]
   'npl.prep_mcu_clk 
[Arguments]
```

## 'npl.prep_pcie

```
[Syntax]
   'npl.prep_pcie 
[Arguments]
```

## 'npl.prep_seal_handle_bank

```
[Syntax]
   'npl.prep_seal_handle_bank 
[Arguments]
```

## 'npl.prep_seal_handle_cs

```
[Syntax]
   'npl.prep_seal_handle_cs 
[Arguments]
```

## 'npl.prep_serdes_clk

```
[Syntax]
   'npl.prep_serdes_clk 
[Arguments]
```

## 'npl.proc_pll_clki

```
[Syntax]
   'npl.proc_pll_clki 
[Arguments]
```

## 'npl.proc_pll_rst

```
[Syntax]
   'npl.proc_pll_rst 
[Arguments]
```

## 'npl.process_bankctrl

```
[Syntax]
   'npl.process_bankctrl 
[Arguments]
```

## 'npl.process_sadc

```
[Syntax]
   'npl.process_sadc 
[Arguments]
```

## 'npl.reset_default_opt_params

```
[Syntax]
   'npl.reset_default_opt_params 
[Arguments]
```

## 'npl.restore_verbose

```
[Syntax]
   'npl.restore_verbose 
[Arguments]
```

## 'npl.run_analytic

```
[Syntax]
   'npl.run_analytic 
[Arguments]
```

## 'npl.run_anneal

```
[Syntax]
   'npl.run_anneal 
[Arguments]
```

## 'npl.run_eco

```
[Syntax]
   'npl.run_eco 
[Arguments]
```

## 'npl.run_ref

```
[Syntax]
   'npl.run_ref 
[Arguments]
```

## 'npl.sa_reset_move_id

```
[Syntax]
   'npl.sa_reset_move_id 
[Arguments]
```

## 'npl.session.begin

```
[Syntax]
   'npl.session.begin  [-ap] [-ap_kw2] [-ap_npl] [-eco] [-effort <effort_value>] [-np] [-seed <seed_value>]
[Arguments]
o ap
    type: switch
    default value: None 
o ap_kw2
    type: switch
    default value: None 
o ap_npl
    type: switch
    default value: None 
o eco
    type: switch
    default value: None 
o effort
    type: enumerated(low|std|high)
    default value: std 
o np
    type: switch
    default value: None 
o seed
    type: integer
    default value: None
```

## 'npl.session.end

```
[Syntax]
   'npl.session.end 
[Arguments]
```

## 'npl.set_seed

```
[Syntax]
   'npl.set_seed 
[Arguments]
```

## 'npl.set_seed.sl2

```
[Syntax]
   'npl.set_seed.sl2 
[Arguments]
```

## 'npl.set_timing_derate

```
[Syntax]
   'npl.set_timing_derate 
[Arguments]
```

## 'npl.setup_bank

```
[Syntax]
   'npl.setup_bank 
[Arguments]
```

## 'npl.setup_dev

```
[Syntax]
   'npl.setup_dev 
[Arguments]
```

## 'npl.setup_dmap

```
[Syntax]
   'npl.setup_dmap 
[Arguments]
```

## 'npl.setup_netlist

```
[Syntax]
   'npl.setup_netlist 
[Arguments]
```

## 'npl.ta_update

```
[Syntax]
   'npl.ta_update 
[Arguments]
```

## 'npl.trans_slice_sk7

```
[Syntax]
   'npl.trans_slice_sk7 
[Arguments]
```

## 'npl.write_loc

```
[Syntax]
   'npl.write_loc 
[Arguments]
```

## 'obj.cell.del

```
[Syntax]
   'obj.cell.del  <obj>
[Arguments]
o obj
    type: object_reference
    default value: None
```

## 'orca2init

```
[Syntax]
   'orca2init 
[Arguments]
```

## 'pack.lut62

```
[Syntax]
   'pack.lut62 
[Arguments]
```

## 'pack.report

```
[Syntax]
   'pack.report 
[Arguments]
```

## 'pdv.test

```
[Syntax]
   'pdv.test 
[Arguments]
```

## 'pdv.test.read

```
[Syntax]
   'pdv.test.read  <fn> <die> <pkg>
[Arguments]
o fn
    type: string
    default value: None 
o die
    type: string
    default value: None 
o pkg
    type: string
    default value: None
```

## 'pr.rpt

```
[Syntax]
   'pr.rpt  [<rpt>]
[Arguments]
o rpt
    type: string
    default value: None
```

## 'rt.delayCompa

```
[Syntax]
   'rt.delayCompa  [-mode <mode_value>]
[Arguments]
o mode
    type: integer
    default value: 3
```

## 'rt.dumpArch

```
[Syntax]
   'rt.dumpArch 
[Arguments]
```

## 'rt.genBriefDelay

```
[Syntax]
   'rt.genBriefDelay 
[Arguments]
```

## 'rt.genPattern

```
[Syntax]
   'rt.genPattern  <templateFile> <outputFile>
[Arguments]
o templateFile
    type: string
    default value: None 
o outputFile
    type: string
    default value: None
```

## 'rt.genResourceUsage

```
[Syntax]
   'rt.genResourceUsage 
[Arguments]
```

## 'rt.gendelay

```
[Syntax]
   'rt.gendelay 
[Arguments]
```

## 'rt.listdelay

```
[Syntax]
   'rt.listdelay  [-effort <effort_value>]
[Arguments]
o effort
    type: enumerated(timing|simplified_timing)
    default value: timing
```

## 'rt.loadtree

```
[Syntax]
   'rt.loadtree 
[Arguments]
```

## 'rt.wholeDelay

```
[Syntax]
   'rt.wholeDelay  [-dlyth <dlyth_value>] [-filename <filename_value>] [-mode <mode_value>] [-sth <sth_value>]
[Arguments]
o dlyth
    type: integer
    default value: 80 
o filename
    type: string
    default value: badpath.txt 
o mode
    type: string
    default value: pl 
o sth
    type: integer
    default value: 50
```

## 'rtres.disable

```
[Syntax]
   'rtres.disable  <wire_pattern>
[Arguments]
o wire_pattern
    type: string
    default value: None
```

## 'spc.writel

```
[Syntax]
   'spc.writel  <filename> <listFile> <cfgFile> <pipComFile>
[Arguments]
o filename
    type: string
    default value: None 
o listFile
    type: string
    default value: None 
o cfgFile
    type: string
    default value: None 
o pipComFile
    type: string
    default value: None
```

## 'swb.analyze

```
[Syntax]
   'swb.analyze 
[Arguments]
```

## 'ta.setup

```
[Syntax]
   'ta.setup 
[Arguments]
```

## 'tgraph.print

```
[Syntax]
   'tgraph.print  [-title <title_value>]
[Arguments]
o title
    type: string
    default value: None
```

## 'tm.check

```
[Syntax]
   'tm.check  <obj>
[Arguments]
o obj
    type: object_reference
    default value: ~
```

## 'tm.correlate

```
[Syntax]
   'tm.correlate  [-detail]
[Arguments]
o detail
    type: switch
    default value: None
```

## 'tm.coverage

```
[Syntax]
   'tm.coverage  [-phy]
[Arguments]
o phy
    type: switch
    default value: None
```

## 'trcecase.check

```
[Syntax]
   'trcecase.check 
[Arguments]
```

## 'ucrypt.eval

```
[Syntax]
   'ucrypt.eval  <fname> [-key <key_value>]
[Arguments]
o fname
    type: string
    default value: None 
o key
    type: integer
    default value: 33
```

## 'udev.gui.fpxml.write

```
[Syntax]
   'udev.gui.fpxml.write  <file>
[Arguments]
o file
    type: string
    default value: None
```

## 'udev.iotype.report

```
[Syntax]
   'udev.iotype.report 
[Arguments]
```

## 'udev.pkg.report

```
[Syntax]
   'udev.pkg.report  [-file <file_value>]
[Arguments]
o file
    type: string
    default value: None
```

## 'udev.report

```
[Syntax]
   'udev.report  [-file <file_value>]
[Arguments]
o file
    type: string
    default value: None
```

## 'ui.save_inst

```
[Syntax]
   'ui.save_inst  <filename>
[Arguments]
o filename
    type: string
    default value: None
```

## 'ui.save_net

```
[Syntax]
   'ui.save_net  <filename>
[Arguments]
o filename
    type: string
    default value: None
```

## 'ui_nl.write

```
[Syntax]
   'ui_nl.write  <filename>
[Arguments]
o filename
    type: string
    default value: None
```

## 'util.dec2chan

```
[Syntax]
   'util.dec2chan  <input_fname>
[Arguments]
o input_fname
    type: string
    default value: None
```

## 'util.encrypt

```
[Syntax]
   'util.encrypt  <input_fname> <output_fname> [-gz]
[Arguments]
o input_fname
    type: string
    default value: None 
o output_fname
    type: string
    default value: None 
o gz
    type: switch
    default value: None
```

## 'util.evalenc

```
[Syntax]
   'util.evalenc  <input_fname>
[Arguments]
o input_fname
    type: string
    default value: None
```

## 'util.socket

```
[Syntax]
   'util.socket 
[Arguments]
```

## 'verbose.set

```
[Syntax]
   'verbose.set  [<level>]
[Arguments]
o level
    type: integer
    default value: None
```

## 'vte.impl

```
[Syntax]
   'vte.impl 
[Arguments]
```

## 'xdb.clear

```
[Syntax]
   'xdb.clear 
[Arguments]
```

## 'xdb.path.set

```
[Syntax]
   'xdb.path.set  <path>
[Arguments]
o path
    type: string
    default value: None
```

## 'xdb.print

```
[Syntax]
   'xdb.print 
[Arguments]
```

## 'xdb.read

```
[Syntax]
   'xdb.read  <fname>
[Arguments]
o fname
    type: string
    default value: None
```

## 'xdb.setup

```
[Syntax]
   'xdb.setup 
[Arguments]
```

## 'zr

```
[Syntax]
   'zr  <inf> <outf>
[Arguments]
o inf
    type: string
    default value: None 
o outf
    type: string
    default value: None
```

## EvalAccept

(无 help 条目)

## EvalConn

(无 help 条目)

## EvalOpenProc

(无 help 条目)

## EvalQuery

(无 help 条目)

## EvalRead

(无 help 条目)

## Eval_Server

(无 help 条目)

## TstQueryConn

(无 help 条目)

## abc.lo

```
[Syntax]
   abc.lo 
[Arguments]
```

## abc.map

```
[Syntax]
   abc.map 
[Arguments]
```

## addPid

(无 help 条目)

## add_uns_line

(无 help 条目)

## after

(无 help 条目)

## all_clocks

```
[Syntax]
   all_clocks 
[Arguments]
```

## all_inputs

```
[Syntax]
   all_inputs 
[Arguments]
```

## all_outputs

```
[Syntax]
   all_outputs 
[Arguments]
```

## append

(无 help 条目)

## apply

(无 help 条目)

## array

(无 help 条目)

## autoDetectTopModule

(无 help 条目)

## auto_execok

(无 help 条目)

## auto_import

(无 help 条目)

## auto_load

(无 help 条目)

## auto_load_index

(无 help 条目)

## auto_qualify

(无 help 条目)

## bank.dci_cascade

```
[Syntax]
   bank.dci_cascade  <banks>
[Arguments]
o banks
    type: string
    default value: None
```

## bgerror

(无 help 条目)

## binary

(无 help 条目)

## break

(无 help 条目)

## bs.read

```
[Syntax]
   bs.read  <nodesfname> <netsfname> [<libfname>]
[Arguments]
o nodesfname
    type: string
    default value: None 
o netsfname
    type: string
    default value: None 
o libfname
    type: string
    default value: None
```

## case

(无 help 条目)

## catch

(无 help 条目)

## cd

(无 help 条目)

## cd_hqorg

(无 help 条目)

## cfgxdata.delete

```
[Syntax]
   cfgxdata.delete  <name>
[Arguments]
o name
    type: string
    default value: None
```

## cfgxdata.query

```
[Syntax]
   cfgxdata.query  <name> <what>
[Arguments]
o name
    type: string
    default value: None 
o what
    type: enumerated(all|value|type)
    default value: all
```

## cfgxdata.set

```
[Syntax]
   cfgxdata.set  <name> <value> [<addsptr>]
[Arguments]
o name
    type: string
    default value: None 
o value
    type: string
    default value: None 
o addsptr
    type: string
    default value: None
```

## chan

(无 help 条目)

## check_netlist_null

(无 help 条目)

## check_operation_applicable

(无 help 条目)

## chkAbsPath

(无 help 条目)

## chkRelativePath

(无 help 条目)

## chk_comon_path

(无 help 条目)

## chk_hqui_var

(无 help 条目)

## chk_insight_dbgr_stat

(无 help 条目)

## chk_insight_impl_stat

(无 help 条目)

## chk_insight_instru_stat

(无 help 条目)

## chk_keep_hier

(无 help 条目)

## chk_restore_100k_drt

(无 help 条目)

## chk_set_100k_drt

(无 help 条目)

## chkrun_step_debug_script

(无 help 条目)

## chkset_drt_from_hqvar

(无 help 条目)

## clear_design

(无 help 条目)

## clear_step_debug_script

(无 help 条目)

## clkrgn.deskew

```
[Syntax]
   clkrgn.deskew 
[Arguments]
```

## clkrgn.skew.annotate

```
[Syntax]
   clkrgn.skew.annotate 
[Arguments]
```

## clock

(无 help 条目)

## close

(无 help 条目)

## concat

(无 help 条目)

## continue

(无 help 条目)

## conv_sl2_eco_pcst

(无 help 条目)

## coroutine

(无 help 条目)

## create_clock

```
[Syntax]
   create_clock  [<source_objects>] [-add] [-name <name_value>] [-period <period_value>] [-waveform <waveform_value>]
[Arguments]
o source_objects
    type: string
    default value: None 
o add
    type: switch
    default value: None 
o name
    type: string
    default value: None 
o period
    type: double
    default value: None 
o waveform
    type: string
    default value: None
```

## create_generated_clock

```
[Syntax]
   create_generated_clock  [<source_objects>] [-add] [-divide_by <divide_by_value>] [-duty_cycle <duty_cycle_value>] [-edge_shift <edge_shift_value>] [-edges <edges_value>] [-invert] [-master_clock <master_clock_value>] [-multiply_by <multiply_by_value>] [-name <name_value>] [-source <source_value>]
[Arguments]
o source_objects
    type: string
    default value: None 
o add
    type: switch
    default value: None 
o divide_by
    type: integer
    default value: None 
o duty_cycle
    type: double
    default value: None 
o edge_shift
    type: string
    default value: None 
o edges
    type: string
    default value: None 
o invert
    type: switch
    default value: None 
o master_clock
    type: string
    default value: None 
o multiply_by
    type: integer
    default value: None 
o name
    type: string
    default value: None 
o source
    type: string
    default value: None
```

## csv2upc

```
[Syntax]
   csv2upc  <csv_file_name> <upc_file_name>
[Arguments]
o csv_file_name
    type: string
    default value: None 
o upc_file_name
    type: string
    default value: None
```

## ctrlsigs.block

```
[Syntax]
   ctrlsigs.block 
[Arguments]
```

## dconv.dev2chipedit

```
[Syntax]
   dconv.dev2chipedit  <filename>
[Arguments]
o filename
    type: string
    default value: None
```

## dconv.xpn2chipedit

```
[Syntax]
   dconv.xpn2chipedit  <filename>
[Arguments]
o filename
    type: string
    default value: None
```

## ddrc.place

```
[Syntax]
   ddrc.place 
[Arguments]
```

## deleteUdm

(无 help 条目)

## derive_generated_clocks

```
[Syntax]
   derive_generated_clocks 
[Arguments]
```

## design.analyze

```
[Syntax]
   design.analyze  <src_files>
[Arguments]
o src_files
    type: string
    default value: None
```

## design.bitgen

(无 help 条目)

## design.drc

```
[Syntax]
   design.drc  [-stage <stage_value>]
[Arguments]
o stage
    type: enumerated(pre_map|post_map|pre_pack|post_pack|pre_place|post_place|pre_route|post_route)
    default value: None
```

## design.flatten

(无 help 条目)

## design.lo

```
[Syntax]
   design.lo  [-effort <effort_value>]
[Arguments]
o effort
    type: enumerated(low|std|high)
    default value: None
```

## design.lo.area

```
[Syntax]
   design.lo.area  [-effort <effort_value>]
[Arguments]
o effort
    type: enumerated(low|std|high)
    default value: None
```

## design.lo.timing

```
[Syntax]
   design.lo.timing  [-effort <effort_value>]
[Arguments]
o effort
    type: enumerated(low|std|high)
    default value: None
```

## design.load

```
[Syntax]
   design.load  <filename>
[Arguments]
o filename
    type: string
    default value: None
```

## design.loadSdb

```
[Syntax]
   design.loadSdb  <filename>
[Arguments]
o filename
    type: string
    default value: None
```

## design.looptdo

```
[Syntax]
   design.looptdo  [-end_stage <end_stage_value>] [-hold_slack <hold_slack_value>] [-j <j_value>] [-max_slack <max_slack_value>] [-n <n_value>] [-rundir <rundir_value>] [-sdc <sdc_value>] [-sdc4sta <sdc4sta_value>] [-slack <slack_value>] [-timeout <timeout_value>] [-tprefix <tprefix_value>] [-upc <upc_value>] [-wl <wl_value>]
[Arguments]
o end_stage
    type: string
    default value: None 
o hold_slack
    type: double
    default value: None 
o j
    type: integer
    default value: 1 
o max_slack
    type: double
    default value: None 
o n
    type: integer
    default value: None 
o rundir
    type: string
    default value: None 
o sdc
    type: string
    default value: None 
o sdc4sta
    type: string
    default value: None 
o slack
    type: double
    default value: None 
o timeout
    type: integer
    default value: 1800 
o tprefix
    type: string
    default value: None 
o upc
    type: string
    default value: None 
o wl
    type: double
    default value: None
```

## design.lpp

```
[Syntax]
   design.lpp  [-effort <effort_value>]
[Arguments]
o effort
    type: enumerated(fast|high|extra)
    default value: fast
```

## design.map

```
[Syntax]
   design.map  [-effort <effort_value>] [-lutpk <lutpk_value>] [-max_cut <max_cut_value>]
[Arguments]
o effort
    type: enumerated(low|std|high)
    default value: None 
o lutpk
    type: integer
    default value: None 
o max_cut
    type: integer
    default value: None
```

## design.pack

```
[Syntax]
   design.pack  [-ap_gpack] [-ap_loc_file <ap_loc_file_value>] [-area] [-effort <effort_value>] [-iob_dff <iob_dff_value>] [-ratio <ratio_value>]
[Arguments]
o ap_gpack
    type: switch
    default value: None 
o ap_loc_file
    type: string
    default value: None 
o area
    type: switch
    default value: None 
o effort
    type: enumerated(low|std|high)
    default value: std 
o iob_dff
    type: integer
    default value: None 
o ratio
    type: integer
    default value: None
```

## design.place

```
[Syntax]
   design.place  [-eco] [-effort <effort_value>] [-seed <seed_value>]
[Arguments]
o eco
    type: switch
    default value: None 
o effort
    type: enumerated(low|std|high)
    default value: std 
o seed
    type: integer
    default value: None
```

## design.reset

```
[Syntax]
   design.reset  [-release_mempool]
[Arguments]
o release_mempool
    type: switch
    default value: None
```

## design.route

```
[Syntax]
   design.route  [-decomp] [-effort <effort_value>] [-mpi] [-parallel <parallel_value>]
[Arguments]
o decomp
    type: switch
    default value: None 
o effort
    type: enumerated(low|std|high|extra)
    default value: std 
o mpi
    type: switch
    default value: None 
o parallel
    type: integer
    default value: None
```

## design.rtlsyn

```
[Syntax]
   design.rtlsyn  [-effort <effort_value>] [-keep_hier] [-top <top_value>]
[Arguments]
o effort
    type: enumerated(low|std|high)
    default value: None 
o keep_hier
    type: switch
    default value: None 
o top
    type: string
    default value: None
```

## design.save

```
[Syntax]
   design.save  <filename> [-inc_tcst] [-no_compress]
[Arguments]
o filename
    type: string
    default value: None 
o inc_tcst
    type: switch
    default value: None 
o no_compress
    type: switch
    default value: None
```

## design.saveSdb

```
[Syntax]
   design.saveSdb  <filename> [-no_compress]
[Arguments]
o filename
    type: string
    default value: None 
o no_compress
    type: switch
    default value: None
```

## design.tdomap

```
[Syntax]
   design.tdomap  [-effort <effort_value>] [-lutpk <lutpk_value>] [-max_cut <max_cut_value>]
[Arguments]
o effort
    type: enumerated(low|std|high)
    default value: None 
o lutpk
    type: integer
    default value: None 
o max_cut
    type: integer
    default value: None
```

## design.tmr

(无 help 条目)

## design.unmap

(无 help 条目)

## designImportExec

(无 help 条目)

## dict

(无 help 条目)

## diff_hqprj_hqins_file

(无 help 条目)

## dir

(无 help 条目)

## drc.seal.io.check

```
[Syntax]
   drc.seal.io.check 
[Arguments]
```

## drc.user_pin_assignment

```
[Syntax]
   drc.user_pin_assignment  <filename>
[Arguments]
o filename
    type: string
    default value: None
```

## dsgn.lo.area

(无 help 条目)

## dsgn.lo.timing

(无 help 条目)

## dsgn.map

(无 help 条目)

## dsgn.rsyn

```
[Syntax]
   dsgn.rsyn  [-effort <effort_value>] [-keep_hier] [-top <top_value>]
[Arguments]
o effort
    type: enumerated(low|std|high)
    default value: None 
o keep_hier
    type: switch
    default value: None 
o top
    type: string
    default value: None
```

## dv.bank.list

```
[Syntax]
   dv.bank.list 
[Arguments]
```

## dv.derating.add

```
[Syntax]
   dv.derating.add  <name> <info>
[Arguments]
o name
    type: string
    default value: None 
o info
    type: string
    default value: None
```

## dv.derating.get

```
[Syntax]
   dv.derating.get  <name> <voltage> <temprature>
[Arguments]
o name
    type: string
    default value: None 
o voltage
    type: double
    default value: None 
o temprature
    type: double
    default value: None
```

## dv.derating.report

```
[Syntax]
   dv.derating.report  [<name>]
[Arguments]
o name
    type: string
    default value: None
```

## dv.get_pin_bank

```
[Syntax]
   dv.get_pin_bank  <pin_name>
[Arguments]
o pin_name
    type: string
    default value: None
```

## dv.get_pin_desc

```
[Syntax]
   dv.get_pin_desc  <pin_name>
[Arguments]
o pin_name
    type: string
    default value: None
```

## dv.get_pin_loc

```
[Syntax]
   dv.get_pin_loc  <pin_name>
[Arguments]
o pin_name
    type: string
    default value: None
```

## dv.info

```
[Syntax]
   dv.info  <what> [-orgdev]
[Arguments]
o what
    type: enumerated(name|vendor|family|die|package|speedgrade|condition|vdir|fdir)
    default value: name 
o orgdev
    type: switch
    default value: None
```

## dv.lib.filter

```
[Syntax]
   dv.lib.filter  <lib> <listf>
[Arguments]
o lib
    type: object_reference
    default value: None 
o listf
    type: string
    default value: None
```

## dv.macro.spot.list

```
[Syntax]
   dv.macro.spot.list 
[Arguments]
```

## dv.pinloc.list

```
[Syntax]
   dv.pinloc.list 
[Arguments]
```

## dv.query

```
[Syntax]
   dv.query  [<family>] [-order_parts]
[Arguments]
o family
    type: string
    default value: None 
o order_parts
    type: switch
    default value: None
```

## dv.resource.limit.clear

```
[Syntax]
   dv.resource.limit.clear 
[Arguments]
```

## dv.resource.limit.query

```
[Syntax]
   dv.resource.limit.query  <name>
[Arguments]
o name
    type: string
    default value: None
```

## dv.resource.limit.set

```
[Syntax]
   dv.resource.limit.set  <name> <limit>
[Arguments]
o name
    type: string
    default value: None 
o limit
    type: integer
    default value: None
```

## dv.setup

```
[Syntax]
   dv.setup  <family> [<dev>]
[Arguments]
o family
    type: string
    default value: None 
o dev
    type: string
    default value: None
```

## dv.sloc.gen

```
[Syntax]
   dv.sloc.gen  <type> <row> <col>
[Arguments]
o type
    type: string
    default value: None 
o row
    type: integer
    default value: None 
o col
    type: integer
    default value: None
```

## dv.sloc.tran

```
[Syntax]
   dv.sloc.tran  <loc_name>
[Arguments]
o loc_name
    type: string
    default value: None
```

## dv.vccio.list

```
[Syntax]
   dv.vccio.list  <bank>
[Arguments]
o bank
    type: string
    default value: None
```

## eco.clear_clock

```
[Syntax]
   eco.clear_clock 
[Arguments]
```

## eco.end

```
[Syntax]
   eco.end 
[Arguments]
```

## eco.forbid_route_node

```
[Syntax]
   eco.forbid_route_node  <node>
[Arguments]
o node
    type: string
    default value: None
```

## eco.icdelay.annotate

```
[Syntax]
   eco.icdelay.annotate 
[Arguments]
```

## eco.init

```
[Syntax]
   eco.init 
[Arguments]
```

## eco.place

```
[Syntax]
   eco.place 
[Arguments]
```

## eco.read

```
[Syntax]
   eco.read  <file_name>
[Arguments]
o file_name
    type: string
    default value: None
```

## eco.report_pin_delay

```
[Syntax]
   eco.report_pin_delay 
[Arguments]
```

## eco.route

```
[Syntax]
   eco.route 
[Arguments]
```

## eco.set_clock

```
[Syntax]
   eco.set_clock  <net> <type> [-index <index_value>]
[Arguments]
o net
    type: object_reference
    default value: None 
o type
    type: enumerated(pclk|sclk)
    default value: None 
o index
    type: integer
    default value: None
```

## eco.set_route_points

```
[Syntax]
   eco.set_route_points  <net> <node_list> <pin_list>
[Arguments]
o net
    type: string
    default value: None 
o node_list
    type: string
    default value: None 
o pin_list
    type: string
    default value: None
```

## eco.signal_probe

```
[Syntax]
   eco.signal_probe  <net> <loc> [-inv]
[Arguments]
o net
    type: string
    default value: None 
o loc
    type: string
    default value: None 
o inv
    type: switch
    default value: None
```

## eco.signal_probe.xist.seal

```
[Syntax]
   eco.signal_probe.xist.seal  <net> <loc> [-inv]
[Arguments]
o net
    type: string
    default value: None 
o loc
    type: string
    default value: None 
o inv
    type: switch
    default value: None
```

## eco.signal_probe.xist.sealion

```
[Syntax]
   eco.signal_probe.xist.sealion  <net> <loc> [-inv]
[Arguments]
o net
    type: string
    default value: None 
o loc
    type: string
    default value: None 
o inv
    type: switch
    default value: None
```

## edif.read

```
[Syntax]
   edif.read  <filename> [-family <family_value>] [-lut_combine] [-mcnc] [-unmap]
[Arguments]
o filename
    type: string
    default value: None 
o family
    type: string
    default value: None 
o lut_combine
    type: switch
    default value: None 
o mcnc
    type: switch
    default value: None 
o unmap
    type: switch
    default value: None
```

## edif.write

```
[Syntax]
   edif.write  <filename> [-family <family_value>]
[Arguments]
o filename
    type: string
    default value: None 
o family
    type: string
    default value: None
```

## encoding

(无 help 条目)

## eof

(无 help 条目)

## error

(无 help 条目)

## eval

(无 help 条目)

## examine_hqins_gen_files

(无 help 条目)

## examine_hqvio_gen_files

(无 help 条目)

## exec

(无 help 条目)

## exec4globalSet

(无 help 条目)

## execImportGlobalSet

(无 help 条目)

## exit

(无 help 条目)

## expr

(无 help 条目)

## extr_bitdata

(无 help 条目)

## extr_wns

(无 help 条目)

## fault.inject

```
[Syntax]
   fault.inject  <type>
[Arguments]
o type
    type: enumerated(assert|crash|exception)
    default value: None
```

## fblocked

(无 help 条目)

## fconfigure

(无 help 条目)

## fcopy

(无 help 条目)

## file

(无 help 条目)

## file_is_newer

(无 help 条目)

## fileevent

(无 help 条目)

## flowcfg.algo.query

```
[Syntax]
   flowcfg.algo.query  [-all] [-packer] [-placer]
[Arguments]
o all
    type: switch
    default value: None 
o packer
    type: switch
    default value: None 
o placer
    type: switch
    default value: None
```

## flowcfg.algo.set

```
[Syntax]
   flowcfg.algo.set  [-packer <packer_value>] [-placer <placer_value>] [-reset_all]
[Arguments]
o packer
    type: enumerated(std|lpp)
    default value: None 
o placer
    type: enumerated(std|ap|lpp)
    default value: None 
o reset_all
    type: switch
    default value: None
```

## flush

(无 help 条目)

## for

(无 help 条目)

## foreach

(无 help 条目)

## format

(无 help 条目)

## fsm.optimize

```
[Syntax]
   fsm.optimize 
[Arguments]
```

## fsm.set

```
[Syntax]
   fsm.set  [-aload <aload_value>] [-encoding <encoding_value>] [-extr_ce <extr_ce_value>] [-max_in_bits <max_in_bits_value>] [-max_onest_in_bits <max_onest_in_bits_value>] [-max_out_bits <max_out_bits_value>] [-max_out_bits_stt <max_out_bits_stt_value>] [-max_states <max_states_value>] [-reset_all] [-stmap_file <stmap_file_value>]
[Arguments]
o aload
    type: enumerated(on|off)
    default value: None 
o encoding
    type: enumerated(auto|onehot|binary|gray|johnson)
    default value: None 
o extr_ce
    type: enumerated(on|off)
    default value: None 
o max_in_bits
    type: integer
    default value: None 
o max_onest_in_bits
    type: integer
    default value: None 
o max_out_bits
    type: integer
    default value: None 
o max_out_bits_stt
    type: integer
    default value: None 
o max_states
    type: integer
    default value: None 
o reset_all
    type: switch
    default value: None 
o stmap_file
    type: string
    default value: None
```

## generateRpt

(无 help 条目)

## get.lutnum

```
[Syntax]
   get.lutnum 
[Arguments]
```

## getTopModuleName

(无 help 条目)

## get_bitcontent_sizes

(无 help 条目)

## get_cells

```
[Syntax]
   get_cells  [<patterns>] [-hierarchical] [-hsc <hsc_value>] [-nocase] [-of_objects <of_objects_value>] [-regexp]
[Arguments]
o patterns
    type: string
    default value: None 
o hierarchical
    type: switch
    default value: None 
o hsc
    type: string
    default value: None 
o nocase
    type: switch
    default value: None 
o of_objects
    type: string
    default value: None 
o regexp
    type: switch
    default value: None
```

## get_clocks

```
[Syntax]
   get_clocks  <patterns> [-nocase] [-regexp]
[Arguments]
o patterns
    type: string
    default value: None 
o nocase
    type: switch
    default value: None 
o regexp
    type: switch
    default value: None
```

## get_curr_hqprj_abspath

(无 help 条目)

## get_curr_hqprj_file

(无 help 条目)

## get_dot_hqins_file

(无 help 条目)

## get_dot_hqins_save_file

(无 help 条目)

## get_effort

(无 help 条目)

## get_file_upd_stat

(无 help 条目)

## get_hqexe_for_ins

(无 help 条目)

## get_hqins_chkok_file

(无 help 条目)

## get_hqprj_save_file

(无 help 条目)

## get_hqui_vlog_inc_paths

(无 help 条目)

## get_multi_inst_nviews

(无 help 条目)

## get_nets

```
[Syntax]
   get_nets  [<patterns>] [-hierarchical] [-hsc <hsc_value>] [-nocase] [-of_objects <of_objects_value>] [-regexp]
[Arguments]
o patterns
    type: string
    default value: None 
o hierarchical
    type: switch
    default value: None 
o hsc
    type: string
    default value: None 
o nocase
    type: switch
    default value: None 
o of_objects
    type: string
    default value: None 
o regexp
    type: switch
    default value: None
```

## get_norm_time_th

(无 help 条目)

## get_obj_loc

(无 help 条目)

## get_os_info

(无 help 条目)

## get_pin_external_loc_from_internal

(无 help 条目)

## get_pin_internal_loc_from_external

(无 help 条目)

## get_pins

```
[Syntax]
   get_pins  [<patterns>] [-hierarchical] [-hsc <hsc_value>] [-nocase] [-of_objects <of_objects_value>] [-regexp]
[Arguments]
o patterns
    type: string
    default value: None 
o hierarchical
    type: switch
    default value: None 
o hsc
    type: string
    default value: None 
o nocase
    type: switch
    default value: None 
o of_objects
    type: string
    default value: None 
o regexp
    type: switch
    default value: None
```

## get_ports

```
[Syntax]
   get_ports  <patterns> [-nocase] [-regexp]
[Arguments]
o patterns
    type: string
    default value: None 
o nocase
    type: switch
    default value: None 
o regexp
    type: switch
    default value: None
```

## get_wns_stat_msgid

(无 help 条目)

## get_xist_device_id

(无 help 条目)

## gets

(无 help 条目)

## glob

(无 help 条目)

## global

(无 help 条目)

## gui.run

```
[Syntax]
   gui.run  [-srv]
[Arguments]
o srv
    type: switch
    default value: None
```

## help

```
[Syntax]
   help  [<cmd>]
[Arguments]
o cmd
    type: string
    default value: None
```

## hinfo.test

```
[Syntax]
   hinfo.test  [-detail]
[Arguments]
o detail
    type: switch
    default value: None
```

## hqBitgenExec

(无 help 条目)

## hqPackExec

(无 help 条目)

## hqPlaceExec

(无 help 条目)

## hqRouteExec

(无 help 条目)

## hqRtlSysExec

(无 help 条目)

## hqfpga.org.unknown

(无 help 条目)

## hqprj2tcl

```
[Syntax]
   hqprj2tcl  <hqprj_file> <t_file>
[Arguments]
o hqprj_file
    type: string
    default value: None 
o t_file
    type: string
    default value: run_hqprj.tcl
```

## hqui_doJob

(无 help 条目)

## hqui_get_dev_name

(无 help 条目)

## hqui_jobReader

(无 help 条目)

## hqui_print

(无 help 条目)

## hqvars.clear

```
[Syntax]
   hqvars.clear 
[Arguments]
```

## hqvars.rtfo.clear

```
[Syntax]
   hqvars.rtfo.clear 
[Arguments]
```

## if

(无 help 条目)

## impl.bitgen.lattice.xo2

```
[Syntax]
   impl.bitgen.lattice.xo2  <bitfile> [-bin] [-compress] [-config <config_value>] [-nocrc] [-rbin] [-v]
[Arguments]
o bitfile
    type: string
    default value: None 
o bin
    type: switch
    default value: None 
o compress
    type: switch
    default value: None 
o config
    type: string
    default value: None 
o nocrc
    type: switch
    default value: None 
o rbin
    type: switch
    default value: None 
o v
    type: switch
    default value: None
```

## impl.bitgen.xist.seal

```
[Syntax]
   impl.bitgen.xist.seal  <bitfile> [-bin] [-compress] [-compress_line_len <compress_line_len_value>] [-config <config_value>] [-dclk <dclk_value>] [-framecrc] [-fuse_protect] [-i2c] [-nocrc] [-pcie_cfg <pcie_cfg_value>] [-rbin] [-sspi] [-trans_mode] [-v]
[Arguments]
o bitfile
    type: string
    default value: None 
o bin
    type: switch
    default value: None 
o compress
    type: switch
    default value: None 
o compress_line_len
    type: integer
    default value: None 
o config
    type: string
    default value: None 
o dclk
    type: string
    default value: None 
o framecrc
    type: switch
    default value: None 
o fuse_protect
    type: switch
    default value: None 
o i2c
    type: switch
    default value: None 
o nocrc
    type: switch
    default value: None 
o pcie_cfg
    type: integer
    default value: None 
o rbin
    type: switch
    default value: None 
o sspi
    type: switch
    default value: None 
o trans_mode
    type: switch
    default value: None 
o v
    type: switch
    default value: None
```

## impl.bitgen.xist.sealion

```
[Syntax]
   impl.bitgen.xist.sealion  <bitfile> [-bin] [-compress] [-compress_line_len <compress_line_len_value>] [-config <config_value>] [-dclk <dclk_value>] [-ext_crystal] [-framecrc] [-fuse_protect] [-i2c] [-nocrc] [-rbin] [-rxfb] [-sspi] [-trans_mode] [-v]
[Arguments]
o bitfile
    type: string
    default value: None 
o bin
    type: switch
    default value: None 
o compress
    type: switch
    default value: None 
o compress_line_len
    type: integer
    default value: None 
o config
    type: string
    default value: None 
o dclk
    type: string
    default value: None 
o ext_crystal
    type: switch
    default value: None 
o framecrc
    type: switch
    default value: None 
o fuse_protect
    type: switch
    default value: None 
o i2c
    type: switch
    default value: None 
o nocrc
    type: switch
    default value: None 
o rbin
    type: switch
    default value: None 
o rxfb
    type: switch
    default value: None 
o sspi
    type: switch
    default value: None 
o trans_mode
    type: switch
    default value: None 
o v
    type: switch
    default value: None
```

## impl.bitgen.xist.shark

```
[Syntax]
   impl.bitgen.xist.shark  <bitfile> [-bin] [-compress] [-compress_line_len <compress_line_len_value>] [-config <config_value>] [-dclk <dclk_value>] [-framecrc] [-fuse_protect] [-i2c] [-nocrc] [-pcie_cfg <pcie_cfg_value>] [-rbin] [-sspi] [-trans_mode] [-v]
[Arguments]
o bitfile
    type: string
    default value: None 
o bin
    type: switch
    default value: None 
o compress
    type: switch
    default value: None 
o compress_line_len
    type: integer
    default value: None 
o config
    type: string
    default value: None 
o dclk
    type: string
    default value: None 
o framecrc
    type: switch
    default value: None 
o fuse_protect
    type: switch
    default value: None 
o i2c
    type: switch
    default value: None 
o nocrc
    type: switch
    default value: None 
o pcie_cfg
    type: integer
    default value: None 
o rbin
    type: switch
    default value: None 
o sspi
    type: switch
    default value: None 
o trans_mode
    type: switch
    default value: None 
o v
    type: switch
    default value: None
```

## impl.bitgen.xist.slxo2

```
[Syntax]
   impl.bitgen.xist.slxo2  <bitfile> [-bin] [-compress] [-config <config_value>] [-nocrc] [-rbin] [-v]
[Arguments]
o bitfile
    type: string
    default value: None 
o bin
    type: switch
    default value: None 
o compress
    type: switch
    default value: None 
o config
    type: string
    default value: None 
o nocrc
    type: switch
    default value: None 
o rbin
    type: switch
    default value: None 
o v
    type: switch
    default value: None
```

## impl.buffer

```
[Syntax]
   impl.buffer  [-fanout_limit <fanout_limit_value>] [-timing]
[Arguments]
o fanout_limit
    type: integer
    default value: 1000 
o timing
    type: switch
    default value: None
```

## impl.cong

```
[Syntax]
   impl.cong 
[Arguments]
```

## impl.decomp

```
[Syntax]
   impl.decomp  [-max_cut <max_cut_value>]
[Arguments]
o max_cut
    type: integer
    default value: None
```

## impl.drc.post_map

```
[Syntax]
   impl.drc.post_map 
[Arguments]
```

## impl.drc.pre_pack

```
[Syntax]
   impl.drc.pre_pack 
[Arguments]
```

## impl.guide.query

```
[Syntax]
   impl.guide.query  [<object>] [-dont_dup] [-dont_dup_ff] [-dont_merge_ff] [-dont_retime] [-dont_touch] [-dont_use] [-fanout_limit] [-keep_hier] [-value_only]
[Arguments]
o object
    type: object_reference
    default value: None 
o dont_dup
    type: switch
    default value: None 
o dont_dup_ff
    type: switch
    default value: None 
o dont_merge_ff
    type: switch
    default value: None 
o dont_retime
    type: switch
    default value: None 
o dont_touch
    type: switch
    default value: None 
o dont_use
    type: switch
    default value: None 
o fanout_limit
    type: switch
    default value: None 
o keep_hier
    type: switch
    default value: None 
o value_only
    type: switch
    default value: None
```

## impl.guide.set

```
[Syntax]
   impl.guide.set  [<object>] [-dont_dup] [-dont_dup_ff] [-dont_merge_ff] [-dont_retime] [-dont_touch] [-dont_use] [-fanout_limit <fanout_limit_value>] [-keep_hier]
[Arguments]
o object
    type: object_reference
    default value: None 
o dont_dup
    type: switch
    default value: None 
o dont_dup_ff
    type: switch
    default value: None 
o dont_merge_ff
    type: switch
    default value: None 
o dont_retime
    type: switch
    default value: None 
o dont_touch
    type: switch
    default value: None 
o dont_use
    type: switch
    default value: None 
o fanout_limit
    type: integer
    default value: None 
o keep_hier
    type: switch
    default value: None
```

## impl.guide.unset

```
[Syntax]
   impl.guide.unset  [<object>] [-all] [-dont_dup] [-dont_dup_ff] [-dont_merge_ff] [-dont_retime] [-dont_touch] [-dont_use] [-fanout_limit] [-keep_hier]
[Arguments]
o object
    type: object_reference
    default value: None 
o all
    type: switch
    default value: None 
o dont_dup
    type: switch
    default value: None 
o dont_dup_ff
    type: switch
    default value: None 
o dont_merge_ff
    type: switch
    default value: None 
o dont_retime
    type: switch
    default value: None 
o dont_touch
    type: switch
    default value: None 
o dont_use
    type: switch
    default value: None 
o fanout_limit
    type: switch
    default value: None 
o keep_hier
    type: switch
    default value: None
```

## impl.legalize

```
[Syntax]
   impl.legalize  [-phase <phase_value>]
[Arguments]
o phase
    type: enumerated(map|place|route)
    default value: place
```

## impl.legalize.map.cme.m5

```
[Syntax]
   impl.legalize.map.cme.m5 
[Arguments]
```

## impl.legalize.map.csmsc.hwdv

```
[Syntax]
   impl.legalize.map.csmsc.hwdv 
[Arguments]
```

## impl.legalize.map.csmsc.hwdv2

```
[Syntax]
   impl.legalize.map.csmsc.hwdv2 
[Arguments]
```

## impl.legalize.map.csmsc.hwdv4

```
[Syntax]
   impl.legalize.map.csmsc.hwdv4 
[Arguments]
```

## impl.legalize.map.etech.yxc3

```
[Syntax]
   impl.legalize.map.etech.yxc3 
[Arguments]
```

## impl.legalize.map.lattice.xo2

```
[Syntax]
   impl.legalize.map.lattice.xo2 
[Arguments]
```

## impl.legalize.map.xilinx.virtex

```
[Syntax]
   impl.legalize.map.xilinx.virtex 
[Arguments]
```

## impl.legalize.map.xilinx.virtex2

```
[Syntax]
   impl.legalize.map.xilinx.virtex2 
[Arguments]
```

## impl.legalize.map.xilinx.virtex4

```
[Syntax]
   impl.legalize.map.xilinx.virtex4 
[Arguments]
```

## impl.legalize.map.xilinx.virtex5

```
[Syntax]
   impl.legalize.map.xilinx.virtex5 
[Arguments]
```

## impl.legalize.map.xist.seal

```
[Syntax]
   impl.legalize.map.xist.seal 
[Arguments]
```

## impl.legalize.map.xist.sealion

```
[Syntax]
   impl.legalize.map.xist.sealion 
[Arguments]
```

## impl.legalize.map.xist.sl2

```
[Syntax]
   impl.legalize.map.xist.sl2 
[Arguments]
```

## impl.legalize.map.xist.slxo2

```
[Syntax]
   impl.legalize.map.xist.slxo2 
[Arguments]
```

## impl.looptdo.xist.seal

```
[Syntax]
   impl.looptdo.xist.seal  [-end_stage <end_stage_value>] [-hold_slack <hold_slack_value>] [-j <j_value>] [-max_slack <max_slack_value>] [-n <n_value>] [-rundir <rundir_value>] [-sdc <sdc_value>] [-sdc4sta <sdc4sta_value>] [-slack <slack_value>] [-timeout <timeout_value>] [-tprefix <tprefix_value>] [-upc <upc_value>] [-wl <wl_value>]
[Arguments]
o end_stage
    type: string
    default value: None 
o hold_slack
    type: double
    default value: None 
o j
    type: integer
    default value: 1 
o max_slack
    type: double
    default value: None 
o n
    type: integer
    default value: None 
o rundir
    type: string
    default value: None 
o sdc
    type: string
    default value: None 
o sdc4sta
    type: string
    default value: None 
o slack
    type: double
    default value: None 
o timeout
    type: integer
    default value: 1800 
o tprefix
    type: string
    default value: None 
o upc
    type: string
    default value: None 
o wl
    type: double
    default value: None
```

## impl.looptdo.xist.sealion

```
[Syntax]
   impl.looptdo.xist.sealion  [-end_stage <end_stage_value>] [-hold_slack <hold_slack_value>] [-j <j_value>] [-max_slack <max_slack_value>] [-n <n_value>] [-rundir <rundir_value>] [-sdc <sdc_value>] [-sdc4sta <sdc4sta_value>] [-slack <slack_value>] [-timeout <timeout_value>] [-tprefix <tprefix_value>] [-upc <upc_value>] [-wl <wl_value>]
[Arguments]
o end_stage
    type: string
    default value: None 
o hold_slack
    type: double
    default value: None 
o j
    type: integer
    default value: 1 
o max_slack
    type: double
    default value: None 
o n
    type: integer
    default value: None 
o rundir
    type: string
    default value: None 
o sdc
    type: string
    default value: None 
o sdc4sta
    type: string
    default value: None 
o slack
    type: double
    default value: None 
o timeout
    type: integer
    default value: 1800 
o tprefix
    type: string
    default value: None 
o upc
    type: string
    default value: None 
o wl
    type: double
    default value: None
```

## impl.looptdo.xist.shark

```
[Syntax]
   impl.looptdo.xist.shark  [-end_stage <end_stage_value>] [-hold_slack <hold_slack_value>] [-j <j_value>] [-max_slack <max_slack_value>] [-n <n_value>] [-rundir <rundir_value>] [-sdc <sdc_value>] [-sdc4sta <sdc4sta_value>] [-slack <slack_value>] [-timeout <timeout_value>] [-tprefix <tprefix_value>] [-upc <upc_value>] [-wl <wl_value>]
[Arguments]
o end_stage
    type: string
    default value: None 
o hold_slack
    type: double
    default value: None 
o j
    type: integer
    default value: 1 
o max_slack
    type: double
    default value: None 
o n
    type: integer
    default value: None 
o rundir
    type: string
    default value: None 
o sdc
    type: string
    default value: None 
o sdc4sta
    type: string
    default value: None 
o slack
    type: double
    default value: None 
o timeout
    type: integer
    default value: 1800 
o tprefix
    type: string
    default value: None 
o upc
    type: string
    default value: None 
o wl
    type: double
    default value: None
```

## impl.lutpair

```
[Syntax]
   impl.lutpair 
[Arguments]
```

## impl.map

```
[Syntax]
   impl.map  [-effort <effort_value>] [-lutpk <lutpk_value>] [-max_cut <max_cut_value>] [-mode <mode_value>] [-no_speedup]
[Arguments]
o effort
    type: enumerated(extra|high|std|low)
    default value: std 
o lutpk
    type: integer
    default value: 1 
o max_cut
    type: integer
    default value: None 
o mode
    type: enumerated(area|timing)
    default value: area 
o no_speedup
    type: switch
    default value: None
```

## impl.pack

```
[Syntax]
   impl.pack  [-ap_gpack] [-area] [-effort <effort_value>] [-iob_dff <iob_dff_value>] [-lpp] [-ratio <ratio_value>]
[Arguments]
o ap_gpack
    type: switch
    default value: None 
o area
    type: switch
    default value: None 
o effort
    type: enumerated(low|std|high)
    default value: std 
o iob_dff
    type: integer
    default value: None 
o lpp
    type: switch
    default value: None 
o ratio
    type: integer
    default value: None
```

## impl.pack.finalize

```
[Syntax]
   impl.pack.finalize 
[Arguments]
```

## impl.pack.seal2shark

```
[Syntax]
   impl.pack.seal2shark 
[Arguments]
```

## impl.part

```
[Syntax]
   impl.part 
[Arguments]
```

## impl.place

```
[Syntax]
   impl.place  [-ap] [-ap_kw2] [-ap_npl] [-eco] [-effort <effort_value>] [-np] [-seed <seed_value>]
[Arguments]
o ap
    type: switch
    default value: None 
o ap_kw2
    type: switch
    default value: None 
o ap_npl
    type: switch
    default value: None 
o eco
    type: switch
    default value: None 
o effort
    type: enumerated(low|std|high)
    default value: std 
o np
    type: switch
    default value: None 
o seed
    type: integer
    default value: None
```

## impl.retarget

```
[Syntax]
   impl.retarget 
[Arguments]
```

## impl.route

```
[Syntax]
   impl.route  [-effort <effort_value>] [-mpi]
[Arguments]
o effort
    type: enumerated(low|std|high)
    default value: std 
o mpi
    type: switch
    default value: None
```

## incr

(无 help 条目)

## info

(无 help 条目)

## info.SdbUdbversion

```
[Syntax]
   info.SdbUdbversion  [<file>]
[Arguments]
o file
    type: string
    default value: None
```

## info.memusage

```
[Syntax]
   info.memusage  [-peak]
[Arguments]
o peak
    type: switch
    default value: None
```

## info.udbversion

```
[Syntax]
   info.udbversion  [<file>]
[Arguments]
o file
    type: string
    default value: None
```

## insight.check

```
[Syntax]
   insight.check  <ip_type>
[Arguments]
o ip_type
    type: enumerated(has_vio|has_vla)
    default value: None
```

## insight.clear

```
[Syntax]
   insight.clear 
[Arguments]
```

## insight.debugip.create

```
[Syntax]
   insight.debugip.create  <overflow> <mwin> [-f <f_value>] [-ins <ins_value>]
[Arguments]
o overflow
    type: string
    default value: None 
o mwin
    type: string
    default value: None 
o f
    type: string
    default value: None 
o ins
    type: string
    default value: None
```

## insight.dump

```
[Syntax]
   insight.dump  [-f <f_value>]
[Arguments]
o f
    type: string
    default value: None
```

## insight.end

```
[Syntax]
   insight.end 
[Arguments]
```

## insight.info.udm

```
[Syntax]
   insight.info.udm 
[Arguments]
```

## insight.jtag

```
[Syntax]
   insight.jtag  <cmd> [-cmdopt <cmdopt_value>]
[Arguments]
o cmd
    type: enumerated(cable|bsdl|detect|part)
    default value: None 
o cmdopt
    type: string
    default value: None
```

## insight.la.condition

```
[Syntax]
   insight.la.condition  <cmd> <la> [-cond <cond_value>] [-op <op_value>] [-operand <operand_value>]
[Arguments]
o cmd
    type: enumerated(get|set)
    default value: None 
o la
    type: integer
    default value: None 
o cond
    type: integer
    default value: None 
o op
    type: string
    default value: None 
o operand
    type: string
    default value: None
```

## insight.la.initcmds

```
[Syntax]
   insight.la.initcmds 
[Arguments]
```

## insight.la.offset

```
[Syntax]
   insight.la.offset  <cmd> <la> [-offset <offset_value>]
[Arguments]
o cmd
    type: enumerated(get|set)
    default value: None 
o la
    type: integer
    default value: None 
o offset
    type: integer
    default value: None
```

## insight.la.reset

```
[Syntax]
   insight.la.reset  <la>
[Arguments]
o la
    type: integer
    default value: None
```

## insight.la.status

```
[Syntax]
   insight.la.status  <la>
[Arguments]
o la
    type: integer
    default value: None
```

## insight.la.waveform

```
[Syntax]
   insight.la.waveform  <la> [-out <out_value>]
[Arguments]
o la
    type: integer
    default value: None 
o out
    type: string
    default value: None
```

## insight.load

```
[Syntax]
   insight.load  <ddffile>
[Arguments]
o ddffile
    type: string
    default value: None
```

## insight.sealion.la.condition

```
[Syntax]
   insight.sealion.la.condition  <cmd> <la> [-cond <cond_value>] [-op <op_value>] [-operand <operand_value>]
[Arguments]
o cmd
    type: enumerated(get|set)
    default value: None 
o la
    type: integer
    default value: None 
o cond
    type: integer
    default value: None 
o op
    type: string
    default value: None 
o operand
    type: string
    default value: None
```

## insight.sealion.la.condition_te

```
[Syntax]
   insight.sealion.la.condition_te  <cmd> <la> <is_continuous> <is_te> <expr_op> [-cond <cond_value>] [-cond_path <cond_path_value>] [-op <op_value>] [-operand <operand_value>] [-te <te_value>]
[Arguments]
o cmd
    type: enumerated(get|set)
    default value: None 
o la
    type: integer
    default value: None 
o is_continuous
    type: string
    default value: None 
o is_te
    type: string
    default value: None 
o expr_op
    type: string
    default value: None 
o cond
    type: integer
    default value: None 
o cond_path
    type: string
    default value: None 
o op
    type: string
    default value: None 
o operand
    type: string
    default value: None 
o te
    type: string
    default value: None
```

## insight.sealion.la.initcmds

```
[Syntax]
   insight.sealion.la.initcmds 
[Arguments]
```

## insight.sealion.la.mem

```
[Syntax]
   insight.sealion.la.mem  <la>
[Arguments]
o la
    type: integer
    default value: None
```

## insight.sealion.la.mw.condition_te

```
[Syntax]
   insight.sealion.la.mw.condition_te  <cmd> <is_continuous> <is_te> <expr_op> [-cond <cond_value>] [-cond_path <cond_path_value>] [-la <la_value>] [-op <op_value>] [-operand <operand_value>] [-te <te_value>]
[Arguments]
o cmd
    type: enumerated(set|get)
    default value: None 
o is_continuous
    type: string
    default value: None 
o is_te
    type: string
    default value: None 
o expr_op
    type: string
    default value: None 
o cond
    type: integer
    default value: None 
o cond_path
    type: string
    default value: None 
o la
    type: integer
    default value: None 
o op
    type: string
    default value: None 
o operand
    type: string
    default value: None 
o te
    type: string
    default value: None
```

## insight.sealion.la.mw.debug_status

```
[Syntax]
   insight.sealion.la.mw.debug_status  [-la <la_value>] [-type <type_value>]
[Arguments]
o la
    type: integer
    default value: None 
o type
    type: enumerated(state|window_num_d|triggered_window_num|start_addr|end_addr|all)
    default value: None
```

## insight.sealion.la.mw.offset

```
[Syntax]
   insight.sealion.la.mw.offset  <cmd> [-la <la_value>] [-offset <offset_value>]
[Arguments]
o cmd
    type: enumerated(get|set)
    default value: None 
o la
    type: integer
    default value: None 
o offset
    type: integer
    default value: None
```

## insight.sealion.la.mw.reset

```
[Syntax]
   insight.sealion.la.mw.reset  [-la <la_value>]
[Arguments]
o la
    type: integer
    default value: None
```

## insight.sealion.la.mw.status

```
[Syntax]
   insight.sealion.la.mw.status  [-la <la_value>]
[Arguments]
o la
    type: integer
    default value: None
```

## insight.sealion.la.mw.waveform

```
[Syntax]
   insight.sealion.la.mw.waveform  [-hier <hier_value>] [-la <la_value>] [-num <num_value>] [-out <out_value>]
[Arguments]
o hier
    type: integer
    default value: None 
o la
    type: integer
    default value: None 
o num
    type: integer
    default value: None 
o out
    type: string
    default value: None
```

## insight.sealion.la.mw.window_num

```
[Syntax]
   insight.sealion.la.mw.window_num  <cmd> [-la <la_value>] [-num <num_value>]
[Arguments]
o cmd
    type: enumerated(set|get)
    default value: None 
o la
    type: integer
    default value: None 
o num
    type: integer
    default value: None
```

## insight.sealion.la.offset

```
[Syntax]
   insight.sealion.la.offset  <cmd> <la> [-offset <offset_value>]
[Arguments]
o cmd
    type: enumerated(get|set)
    default value: None 
o la
    type: integer
    default value: None 
o offset
    type: integer
    default value: None
```

## insight.sealion.la.reset

```
[Syntax]
   insight.sealion.la.reset  <la>
[Arguments]
o la
    type: integer
    default value: None
```

## insight.sealion.la.status

```
[Syntax]
   insight.sealion.la.status  <la>
[Arguments]
o la
    type: integer
    default value: None
```

## insight.sealion.la.waveform

```
[Syntax]
   insight.sealion.la.waveform  <la> <hier> [-out <out_value>]
[Arguments]
o la
    type: integer
    default value: None 
o hier
    type: integer
    default value: None 
o out
    type: string
    default value: None
```

## insight.sealion.load

```
[Syntax]
   insight.sealion.load  <ddffile>
[Arguments]
o ddffile
    type: string
    default value: None
```

## insight.sealion.mla.condition_te

```
[Syntax]
   insight.sealion.mla.condition_te  <cmd> <is_continuous> <is_te> <expr_op> [-cond <cond_value>] [-cond_path <cond_path_value>] [-op <op_value>] [-operand <operand_value>] [-te <te_value>]
[Arguments]
o cmd
    type: enumerated(get|set)
    default value: None 
o is_continuous
    type: string
    default value: None 
o is_te
    type: string
    default value: None 
o expr_op
    type: string
    default value: None 
o cond
    type: integer
    default value: None 
o cond_path
    type: string
    default value: None 
o op
    type: string
    default value: None 
o operand
    type: string
    default value: None 
o te
    type: string
    default value: None
```

## insight.sealion.mla.offset

```
[Syntax]
   insight.sealion.mla.offset  <cmd> [-offset <offset_value>]
[Arguments]
o cmd
    type: enumerated(get|set)
    default value: None 
o offset
    type: string
    default value: None
```

## insight.sealion.mla.reset

```
[Syntax]
   insight.sealion.mla.reset 
[Arguments]
```

## insight.sealion.mla.status

```
[Syntax]
   insight.sealion.mla.status 
[Arguments]
```

## insight.sealion.mlas.status

```
[Syntax]
   insight.sealion.mlas.status 
[Arguments]
```

## insight.sealionjtag

```
[Syntax]
   insight.sealionjtag  <cmd> [-cmdopt <cmdopt_value>]
[Arguments]
o cmd
    type: enumerated(cable|bsdl|detect|part)
    default value: None 
o cmdopt
    type: string
    default value: None
```

## insight.sealionjtag.start

```
[Syntax]
   insight.sealionjtag.start 
[Arguments]
```

## insight.start

```
[Syntax]
   insight.start  <host> <port>
[Arguments]
o host
    type: string
    default value: None 
o port
    type: integer
    default value: None
```

## insight.svf_generator.dump_vcd

```
[Syntax]
   insight.svf_generator.dump_vcd  <la_num> <la_idx> <out_path_prefix> [-diff_info <diff_info_value>] [-is_hier <is_hier_value>] [-is_multi_window <is_multi_window_value>] [-signal_map_path <signal_map_path_value>] [-tdo_path <tdo_path_value>] [-window_num <window_num_value>]
[Arguments]
o la_num
    type: integer
    default value: None 
o la_idx
    type: integer
    default value: None 
o out_path_prefix
    type: string
    default value: None 
o diff_info
    type: string
    default value: None 
o is_hier
    type: enumerated(True|False)
    default value: False 
o is_multi_window
    type: enumerated(True|False)
    default value: False 
o signal_map_path
    type: string
    default value: None 
o tdo_path
    type: string
    default value: None 
o window_num
    type: integer
    default value: 1
```

## insight.svf_generator.jtag_detect

```
[Syntax]
   insight.svf_generator.jtag_detect 
[Arguments]
```

## insight.svf_generator.la_offset

```
[Syntax]
   insight.svf_generator.la_offset  <la_num> <la_idx> <offset> [-is_multi_window <is_multi_window_value>] [-vio_out_value <vio_out_value_value>]
[Arguments]
o la_num
    type: integer
    default value: None 
o la_idx
    type: integer
    default value: None 
o offset
    type: integer
    default value: None 
o is_multi_window
    type: enumerated(True|False)
    default value: False 
o vio_out_value
    type: string
    default value: None
```

## insight.svf_generator.la_reset

```
[Syntax]
   insight.svf_generator.la_reset  <la_num> <la_idx> [-is_multi_window <is_multi_window_value>] [-vio_out_value <vio_out_value_value>]
[Arguments]
o la_num
    type: integer
    default value: None 
o la_idx
    type: integer
    default value: None 
o is_multi_window
    type: enumerated(True|False)
    default value: False 
o vio_out_value
    type: string
    default value: None
```

## insight.svf_generator.la_set_trig_cond

```
[Syntax]
   insight.svf_generator.la_set_trig_cond  <la_num> <la_idx> <is_ct> <expr_op> [-cond_path <cond_path_value>] [-ct_no <ct_no_value>] [-is_continuous <is_continuous_value>] [-is_multi_window <is_multi_window_value>] [-vio_out_value <vio_out_value_value>]
[Arguments]
o la_num
    type: integer
    default value: None 
o la_idx
    type: integer
    default value: None 
o is_ct
    type: enumerated(True|False)
    default value: False 
o expr_op
    type: string
    default value: None 
o cond_path
    type: string
    default value: None 
o ct_no
    type: string
    default value: None 
o is_continuous
    type: enumerated(True|False)
    default value: False 
o is_multi_window
    type: enumerated(True|False)
    default value: False 
o vio_out_value
    type: string
    default value: None
```

## insight.svf_generator.la_status

```
[Syntax]
   insight.svf_generator.la_status  <la_num> <la_idx> [-is_multi_window <is_multi_window_value>] [-vio_out_value <vio_out_value_value>]
[Arguments]
o la_num
    type: integer
    default value: None 
o la_idx
    type: integer
    default value: None 
o is_multi_window
    type: enumerated(True|False)
    default value: False 
o vio_out_value
    type: string
    default value: None
```

## insight.svf_generator.la_status_window

```
[Syntax]
   insight.svf_generator.la_status_window  <la_num> <la_idx> <window_idx> [-vio_out_value <vio_out_value_value>]
[Arguments]
o la_num
    type: integer
    default value: None 
o la_idx
    type: integer
    default value: None 
o window_idx
    type: integer
    default value: None 
o vio_out_value
    type: string
    default value: None
```

## insight.svf_generator.la_waveform

```
[Syntax]
   insight.svf_generator.la_waveform  <la_num> <la_idx> <limit> [-is_multi_window <is_multi_window_value>] [-vio_out_value <vio_out_value_value>]
[Arguments]
o la_num
    type: integer
    default value: None 
o la_idx
    type: integer
    default value: None 
o limit
    type: integer
    default value: None 
o is_multi_window
    type: enumerated(True|False)
    default value: False 
o vio_out_value
    type: string
    default value: None
```

## insight.svf_generator.la_window_num

```
[Syntax]
   insight.svf_generator.la_window_num  <la_num> <la_idx> <window_num> [-vio_out_value <vio_out_value_value>]
[Arguments]
o la_num
    type: integer
    default value: None 
o la_idx
    type: integer
    default value: None 
o window_num
    type: integer
    default value: None 
o vio_out_value
    type: string
    default value: None
```

## insight.svf_generator.start

```
[Syntax]
   insight.svf_generator.start  <svf_file_path> <device_die> [-ddf_file <ddf_file_value>]
[Arguments]
o svf_file_path
    type: string
    default value: None 
o device_die
    type: string
    default value: None 
o ddf_file
    type: string
    default value: None
```

## insight.svf_generator.vio_read

```
[Syntax]
   insight.svf_generator.vio_read  <bit_length>
[Arguments]
o bit_length
    type: integer
    default value: None
```

## insight.svf_generator.vio_write

```
[Syntax]
   insight.svf_generator.vio_write  <value> [-is_multi_window <is_multi_window_value>] [-is_vla_mode <is_vla_mode_value>] [-radix_type <radix_type_value>]
[Arguments]
o value
    type: string
    default value: None 
o is_multi_window
    type: enumerated(True|False)
    default value: False 
o is_vla_mode
    type: enumerated(True|False)
    default value: False 
o radix_type
    type: enumerated(Binary|Octal|Decimal|Hexadecimal)
    default value: Binary
```

## insight.svf_generator.write

```
[Syntax]
   insight.svf_generator.write 
[Arguments]
```

## inst.cfg.check

```
[Syntax]
   inst.cfg.check  <inst> <cfg_name>
[Arguments]
o inst
    type: object_reference
    default value: None 
o cfg_name
    type: string
    default value: None
```

## interp

(无 help 条目)

## ioh.clear_default_iotype

```
[Syntax]
   ioh.clear_default_iotype 
[Arguments]
```

## ioh.get_attr_val

```
[Syntax]
   ioh.get_attr_val  <port_name> <io_std> <attr_name> [-loc <loc_value>]
[Arguments]
o port_name
    type: string
    default value: None 
o io_std
    type: string
    default value: None 
o attr_name
    type: string
    default value: None 
o loc
    type: string
    default value: None
```

## ioh.get_attrs

```
[Syntax]
   ioh.get_attrs  [-upc]
[Arguments]
o upc
    type: switch
    default value: None
```

## ioh.get_default_iotype

```
[Syntax]
   ioh.get_default_iotype 
[Arguments]
```

## ioh.get_default_pullmode

```
[Syntax]
   ioh.get_default_pullmode 
[Arguments]
```

## ioh.get_dpio

```
[Syntax]
   ioh.get_dpio  [-loc]
[Arguments]
o loc
    type: switch
    default value: None
```

## ioh.get_dpio_pullmode

```
[Syntax]
   ioh.get_dpio_pullmode  <dpio_name>
[Arguments]
o dpio_name
    type: string
    default value: None
```

## ioh.get_global_attr

```
[Syntax]
   ioh.get_global_attr  <what>
[Arguments]
o what
    type: enumerated(unused_io|cfgio_pull|unsio_pullmode|trans_mode|all)
    default value: None
```

## ioh.get_iostd

```
[Syntax]
   ioh.get_iostd  <port_name> [-bankvcc <bankvcc_value>] [-loc <loc_value>]
[Arguments]
o port_name
    type: string
    default value: None 
o bankvcc
    type: string
    default value: None 
o loc
    type: string
    default value: None
```

## ioh.get_iotype

```
[Syntax]
   ioh.get_iotype  <port_name> [-bankvcc <bankvcc_value>] [-loc <loc_value>]
[Arguments]
o port_name
    type: string
    default value: None 
o bankvcc
    type: string
    default value: None 
o loc
    type: string
    default value: None
```

## ioh.get_ports

```
[Syntax]
   ioh.get_ports  <dir>
[Arguments]
o dir
    type: enumerated(I|O|B)
    default value: None
```

## ioh.set_default_iotype

```
[Syntax]
   ioh.set_default_iotype  <type>
[Arguments]
o type
    type: enumerated(LVCMOS18|LVCMOS25|LVCMOS33)
    default value: None
```

## ioh.set_default_pullmode

```
[Syntax]
   ioh.set_default_pullmode  <pullmode>
[Arguments]
o pullmode
    type: enumerated(NONE|DOWN|UP|KEEPER)
    default value: None
```

## ioh.set_global_attr

```
[Syntax]
   ioh.set_global_attr  [-cfgio_pull <cfgio_pull_value>] [-trans_mode <trans_mode_value>] [-unsio_pullmode <unsio_pullmode_value>] [-unused_io <unused_io_value>]
[Arguments]
o cfgio_pull
    type: enumerated(on|off)
    default value: on 
o trans_mode
    type: enumerated(on|off)
    default value: None 
o unsio_pullmode
    type: enumerated(NONE|DOWN|UP|KEEPER)
    default value: None 
o unused_io
    type: enumerated(auto|tie_z)
    default value: None
```

## ioh.set_uns_dpio_pullmode

```
[Syntax]
   ioh.set_uns_dpio_pullmode  <dpio_name> <pull_mode>
[Arguments]
o dpio_name
    type: string
    default value: None 
o pull_mode
    type: enumerated(UP|DOWN|NONE|KEEPER)
    default value: None
```

## isDummyTopmName

(无 help 条目)

## is_demo_dev

(无 help 条目)

## is_hier_kept

(无 help 条目)

## is_hq_gen_nview

(无 help 条目)

## is_proj_open

(无 help 条目)

## is_running_lpp_flow

(无 help 条目)

## is_sk7_slice_trans_flow

(无 help 条目)

## is_valid_num

(无 help 条目)

## iseBitgen

(无 help 条目)

## iter_basic_logic_reduce

(无 help 条目)

## join

(无 help 条目)

## lang.query

```
[Syntax]
   lang.query 
[Arguments]
```

## lang.set

```
[Syntax]
   lang.set  <lang>
[Arguments]
o lang
    type: string
    default value: None
```

## lappend

(无 help 条目)

## lassign

(无 help 条目)

## lb.ins

```
[Syntax]
   lb.ins  [-round <round_value>]
[Arguments]
o round
    type: integer
    default value: 10
```

## ldelete

(无 help 条目)

## le.pack.run

```
[Syntax]
   le.pack.run  <th>
[Arguments]
o th
    type: double
    default value: None
```

## le.pack.stat

```
[Syntax]
   le.pack.stat 
[Arguments]
```

## lglz.check.pio

```
[Syntax]
   lglz.check.pio 
[Arguments]
```

## lglz.pcie

```
[Syntax]
   lglz.pcie  <stage>
[Arguments]
o stage
    type: enumerated(pre|post)
    default value: None
```

## license.query

```
[Syntax]
   license.query 
[Arguments]
```

## lindex

(无 help 条目)

## linsert

(无 help 条目)

## list

(无 help 条目)

## llength

(无 help 条目)

## lmap

(无 help 条目)

## lo.bddnot

```
[Syntax]
   lo.bddnot  [<nview>]
[Arguments]
o nview
    type: object_reference
    default value: None
```

## lo.boolresub

```
[Syntax]
   lo.boolresub  [<nview>] [-algorithm <algorithm_value>] [-object <object_value>]
[Arguments]
o nview
    type: object_reference
    default value: None 
o algorithm
    type: enumerated(ESPRESSO|NOCOMP|SNOCOMP|EXACT|SEPARATE|PHASE)
    default value: NOCOMP 
o object
    type: enumerated(CUBE|LITERAL|SUPPORT)
    default value: LITERAL
```

## lo.cdc_sync_reg.insert

```
[Syntax]
   lo.cdc_sync_reg.insert  [<nview>] [-excfrom <excfrom_value>] [-excto <excto_value>] [-from_clk <from_clk_value>] [-inc_reg <inc_reg_value>] [-regcnt <regcnt_value>] [-to_clk <to_clk_value>]
[Arguments]
o nview
    type: object_reference
    default value: None 
o excfrom
    type: string
    default value: None 
o excto
    type: string
    default value: None 
o from_clk
    type: string
    default value: None 
o inc_reg
    type: string
    default value: None 
o regcnt
    type: integer
    default value: None 
o to_clk
    type: string
    default value: None
```

## lo.clk_conv

```
[Syntax]
   lo.clk_conv  [<nview>]
[Arguments]
o nview
    type: object_reference
    default value: None
```

## lo.clk_div

```
[Syntax]
   lo.clk_div  [<nview>]
[Arguments]
o nview
    type: object_reference
    default value: None
```

## lo.convertsrl16.opt

```
[Syntax]
   lo.convertsrl16.opt  [<nview>]
[Arguments]
o nview
    type: object_reference
    default value: None
```

## lo.extr_ctrl

```
[Syntax]
   lo.extr_ctrl  [<nview>]
[Arguments]
o nview
    type: object_reference
    default value: None
```

## lo.ffDataOpt

```
[Syntax]
   lo.ffDataOpt  [<nview>] [-effort <effort_value>]
[Arguments]
o nview
    type: object_reference
    default value: None 
o effort
    type: enumerated(light|low|std|high|extra|auto)
    default value: auto
```

## lo.ffconvasetclr

```
[Syntax]
   lo.ffconvasetclr  [<nview>] [-effort <effort_value>]
[Arguments]
o nview
    type: object_reference
    default value: None 
o effort
    type: enumerated(low|std|high)
    default value: std
```

## lo.ffctrlset.opt

```
[Syntax]
   lo.ffctrlset.opt  [<nview>]
[Arguments]
o nview
    type: object_reference
    default value: None
```

## lo.ffduplicate

```
[Syntax]
   lo.ffduplicate  [<nview>] [-t <t_value>]
[Arguments]
o nview
    type: object_reference
    default value: None 
o t
    type: integer
    default value: None
```

## lo.ffmerge

```
[Syntax]
   lo.ffmerge  [<nview>]
[Arguments]
o nview
    type: object_reference
    default value: None
```

## lo.ffpinsweep

```
[Syntax]
   lo.ffpinsweep  [<nview>]
[Arguments]
o nview
    type: object_reference
    default value: None
```

## lo.ffsweep

```
[Syntax]
   lo.ffsweep  [<nview>] [-effort <effort_value>]
[Arguments]
o nview
    type: object_reference
    default value: None 
o effort
    type: enumerated(low|std|high)
    default value: std
```

## lo.genffce

```
[Syntax]
   lo.genffce  [<nview>] [-effort <effort_value>]
[Arguments]
o nview
    type: object_reference
    default value: None 
o effort
    type: enumerated(low|std|high)
    default value: std
```

## lo.init_ff

```
[Syntax]
   lo.init_ff  [<nview>]
[Arguments]
o nview
    type: object_reference
    default value: None
```

## lo.retime

```
[Syntax]
   lo.retime  [<nview>]
[Arguments]
o nview
    type: object_reference
    default value: None
```

## lo.set

```
[Syntax]
   lo.set  [-chain_decongest <chain_decongest_value>] [-cut_merge <cut_merge_value>] [-force_wide_group <force_wide_group_value>] [-greedy_wide_group <greedy_wide_group_value>] [-lut_opt <lut_opt_value>] [-reset_all] [-wide_input <wide_input_value>]
[Arguments]
o chain_decongest
    type: enumerated(on|off)
    default value: None 
o cut_merge
    type: enumerated(on|off)
    default value: None 
o force_wide_group
    type: enumerated(on|off)
    default value: None 
o greedy_wide_group
    type: enumerated(on|off)
    default value: None 
o lut_opt
    type: enumerated(on|off)
    default value: None 
o reset_all
    type: switch
    default value: None 
o wide_input
    type: enumerated(on|off)
    default value: None
```

## lo.simplify

```
[Syntax]
   lo.simplify  [<nview>] [-algorithm <algorithm_value>] [-dc <dc_value>] [-object <object_value>]
[Arguments]
o nview
    type: object_reference
    default value: None 
o algorithm
    type: enumerated(ESPRESSO|NOCOMP|SNOCOMP|EXACT|SEPARATE|PHASE)
    default value: NOCOMP 
o dc
    type: enumerated(NODC|DC)
    default value: DC 
o object
    type: enumerated(CUBE|LITERAL|SUPPORT)
    default value: LITERAL
```

## lo.slo.set

```
[Syntax]
   lo.slo.set  [-clk_conv <clk_conv_value>] [-convert_srl16 <convert_srl16_value>] [-ctrlset_opt <ctrlset_opt_value>] [-data_opt <data_opt_value>] [-data_opt_effort <data_opt_effort_value>] [-dopt_multi_run <dopt_multi_run_value>] [-extr_ce <extr_ce_value>] [-extr_ctrl <extr_ctrl_value>] [-extr_srs <extr_srs_value>] [-ff_init <ff_init_value>] [-lec_fmerge <lec_fmerge_value>] [-lec_sr_merge <lec_sr_merge_value>] [-lec_static_srl_opt <lec_static_srl_opt_value>] [-merge <merge_value>] [-pinsweep <pinsweep_value>] [-reset_all] [-retime <retime_value>] [-sr_merge <sr_merge_value>] [-srl_dff_first <srl_dff_first_value>] [-srlsweep <srlsweep_value>] [-static_srl_opt <static_srl_opt_value>] [-sweep <sweep_value>]
[Arguments]
o clk_conv
    type: enumerated(on|off)
    default value: None 
o convert_srl16
    type: enumerated(on|off)
    default value: None 
o ctrlset_opt
    type: enumerated(on|off)
    default value: None 
o data_opt
    type: enumerated(on|off)
    default value: None 
o data_opt_effort
    type: enumerated(light|low|std|high|extra|auto)
    default value: None 
o dopt_multi_run
    type: enumerated(on|off|auto)
    default value: None 
o extr_ce
    type: enumerated(on|off)
    default value: None 
o extr_ctrl
    type: enumerated(on|off)
    default value: None 
o extr_srs
    type: enumerated(on|off)
    default value: None 
o ff_init
    type: enumerated(0|1|force0|force1)
    default value: None 
o lec_fmerge
    type: enumerated(on|off)
    default value: None 
o lec_sr_merge
    type: enumerated(on|off)
    default value: None 
o lec_static_srl_opt
    type: enumerated(on|off)
    default value: None 
o merge
    type: enumerated(on|off)
    default value: None 
o pinsweep
    type: enumerated(on|off)
    default value: None 
o reset_all
    type: switch
    default value: None 
o retime
    type: enumerated(on|off)
    default value: None 
o sr_merge
    type: enumerated(on|off)
    default value: None 
o srl_dff_first
    type: enumerated(on|off)
    default value: None 
o srlsweep
    type: enumerated(on|off)
    default value: None 
o static_srl_opt
    type: enumerated(on|off)
    default value: None 
o sweep
    type: enumerated(on|off)
    default value: None
```

## lo.sloset.query

```
[Syntax]
   lo.sloset.query  [-all] [-clk_conv] [-convert_srl16] [-ctrlset_opt] [-data_opt] [-data_opt_effort] [-dopt_multi_run] [-extr_ce] [-extr_ctrl] [-extr_srs] [-lec_fmerge] [-lec_sr_merge] [-lec_static_srl_opt] [-merge] [-pinsweep] [-retime] [-sr_merge] [-srl_dff_first] [-srlsweep] [-static_srl_opt] [-sweep]
[Arguments]
o all
    type: switch
    default value: None 
o clk_conv
    type: switch
    default value: None 
o convert_srl16
    type: switch
    default value: None 
o ctrlset_opt
    type: switch
    default value: None 
o data_opt
    type: switch
    default value: None 
o data_opt_effort
    type: switch
    default value: None 
o dopt_multi_run
    type: switch
    default value: None 
o extr_ce
    type: switch
    default value: None 
o extr_ctrl
    type: switch
    default value: None 
o extr_srs
    type: switch
    default value: None 
o lec_fmerge
    type: switch
    default value: None 
o lec_sr_merge
    type: switch
    default value: None 
o lec_static_srl_opt
    type: switch
    default value: None 
o merge
    type: switch
    default value: None 
o pinsweep
    type: switch
    default value: None 
o retime
    type: switch
    default value: None 
o sr_merge
    type: switch
    default value: None 
o srl_dff_first
    type: switch
    default value: None 
o srlsweep
    type: switch
    default value: None 
o static_srl_opt
    type: switch
    default value: None 
o sweep
    type: switch
    default value: None
```

## lo.srlsweep

```
[Syntax]
   lo.srlsweep  [<nview>]
[Arguments]
o nview
    type: object_reference
    default value: None
```

## lo.srs_opt

```
[Syntax]
   lo.srs_opt  [<nview>]
[Arguments]
o nview
    type: object_reference
    default value: None
```

## lo.staticsrl.opt

```
[Syntax]
   lo.staticsrl.opt  [<nview>]
[Arguments]
o nview
    type: object_reference
    default value: None
```

## lo.synprim.opt

```
[Syntax]
   lo.synprim.opt  [<nview>]
[Arguments]
o nview
    type: object_reference
    default value: None
```

## lo.synprim.query

```
[Syntax]
   lo.synprim.query  [-all] [-all_muxf] [-carry4] [-chain] [-local_dual] [-lut] [-macro] [-muxf] [-pass_net] [-s_di_same] [-same_s]
[Arguments]
o all
    type: switch
    default value: None 
o all_muxf
    type: switch
    default value: None 
o carry4
    type: switch
    default value: None 
o chain
    type: switch
    default value: None 
o local_dual
    type: switch
    default value: None 
o lut
    type: switch
    default value: None 
o macro
    type: switch
    default value: None 
o muxf
    type: switch
    default value: None 
o pass_net
    type: switch
    default value: None 
o s_di_same
    type: switch
    default value: None 
o same_s
    type: switch
    default value: None
```

## lo.synprim.set

```
[Syntax]
   lo.synprim.set  [-all_muxf <all_muxf_value>] [-carry4 <carry4_value>] [-chain <chain_value>] [-local_dual <local_dual_value>] [-lut <lut_value>] [-macro <macro_value>] [-muxf <muxf_value>] [-pass_net <pass_net_value>] [-reset_all] [-s_di_same <s_di_same_value>] [-same_s <same_s_value>]
[Arguments]
o all_muxf
    type: enumerated(on|off)
    default value: None 
o carry4
    type: enumerated(on|off)
    default value: None 
o chain
    type: enumerated(on|off)
    default value: None 
o local_dual
    type: enumerated(on|off)
    default value: None 
o lut
    type: enumerated(on|off)
    default value: None 
o macro
    type: enumerated(on|off)
    default value: None 
o muxf
    type: enumerated(on|off)
    default value: None 
o pass_net
    type: enumerated(on|off)
    default value: None 
o reset_all
    type: switch
    default value: None 
o s_di_same
    type: enumerated(on|off)
    default value: None 
o same_s
    type: enumerated(on|off)
    default value: None
```

## lo.widelogic.opt

```
[Syntax]
   lo.widelogic.opt  [<nview>] [-action <action_value>] [-chain_len <chain_len_value>] [-force] [-lut_bound <lut_bound_value>] [-wide_bound <wide_bound_value>]
[Arguments]
o nview
    type: object_reference
    default value: None 
o action
    type: enumerated(GROUP|DECOMP|UNKEEP)
    default value: GROUP 
o chain_len
    type: integer
    default value: None 
o force
    type: switch
    default value: None 
o lut_bound
    type: integer
    default value: None 
o wide_bound
    type: integer
    default value: None
```

## lo.xeliminate

```
[Syntax]
   lo.xeliminate  [<nview>] [-advanced] [-method <method_value>]
[Arguments]
o nview
    type: object_reference
    default value: None 
o advanced
    type: switch
    default value: None 
o method
    type: enumerated(FORCE0|FORCE1|FORCEDASH|AUTO|DCGEN)
    default value: DCGEN
```

## lo.xor.opt

```
[Syntax]
   lo.xor.opt  [<nview>] [-action <action_value>] [-bound <bound_value>]
[Arguments]
o nview
    type: object_reference
    default value: None 
o action
    type: enumerated(GROUP|DECOMP)
    default value: DECOMP 
o bound
    type: integer
    default value: None
```

## load

(无 help 条目)

## loadConstraint

(无 help 条目)

## loadPhysicalConstraint

(无 help 条目)

## loadTimingConstraint

(无 help 条目)

## loadUdm

(无 help 条目)

## logfile.append

```
[Syntax]
   logfile.append  <file>
[Arguments]
o file
    type: string
    default value: None
```

## logfile.flush

```
[Syntax]
   logfile.flush 
[Arguments]
```

## logfile.puts

```
[Syntax]
   logfile.puts  <msg>
[Arguments]
o msg
    type: string
    default value: None
```

## loset.query

```
[Syntax]
   loset.query  [-all] [-chain_decongest] [-cut_merge] [-force_wide_group] [-greedy_wide_group] [-lut_opt] [-wide_input]
[Arguments]
o all
    type: switch
    default value: None 
o chain_decongest
    type: switch
    default value: None 
o cut_merge
    type: switch
    default value: None 
o force_wide_group
    type: switch
    default value: None 
o greedy_wide_group
    type: switch
    default value: None 
o lut_opt
    type: switch
    default value: None 
o wide_input
    type: switch
    default value: None
```

## lpp.ap

```
[Syntax]
   lpp.ap 
[Arguments]
```

## lpp.bpl

```
[Syntax]
   lpp.bpl 
[Arguments]
```

## lpp.bpl.genupc

```
[Syntax]
   lpp.bpl.genupc  <filename>
[Arguments]
o filename
    type: string
    default value: None
```

## lpp.ca

```
[Syntax]
   lpp.ca  [-th_dsts_expand <th_dsts_expand_value>]
[Arguments]
o th_dsts_expand
    type: integer
    default value: None
```

## lpp.ca.insert_clk_elem

```
[Syntax]
   lpp.ca.insert_clk_elem 
[Arguments]
```

## lpp.clearpos

```
[Syntax]
   lpp.clearpos 
[Arguments]
```

## lpp.clk.region.flow

```
[Syntax]
   lpp.clk.region.flow 
[Arguments]
```

## lpp.export_conn

```
[Syntax]
   lpp.export_conn 
[Arguments]
```

## lpp.export_pin_delay

```
[Syntax]
   lpp.export_pin_delay  <file>
[Arguments]
o file
    type: string
    default value: None
```

## lpp.export_udev

```
[Syntax]
   lpp.export_udev  [-pkgonly]
[Arguments]
o pkgonly
    type: switch
    default value: None
```

## lpp.flushdelay

```
[Syntax]
   lpp.flushdelay 
[Arguments]
```

## lpp.fpl

```
[Syntax]
   lpp.fpl  [-clkonly] [-max_epoch <max_epoch_value>] [-use_last] [-wl]
[Arguments]
o clkonly
    type: switch
    default value: None 
o max_epoch
    type: integer
    default value: None 
o use_last
    type: switch
    default value: None 
o wl
    type: switch
    default value: None
```

## lpp.grid_report

```
[Syntax]
   lpp.grid_report 
[Arguments]
```

## lpp.lglz_dsp

```
[Syntax]
   lpp.lglz_dsp 
[Arguments]
```

## lpp.lglz_dsp_slice_ctrl

```
[Syntax]
   lpp.lglz_dsp_slice_ctrl 
[Arguments]
```

## lpp.lglz_ebr

```
[Syntax]
   lpp.lglz_ebr 
[Arguments]
```

## lpp.lglz_plb

```
[Syntax]
   lpp.lglz_plb 
[Arguments]
```

## lpp.lglz_plb.site

```
[Syntax]
   lpp.lglz_plb.site 
[Arguments]
```

## lpp.lglz_plb.site2xyz

```
[Syntax]
   lpp.lglz_plb.site2xyz 
[Arguments]
```

## lpp.lglz_plb.xyz

```
[Syntax]
   lpp.lglz_plb.xyz 
[Arguments]
```

## lpp.lglz_saiol_22k

```
[Syntax]
   lpp.lglz_saiol_22k 
[Arguments]
```

## lpp.loadrc

```
[Syntax]
   lpp.loadrc  <pos>
[Arguments]
o pos
    type: string
    default value: None
```

## lpp.neg_slack_pins

```
[Syntax]
   lpp.neg_slack_pins  <file>
[Arguments]
o file
    type: string
    default value: None
```

## lpp.report

```
[Syntax]
   lpp.report 
[Arguments]
```

## lpp.saverc

```
[Syntax]
   lpp.saverc  <pos>
[Arguments]
o pos
    type: string
    default value: None
```

## lpp.stat

```
[Syntax]
   lpp.stat 
[Arguments]
```

## lpp.timing_available

```
[Syntax]
   lpp.timing_available 
[Arguments]
```

## lpp.version

```
[Syntax]
   lpp.version 
[Arguments]
```

## lrange

(无 help 条目)

## lrepeat

(无 help 条目)

## lreplace

(无 help 条目)

## lreverse

(无 help 条目)

## ls

(无 help 条目)

## lsearch

(无 help 条目)

## lset

(无 help 条目)

## lsort

(无 help 条目)

## macro.build

```
[Syntax]
   macro.build  [<udmObj>]
[Arguments]
o udmObj
    type: object_reference
    default value: None
```

## macro.flatten

```
[Syntax]
   macro.flatten  [<nview>]
[Arguments]
o nview
    type: object_reference
    default value: None
```

## macro.map

```
[Syntax]
   macro.map 
[Arguments]
```

## macro.pack

```
[Syntax]
   macro.pack  [<nview>]
[Arguments]
o nview
    type: object_reference
    default value: None
```

## macro.rebuild

```
[Syntax]
   macro.rebuild  [<nview>] [-merge_only]
[Arguments]
o nview
    type: object_reference
    default value: None 
o merge_only
    type: switch
    default value: None
```

## macro.remap

```
[Syntax]
   macro.remap  [-src_family <src_family_value>]
[Arguments]
o src_family
    type: string
    default value: None
```

## macro.unmap

```
[Syntax]
   macro.unmap  [-src_family <src_family_value>]
[Arguments]
o src_family
    type: string
    default value: None
```

## mpi_route

(无 help 条目)

## mpimem

(无 help 条目)

## msg

```
[Syntax]
   msg  <switch>
[Arguments]
o switch
    type: enumerated(on|off|stat)
    default value: None
```

## msg.plimit.reset

```
[Syntax]
   msg.plimit.reset  [-all] [-msg <msg_value>]
[Arguments]
o all
    type: switch
    default value: None 
o msg
    type: string
    default value: None
```

## msg.plimit.set

```
[Syntax]
   msg.plimit.set  <msg_id> [<limit>]
[Arguments]
o msg_id
    type: string
    default value: None 
o limit
    type: integer
    default value: None
```

## msg.print

```
[Syntax]
   msg.print  <msg_id> <msg_content> [-tochannel <tochannel_value>]
[Arguments]
o msg_id
    type: string
    default value: None 
o msg_content
    type: string
    default value:  
o tochannel
    type: string
    default value: None
```

## msg.type.set

```
[Syntax]
   msg.type.set  <msg_id> <type>
[Arguments]
o msg_id
    type: string
    default value: None 
o type
    type: enumerated(p|e|w|f|n|h|i)
    default value: None
```

## namespace

(无 help 条目)

## netlist.setup

```
[Syntax]
   netlist.setup 
[Arguments]
```

## nl.blackbox.check

```
[Syntax]
   nl.blackbox.check 
[Arguments]
```

## nl.chain.decongest

```
[Syntax]
   nl.chain.decongest  [<nview>] [-gap <gap_value>] [-max_cnt <max_cnt_value>] [-min_len <min_len_value>]
[Arguments]
o nview
    type: object_reference
    default value: None 
o gap
    type: integer
    default value: None 
o max_cnt
    type: integer
    default value: None 
o min_len
    type: integer
    default value: None
```

## nl.chkfix

```
[Syntax]
   nl.chkfix  <nview> [-chkonly] [-nohier] [-nomsg] [-rpt2file <rpt2file_value>]
[Arguments]
o nview
    type: object_reference
    default value: ~ 
o chkonly
    type: switch
    default value: None 
o nohier
    type: switch
    default value: None 
o nomsg
    type: switch
    default value: None 
o rpt2file
    type: string
    default value: None
```

## nl.clean

```
[Syntax]
   nl.clean  [<nview>] [-hier]
[Arguments]
o nview
    type: object_reference
    default value: None 
o hier
    type: switch
    default value: None
```

## nl.clkdom.report

```
[Syntax]
   nl.clkdom.report  [-comb_logic_ckdom <comb_logic_ckdom_value>] [-detail] [-inner_name]
[Arguments]
o comb_logic_ckdom
    type: enumerated(fastest|all)
    default value: fastest 
o detail
    type: switch
    default value: None 
o inner_name
    type: switch
    default value: None
```

## nl.clock.detect

```
[Syntax]
   nl.clock.detect  [-net] [-obj] [-type]
[Arguments]
o net
    type: switch
    default value: None 
o obj
    type: switch
    default value: None 
o type
    type: switch
    default value: None
```

## nl.clroute.chk

```
[Syntax]
   nl.clroute.chk 
[Arguments]
```

## nl.cnvtmocombs

```
[Syntax]
   nl.cnvtmocombs 
[Arguments]
```

## nl.ctrlset.report

```
[Syntax]
   nl.ctrlset.report 
[Arguments]
```

## nl.dataskew.chk

```
[Syntax]
   nl.dataskew.chk 
[Arguments]
```

## nl.fanout_opt

```
[Syntax]
   nl.fanout_opt 
[Arguments]
```

## nl.fix_comb_async_ctrl

```
[Syntax]
   nl.fix_comb_async_ctrl  <nview>
[Arguments]
o nview
    type: object_reference
    default value: ~
```

## nl.flatten

```
[Syntax]
   nl.flatten  [<nview>] [<nmnc>]
[Arguments]
o nview
    type: object_reference
    default value: None 
o nmnc
    type: switch
    default value: None
```

## nl.hier.report

```
[Syntax]
   nl.hier.report  [-inc_devcnt] [-inc_header] [-inc_level] [-inc_self] [-inc_unused]
[Arguments]
o inc_devcnt
    type: switch
    default value: None 
o inc_header
    type: switch
    default value: None 
o inc_level
    type: switch
    default value: None 
o inc_self
    type: switch
    default value: None 
o inc_unused
    type: switch
    default value: None
```

## nl.hierinfo.build

```
[Syntax]
   nl.hierinfo.build  <obj>
[Arguments]
o obj
    type: object_reference
    default value: ~
```

## nl.inst.exist

```
[Syntax]
   nl.inst.exist  <type>
[Arguments]
o type
    type: enumerated(zero|one|dff|tff|jkff|latch|tribuf|buf|inv|mux2|comblogic|lut|block|io|bram|dram|dsp|cmu|ext|vendor)
    default value: None
```

## nl.ioinsertion

```
[Syntax]
   nl.ioinsertion  [-tribuf2logic]
[Arguments]
o tribuf2logic
    type: switch
    default value: None
```

## nl.loop.break

```
[Syntax]
   nl.loop.break  [<nview>] [-loop_report]
[Arguments]
o nview
    type: object_reference
    default value: None 
o loop_report
    type: switch
    default value: None
```

## nl.loop.brkpnt.set

```
[Syntax]
   nl.loop.brkpnt.set  <objname> [-type <type_value>]
[Arguments]
o objname
    type: string
    default value: None 
o type
    type: enumerated(PIN|NET)
    default value: PIN
```

## nl.loop.recover

```
[Syntax]
   nl.loop.recover  [<nview>]
[Arguments]
o nview
    type: object_reference
    default value: None
```

## nl.loop.report

```
[Syntax]
   nl.loop.report  [-breaker]
[Arguments]
o breaker
    type: switch
    default value: None
```

## nl.lut_opt

```
[Syntax]
   nl.lut_opt  [<nview>]
[Arguments]
o nview
    type: object_reference
    default value: None
```

## nl.merge_cut

```
[Syntax]
   nl.merge_cut 
[Arguments]
```

## nl.namestyle.query

```
[Syntax]
   nl.namestyle.query  [-all] [-bus] [-hier_seperator] [-pin_mark]
[Arguments]
o all
    type: switch
    default value: None 
o bus
    type: switch
    default value: None 
o hier_seperator
    type: switch
    default value: None 
o pin_mark
    type: switch
    default value: None
```

## nl.namestyle.set

```
[Syntax]
   nl.namestyle.set  [-bus <bus_value>] [-hier_seperator <hier_seperator_value>] [-pin_mark <pin_mark_value>] [-reset_all]
[Arguments]
o bus
    type: enumerated(%s[%d]|%s(%d)|%s<%d>)
    default value: None 
o hier_seperator
    type: enumerated(/|.|:|$|%)
    default value: None 
o pin_mark
    type: enumerated(.|/|@|:)
    default value: None 
o reset_all
    type: switch
    default value: None
```

## nl.power.params.report

```
[Syntax]
   nl.power.params.report  [-file <file_value>]
[Arguments]
o file
    type: string
    default value: None
```

## nl.power.report

```
[Syntax]
   nl.power.report  [-toggle_rate <toggle_rate_value>]
[Arguments]
o toggle_rate
    type: double
    default value: None
```

## nl.prep.pack

```
[Syntax]
   nl.prep.pack 
[Arguments]
```

## nl.prep.pack.xist.seal

```
[Syntax]
   nl.prep.pack.xist.seal 
[Arguments]
```

## nl.prep.pack.xist.sealion

```
[Syntax]
   nl.prep.pack.xist.sealion 
[Arguments]
```

## nl.prep.pack.xist.shark

```
[Syntax]
   nl.prep.pack.xist.shark  [-absorb_ble_inv] [-norm_ble]
[Arguments]
o absorb_ble_inv
    type: switch
    default value: None 
o norm_ble
    type: switch
    default value: None
```

## nl.prep.place

```
[Syntax]
   nl.prep.place 
[Arguments]
```

## nl.prep4fmv

(无 help 条目)

## nl.primbind

```
[Syntax]
   nl.primbind  [<comb>] [<seq>] [<io>] [<recursive>] [<no_absorb_seq_inv>]
[Arguments]
o comb
    type: switch
    default value: None 
o seq
    type: switch
    default value: None 
o io
    type: switch
    default value: None 
o recursive
    type: switch
    default value: None 
o no_absorb_seq_inv
    type: switch
    default value: None
```

## nl.pstru.build

```
[Syntax]
   nl.pstru.build  <nview>
[Arguments]
o nview
    type: object_reference
    default value: ~
```

## nl.report

```
[Syntax]
   nl.report  [-check] [-file <file_value>] [-location] [-of <of_value>] [-ratio] [-region] [-rtinfo]
[Arguments]
o check
    type: switch
    default value: None 
o file
    type: string
    default value: None 
o location
    type: switch
    default value: None 
o of
    type: string
    default value: None 
o ratio
    type: switch
    default value: None 
o region
    type: switch
    default value: None 
o rtinfo
    type: switch
    default value: None
```

## nl.revext

```
[Syntax]
   nl.revext  <nview> [-fmv]
[Arguments]
o nview
    type: object_reference
    default value: ~ 
o fmv
    type: switch
    default value: None
```

## nl.shark_slice_build_cst

```
[Syntax]
   nl.shark_slice_build_cst 
[Arguments]
```

## nl.sort

```
[Syntax]
   nl.sort  [<nview>]
[Arguments]
o nview
    type: object_reference
    default value: None
```

## nl.stat.check

```
[Syntax]
   nl.stat.check  <stat> [-ignore_const] [-partial]
[Arguments]
o stat
    type: enumerated(is_mapped|is_packed|is_placed|is_routed)
    default value: None 
o ignore_const
    type: switch
    default value: None 
o partial
    type: switch
    default value: None
```

## nl.stat.fanout

```
[Syntax]
   nl.stat.fanout  <type> [-detail] [-n <n_value>] [-p <p_value>]
[Arguments]
o type
    type: enumerated(all|clk|data|ctrl|mixed|const)
    default value: all 
o detail
    type: switch
    default value: None 
o n
    type: integer
    default value: None 
o p
    type: integer
    default value: None
```

## nl.sweep

```
[Syntax]
   nl.sweep  [<obj>]
[Arguments]
o obj
    type: object_reference
    default value: None
```

## nl.synlib.param.check

```
[Syntax]
   nl.synlib.param.check 
[Arguments]
```

## nl.unflatten

```
[Syntax]
   nl.unflatten  [<nview>]
[Arguments]
o nview
    type: object_reference
    default value: None
```

## nl.uniquify

```
[Syntax]
   nl.uniquify  [<nview>]
[Arguments]
o nview
    type: object_reference
    default value: None
```

## nl.unmap

```
[Syntax]
   nl.unmap  [<nview>] [<keep_cell>]
[Arguments]
o nview
    type: object_reference
    default value: None 
o keep_cell
    type: string
    default value: None
```

## nl.write

```
[Syntax]
   nl.write  <filename> [-eqn] [-fmv] [-lib <lib_value>] [-loc] [-no_defparam] [-phy] [-sdf] [-sort <sort_value>]
[Arguments]
o filename
    type: string
    default value: None 
o eqn
    type: switch
    default value: None 
o fmv
    type: switch
    default value: None 
o lib
    type: object_reference
    default value: None 
o loc
    type: switch
    default value: None 
o no_defparam
    type: switch
    default value: None 
o phy
    type: switch
    default value: None 
o sdf
    type: switch
    default value: None 
o sort
    type: enumerated(net|inst|port|net_inst|all)
    default value: None
```

## nl.xparam.fix

```
[Syntax]
   nl.xparam.fix 
[Arguments]
```

## norm_xdata.info

```
[Syntax]
   norm_xdata.info  <obj> <xdname>
[Arguments]
o obj
    type: object_reference
    default value: None 
o xdname
    type: string
    default value: None
```

## normxdata.list

```
[Syntax]
   normxdata.list  <obj> [-order <order_value>]
[Arguments]
o obj
    type: object_reference
    default value: None 
o order
    type: enumerated(top_down|bottom_up)
    default value: bottom_up
```

## npl.sa

```
[Syntax]
   npl.sa  [-effort <effort_value>] [-np] [-seed <seed_value>]
[Arguments]
o effort
    type: enumerated(low|std|high)
    default value: std 
o np
    type: switch
    default value: None 
o seed
    type: integer
    default value: None
```

## npl.session

```
[Syntax]
   npl.session  [-ap] [-ap_kw2] [-ap_npl] [-eco] [-effort <effort_value>] [-np] [-seed <seed_value>]
[Arguments]
o ap
    type: switch
    default value: None 
o ap_kw2
    type: switch
    default value: None 
o ap_npl
    type: switch
    default value: None 
o eco
    type: switch
    default value: None 
o effort
    type: enumerated(low|std|high)
    default value: std 
o np
    type: switch
    default value: None 
o seed
    type: integer
    default value: None
```

## npl.session.body

(无 help 条目)

## nview.lo.literal

(无 help 条目)

## nvlg.read

```
[Syntax]
   nvlg.read  <filename> [-family <family_value>] [-tolib <tolib_value>] [-top <top_value>]
[Arguments]
o filename
    type: string
    default value: None 
o family
    type: string
    default value: None 
o tolib
    type: object_reference
    default value: None 
o top
    type: string
    default value: None
```

## obj.cell.info

```
[Syntax]
   obj.cell.info  <obj> <info>
[Arguments]
o obj
    type: object_reference
    default value: None 
o info
    type: enumerated(type|portcnt|viewcnt|all)
    default value: all
```

## obj.cell.set

```
[Syntax]
   obj.cell.set  <obj> <type>
[Arguments]
o obj
    type: object_reference
    default value: None 
o type
    type: enumerated(zero|one|dff|tff|jkff|latch|tribuf|buf|inv|mux2|comblogic|lut|block|io|bram|dram|dsp|cmu|ext|vendor)
    default value: None
```

## obj.flag.list

```
[Syntax]
   obj.flag.list  <obj>
[Arguments]
o obj
    type: object_reference
    default value: None
```

## obj.foreach

```
[Syntax]
   obj.foreach  <obj_type> <iter_var> <owner> <script>
[Arguments]
o obj_type
    type: enumerated(lib|cell|view|inst|nview_inst|net|pin|port)
    default value: None 
o iter_var
    type: string
    default value: None 
o owner
    type: object_reference
    default value: None 
o script
    type: string
    default value: None
```

## obj.get

```
[Syntax]
   obj.get  <hier_name> [<msg_var>]
[Arguments]
o hier_name
    type: string
    default value: None 
o msg_var
    type: string
    default value: None
```

## obj.index.start

```
[Syntax]
   obj.index.start 
[Arguments]
```

## obj.index.stop

```
[Syntax]
   obj.index.stop 
[Arguments]
```

## obj.info

```
[Syntax]
   obj.info  <obj> <type>
[Arguments]
o obj
    type: object_reference
    default value: None 
o type
    type: enumerated(all|name|hiername|type|owner)
    default value: all
```

## obj.inst.info

```
[Syntax]
   obj.inst.info  <obj> <info>
[Arguments]
o obj
    type: object_reference
    default value: None 
o info
    type: enumerated(type|pincnt|incnt|outcnt|inoutcnt|view|all)
    default value: all
```

## obj.inst.op

```
[Syntax]
   obj.inst.op  <op> <inst> [<view>] [<nview>]
[Arguments]
o op
    type: enumerated(create|delete)
    default value: None 
o inst
    type: string
    default value: None 
o view
    type: object_reference
    default value: None 
o nview
    type: object_reference
    default value: None
```

## obj.lib.create

```
[Syntax]
   obj.lib.create  <name>
[Arguments]
o name
    type: string
    default value: None
```

## obj.lib.info

```
[Syntax]
   obj.lib.info  <obj> <info>
[Arguments]
o obj
    type: object_reference
    default value: None 
o info
    type: enumerated(type|cellcnt|all)
    default value: all
```

## obj.lview.info

```
[Syntax]
   obj.lview.info  <lview> <info>
[Arguments]
o lview
    type: object_reference
    default value: None 
o info
    type: enumerated(type|cover)
    default value: None
```

## obj.lview.set

```
[Syntax]
   obj.lview.set  <view> <type> [-cover <cover_value>]
[Arguments]
o view
    type: object_reference
    default value: None 
o type
    type: enumerated(one|zero|buf|inv|and|or|nand|nor|xor|xnor|mux2|complex)
    default value: complex 
o cover
    type: string
    default value: None
```

## obj.net.info

```
[Syntax]
   obj.net.info  <obj> <info>
[Arguments]
o obj
    type: object_reference
    default value: None 
o info
    type: enumerated(pincnt|drivercnt|sinkcnt|driver|all|phynet)
    default value: all
```

## obj.net.op

```
[Syntax]
   obj.net.op  <op> <net> [<context_obj>] [-vec <vec_value>]
[Arguments]
o op
    type: enumerated(create|delete|connect|disconnect|merge)
    default value: None 
o net
    type: string
    default value: None 
o context_obj
    type: object_reference
    default value: None 
o vec
    type: string
    default value: None
```

## obj.nview.info

```
[Syntax]
   obj.nview.info  <obj> <info>
[Arguments]
o obj
    type: object_reference
    default value: None 
o info
    type: enumerated(instcnt|netcnt|psview|all)
    default value: all
```

## obj.pin.get

```
[Syntax]
   obj.pin.get  <owner> <index> [-direction <direction_value>]
[Arguments]
o owner
    type: object_reference
    default value: None 
o index
    type: integer
    default value: None 
o direction
    type: enumerated(in|out|inout|all)
    default value: all
```

## obj.pin.info

```
[Syntax]
   obj.pin.info  <obj> <info>
[Arguments]
o obj
    type: object_reference
    default value: None 
o info
    type: enumerated(net|port|direction|type|vec|bubbled|delay|all)
    default value: all
```

## obj.port.create

```
[Syntax]
   obj.port.create  <obj> <name> <direction>
[Arguments]
o obj
    type: object_reference
    default value: None 
o name
    type: string
    default value: None 
o direction
    type: enumerated(in|out|inout)
    default value: None
```

## obj.port.info

```
[Syntax]
   obj.port.info  <obj> <info>
[Arguments]
o obj
    type: object_reference
    default value: None 
o info
    type: enumerated(direction|type|vec|bubbled|all)
    default value: all
```

## obj.port.set

```
[Syntax]
   obj.port.set  <obj> <type> [-bubbled]
[Arguments]
o obj
    type: object_reference
    default value: None 
o type
    type: enumerated(data|pad|clk|ce|oe|cin|cout|casin|casout|aset|aclr|sset|sclr|aload|sload|actrl|sctrl|we|re|qout|if|then|else)
    default value: None 
o bubbled
    type: switch
    default value: None
```

## obj.probe

```
[Syntax]
   obj.probe  <obj> <what> [-idx2nm]
[Arguments]
o obj
    type: object_reference
    default value: None 
o what
    type: enumerated(l1|l2|c1|c2|fidx|flist|all)
    default value: all 
o idx2nm
    type: switch
    default value: None
```

## obj.psview.info

```
[Syntax]
   obj.psview.info  <obj> <info>
[Arguments]
o obj
    type: object_reference
    default value: None 
o info
    type: enumerated(nview|cfgstr|all)
    default value: all
```

## obj.sys.get

```
[Syntax]
   obj.sys.get  <sysobj>
[Arguments]
o sysobj
    type: enumerated(design|topview|worklib|primlib|archlib|synlib|org_archlib|org_synlib)
    default value: None
```

## obj.view.info

```
[Syntax]
   obj.view.info  <obj> <info>
[Arguments]
o obj
    type: object_reference
    default value: None 
o info
    type: enumerated(type|hasinst|instcnt|unique_inst|all)
    default value: all
```

## obj.xdata.delete

```
[Syntax]
   obj.xdata.delete  <obj> <xdata_name>
[Arguments]
o obj
    type: object_reference
    default value: None 
o xdata_name
    type: string
    default value: None
```

## obj.xdata.info

```
[Syntax]
   obj.xdata.info  <obj> <xdata_name> <info>
[Arguments]
o obj
    type: object_reference
    default value: None 
o xdata_name
    type: string
    default value: None 
o info
    type: enumerated(value|type|all)
    default value: all
```

## obj.xdata.list

```
[Syntax]
   obj.xdata.list  <obj>
[Arguments]
o obj
    type: object_reference
    default value: None
```

## obj.xdata.set

```
[Syntax]
   obj.xdata.set  <obj> <xdata_name> <xdata_value> <xdata_type>
[Arguments]
o obj
    type: object_reference
    default value: None 
o xdata_name
    type: string
    default value: None 
o xdata_value
    type: string
    default value: None 
o xdata_type
    type: enumerated(string|short|int|long|ull|float|double)
    default value: string
```

## opcond.clear

```
[Syntax]
   opcond.clear 
[Arguments]
```

## opcond.define

```
[Syntax]
   opcond.define  <name> [-p <p_value>] [-t <t_value>] [-v <v_value>]
[Arguments]
o name
    type: string
    default value: None 
o p
    type: string
    default value: None 
o t
    type: string
    default value: None 
o v
    type: string
    default value: None
```

## opcond.query

```
[Syntax]
   opcond.query  <opt> [<name>]
[Arguments]
o opt
    type: enumerated(best|worst|names|detail)
    default value: None 
o name
    type: string
    default value: None
```

## opcond.set

```
[Syntax]
   opcond.set  [<cond>] [-best <best_value>] [-worst <worst_value>]
[Arguments]
o cond
    type: string
    default value: None 
o best
    type: string
    default value: None 
o worst
    type: string
    default value: None
```

## open

(无 help 条目)

## outdir.set

```
[Syntax]
   outdir.set  [<dir>] [-append_log]
[Arguments]
o dir
    type: string
    default value: None 
o append_log
    type: switch
    default value: None
```

## outputFirstStageRptsCpFromV3

(无 help 条目)

## outputSecondStageRptsCpFromV3

(无 help 条目)

## output_hq_setting

(无 help 条目)

## package

(无 help 条目)

## phycst.blockage.set

```
[Syntax]
   phycst.blockage.set  <site>
[Arguments]
o site
    type: string
    default value: None
```

## phycst.clear

```
[Syntax]
   phycst.clear 
[Arguments]
```

## phycst.clkroute.set

```
[Syntax]
   phycst.clkroute.set  <nets> <type> [-maxdelay <maxdelay_value>]
[Arguments]
o nets
    type: string
    default value: None 
o type
    type: enumerated(direct|general)
    default value: None 
o maxdelay
    type: double
    default value: None
```

## phycst.ddr

```
[Syntax]
   phycst.ddr  <val> [-external] [-internal] [-ratio <ratio_value>] [-seperated] [-vref]
[Arguments]
o val
    type: enumerated(on|off)
    default value: None 
o external
    type: switch
    default value: None 
o internal
    type: switch
    default value: None 
o ratio
    type: enumerated(I45|I50|I55)
    default value: None 
o seperated
    type: switch
    default value: None 
o vref
    type: switch
    default value: None
```

## phycst.devdelay.adjust

```
[Syntax]
   phycst.devdelay.adjust  <ll> <tr> [-add <add_value>] [-factor <factor_value>]
[Arguments]
o ll
    type: string
    default value: None 
o tr
    type: string
    default value: None 
o add
    type: double
    default value: None 
o factor
    type: double
    default value: None
```

## phycst.devdelay.clear

```
[Syntax]
   phycst.devdelay.clear 
[Arguments]
```

## phycst.end

```
[Syntax]
   phycst.end 
[Arguments]
```

## phycst.exclusive.set

```
[Syntax]
   phycst.exclusive.set  <inst_list> <group_name>
[Arguments]
o inst_list
    type: string
    default value: None 
o group_name
    type: string
    default value: None
```

## phycst.extvref.set

```
[Syntax]
   phycst.extvref.set  <loc> <vccio> [-bank <bank_value>]
[Arguments]
o loc
    type: string
    default value: None 
o vccio
    type: enumerated(0.9|0.9V|1.2|1.2V|1.35|1.35V|1.5|1.5V|1.8|1.8V|2.5|2.5V|3.3|3.3V|5.0|5.0V)
    default value: None 
o bank
    type: string
    default value: None
```

## phycst.loc.check

```
[Syntax]
   phycst.loc.check  <loc>
[Arguments]
o loc
    type: string
    default value: None
```

## phycst.loc.set

```
[Syntax]
   phycst.loc.set  <inst> <loc> [-soft]
[Arguments]
o inst
    type: string
    default value: None 
o loc
    type: string
    default value: None 
o soft
    type: switch
    default value: None
```

## phycst.net.set

```
[Syntax]
   phycst.net.set  <nets> <type> [-disable] [-index <index_value>] [-loc <loc_value>] [-tapidx <tapidx_value>]
[Arguments]
o nets
    type: string
    default value: None 
o type
    type: string
    default value: None 
o disable
    type: switch
    default value: None 
o index
    type: integer
    default value: None 
o loc
    type: string
    default value: None 
o tapidx
    type: integer
    default value: None
```

## phycst.pin.set

```
[Syntax]
   phycst.pin.set  <primary> [<loc>] [-attr <attr_value>]* [-force] [-soft]
[Arguments]
o primary
    type: string
    default value: None 
o loc
    type: string
    default value: None 
o attr
    type: string
    default value: None 
o force
    type: switch
    default value: None 
o soft
    type: switch
    default value: None
```

## phycst.pkgroup.set

```
[Syntax]
   phycst.pkgroup.set  <inst_net_list> <group_name> [-exclusive] [-net]
[Arguments]
o inst_net_list
    type: string
    default value: None 
o group_name
    type: string
    default value: None 
o exclusive
    type: switch
    default value: None 
o net
    type: switch
    default value: None
```

## phycst.region.check

```
[Syntax]
   phycst.region.check  <rect>
[Arguments]
o rect
    type: recursive(ll_loc:S ur_loc:S)
    default value: None
```

## phycst.region.create

```
[Syntax]
   phycst.region.create  <region_name> <rect> [-add] [-type <type_value>]
[Arguments]
o region_name
    type: string
    default value: None 
o rect
    type: recursive(ll_loc:S ur_loc:S)
    default value: None 
o add
    type: switch
    default value: None 
o type
    type: enumerated(inclusive|exclusive|empty)
    default value: None
```

## phycst.region.set

```
[Syntax]
   phycst.region.set  <inst_net_list> <region_name> [-net]
[Arguments]
o inst_net_list
    type: string
    default value: None 
o region_name
    type: string
    default value: None 
o net
    type: switch
    default value: None
```

## phycst.rloc.set

```
[Syntax]
   phycst.rloc.set  <inst> <rloc> <rset>
[Arguments]
o inst
    type: string
    default value: None 
o rloc
    type: string
    default value: None 
o rset
    type: string
    default value: None
```

## phycst.start

```
[Syntax]
   phycst.start 
[Arguments]
```

## phycst.vccio.set

```
[Syntax]
   phycst.vccio.set  <bank> <vccio>
[Arguments]
o bank
    type: string
    default value: None 
o vccio
    type: enumerated(0.9|0.9V|1.2|1.2V|1.35|1.35V|1.5|1.5V|1.8|1.8V|2.5|2.5V|3.3|3.3V|5.0|5.0V)
    default value: None
```

## phyrule.query

```
[Syntax]
   phyrule.query  <what>
[Arguments]
o what
    type: enumerated(rtfo|chk_clkio|bgen_padloc|mutex_io|all)
    default value: all
```

## phyrule.set

```
[Syntax]
   phyrule.set  [-bgen_padloc <bgen_padloc_value>] [-chk_clkio <chk_clkio_value>] [-len_only] [-mutex_io <mutex_io_value>] [-rtfo <rtfo_value>]
[Arguments]
o bgen_padloc
    type: enumerated(on|off)
    default value: None 
o chk_clkio
    type: enumerated(on|off)
    default value: None 
o len_only
    type: switch
    default value: None 
o mutex_io
    type: enumerated(on|off)
    default value: None 
o rtfo
    type: enumerated(on|off)
    default value: None
```

## pid

(无 help 条目)

## pin.cover

(无 help 条目)

## pin2csv

```
[Syntax]
   pin2csv  <csv_file_name>
[Arguments]
o csv_file_name
    type: string
    default value: None
```

## pip.clean

(无 help 条目)

## pip.cover

(无 help 条目)

## pkg_mkIndex

(无 help 条目)

## pl.ap.gpack

```
[Syntax]
   pl.ap.gpack 
[Arguments]
```

## pl.check.clock

```
[Syntax]
   pl.check.clock 
[Arguments]
```

## pl.clk.auto.confine

```
[Syntax]
   pl.clk.auto.confine  <flag> <file> <log> <iter> <cap>
[Arguments]
o flag
    type: enumerated(on|off)
    default value: on 
o file
    type: string
    default value: None 
o log
    type: integer
    default value: None 
o iter
    type: integer
    default value: None 
o cap
    type: integer
    default value: None
```

## pl.clk.store

```
[Syntax]
   pl.clk.store  <flag> [-name <name_value>]
[Arguments]
o flag
    type: enumerated(auto|on|off)
    default value: auto 
o name
    type: string
    default value: None
```

## pl.clkdiv.opt

```
[Syntax]
   pl.clkdiv.opt 
[Arguments]
```

## pl.delay.annotate

```
[Syntax]
   pl.delay.annotate 
[Arguments]
```

## pl.deskew

```
[Syntax]
   pl.deskew 
[Arguments]
```

## pl.eco.load

```
[Syntax]
   pl.eco.load 
[Arguments]
```

## pl.eco.move

```
[Syntax]
   pl.eco.move  <inst> <loc>
[Arguments]
o inst
    type: string
    default value: None 
o loc
    type: string
    default value: None
```

## pl.eco.optimize

```
[Syntax]
   pl.eco.optimize 
[Arguments]
```

## pl.eco.path.opt

```
[Syntax]
   pl.eco.path.opt  <spin> <epin>
[Arguments]
o spin
    type: string
    default value: None 
o epin
    type: string
    default value: None
```

## pl.eco.region.opt

```
[Syntax]
   pl.eco.region.opt  <start> <end>
[Arguments]
o start
    type: string
    default value: None 
o end
    type: string
    default value: None
```

## pl.eco.save

```
[Syntax]
   pl.eco.save 
[Arguments]
```

## pl.eco.start

```
[Syntax]
   pl.eco.start 
[Arguments]
```

## pl.eco.stop

```
[Syntax]
   pl.eco.stop 
[Arguments]
```

## pl.eco.tri.opt

```
[Syntax]
   pl.eco.tri.opt  <beg> <mid> <end>
[Arguments]
o beg
    type: string
    default value: None 
o mid
    type: string
    default value: None 
o end
    type: string
    default value: None
```

## pl.io.check

```
[Syntax]
   pl.io.check 
[Arguments]
```

## pl.slice.trans

```
[Syntax]
   pl.slice.trans 
[Arguments]
```

## pl.test.clk.setup

```
[Syntax]
   pl.test.clk.setup 
[Arguments]
```

## pl.test.clkdist

```
[Syntax]
   pl.test.clkdist  <fn> <limit> [-reduce]
[Arguments]
o fn
    type: string
    default value: None 
o limit
    type: integer
    default value: 10 
o reduce
    type: switch
    default value: None
```

## pl.test.mk.clktree

```
[Syntax]
   pl.test.mk.clktree 
[Arguments]
```

## pl.test.pl.assign

```
[Syntax]
   pl.test.pl.assign  <xpn> <limit>
[Arguments]
o xpn
    type: string
    default value: None 
o limit
    type: integer
    default value: 10
```

## pl.test.rm.clktree

```
[Syntax]
   pl.test.rm.clktree 
[Arguments]
```

## post_set_xise

(无 help 条目)

## postsyn.areaopt

```
[Syntax]
   postsyn.areaopt 
[Arguments]
```

## postsyn.areaopt.query

```
[Syntax]
   postsyn.areaopt.query  <what>
[Arguments]
o what
    type: enumerated(effort|dummy)
    default value: None
```

## postsyn.areaopt.set

```
[Syntax]
   postsyn.areaopt.set  [-effort <effort_value>]
[Arguments]
o effort
    type: enumerated(tiny|low|std|high|extra|extreme|none|auto)
    default value: None
```

## predefined.drtvs.set

```
[Syntax]
   predefined.drtvs.set 
[Arguments]
```

## preopt.clock.assign

```
[Syntax]
   preopt.clock.assign  <to_file>
[Arguments]
o to_file
    type: string
    default value: clk.txt
```

## preopt.lpp.io

```
[Syntax]
   preopt.lpp.io  <to_file>
[Arguments]
o to_file
    type: string
    default value: io_lpp.upc
```

## prep_options

(无 help 条目)

## prep_set_xise

(无 help 条目)

## prep_wns_value

(无 help 条目)

## proc

(无 help 条目)

## progBit

(无 help 条目)

## put_cmd_banner

(无 help 条目)

## puts

(无 help 条目)

## pwd

(无 help 条目)

## queryTopModule

(无 help 条目)

## quiet_run

(无 help 条目)

## read

(无 help 条目)

## readEdifExec

(无 help 条目)

## readOpt

(无 help 条目)

## readPrjOpt

(无 help 条目)

## refine_fmt

(无 help 条目)

## regexp

(无 help 条目)

## regsub

(无 help 条目)

## removePid

(无 help 条目)

## remove_pksi_seal

```
[Syntax]
   remove_pksi_seal 
[Arguments]
```

## rename

(无 help 条目)

## report_timing_derate

```
[Syntax]
   report_timing_derate 
[Arguments]
```

## res.overflow.check

```
[Syntax]
   res.overflow.check  <res_list>
[Arguments]
o res_list
    type: string
    default value: None
```

## res.report

```
[Syntax]
   res.report  [-file <file_value>]
[Arguments]
o file
    type: string
    default value: None
```

## reset_timing_derate

```
[Syntax]
   reset_timing_derate  [-keep_saved]
[Arguments]
o keep_saved
    type: switch
    default value: None
```

## resolve_bitfile_names

(无 help 条目)

## resolve_hqprj2ins_file_dirs

(无 help 条目)

## resolve_hqprj2vio_file_dirs

(无 help 条目)

## resolve_only_bit_file_name

(无 help 条目)

## restore_timing_derate

```
[Syntax]
   restore_timing_derate 
[Arguments]
```

## resyn

```
[Syntax]
   resyn  [-N <N_value>] [-v] [-w]
[Arguments]
o N
    type: integer
    default value: None 
o v
    type: switch
    default value: None 
o w
    type: switch
    default value: None
```

## return

(无 help 条目)

## root.query

```
[Syntax]
   root.query 
[Arguments]
```

## rptXCVtiming

(无 help 条目)

## rt.collect

```
[Syntax]
   rt.collect  [-file1 <file1_value>] [-file2 <file2_value>] [-inRtmain <inRtmain_value>] [-longpathL <longpathL_value>] [-num <num_value>]
[Arguments]
o file1
    type: string
    default value: rt_collector.rpt 
o file2
    type: string
    default value: schematic 
o inRtmain
    type: integer
    default value: 0 
o longpathL
    type: integer
    default value: 100 
o num
    type: integer
    default value: 500
```

## rt.congEst

```
[Syntax]
   rt.congEst  [-file <file_value>] [-isdump <isdump_value>] [-method <method_value>]
[Arguments]
o file
    type: string
    default value: rt_congEst.out 
o isdump
    type: integer
    default value: 1 
o method
    type: integer
    default value: 1
```

## rt.genCongValue

```
[Syntax]
   rt.genCongValue 
[Arguments]
```

## rt.genRoutingResult

```
[Syntax]
   rt.genRoutingResult 
[Arguments]
```

## rt.getCellsPin

```
[Syntax]
   rt.getCellsPin 
[Arguments]
```

## rt.getHardConns

```
[Syntax]
   rt.getHardConns 
[Arguments]
```

## rt.getPinConn

```
[Syntax]
   rt.getPinConn 
[Arguments]
```

## rt.getSpecialWrap

```
[Syntax]
   rt.getSpecialWrap 
[Arguments]
```

## rt.getTileConn

```
[Syntax]
   rt.getTileConn 
[Arguments]
```

## rtl.addfiles

```
[Syntax]
   rtl.addfiles  <src_file_list> [-lib <lib_value>]
[Arguments]
o src_file_list
    type: string
    default value: None 
o lib
    type: string
    default value: None
```

## rtl.analyze

```
[Syntax]
   rtl.analyze  [<src_file_list>]
[Arguments]
o src_file_list
    type: string
    default value: None
```

## rtl.analyzeStr

```
[Syntax]
   rtl.analyzeStr  [-text <text_value>]
[Arguments]
o text
    type: string
    default value: None
```

## rtl.dumpadb

```
[Syntax]
   rtl.dumpadb 
[Arguments]
```

## rtl.dumper

```
[Syntax]
   rtl.dumper  [-json <json_value>]
[Arguments]
o json
    type: string
    default value: None
```

## rtl.dumpsdb

```
[Syntax]
   rtl.dumpsdb  <fn>
[Arguments]
o fn
    type: string
    default value: None
```

## rtl.elaborate

```
[Syntax]
   rtl.elaborate  [-top <top_value>]
[Arguments]
o top
    type: string
    default value: None
```

## rtl.file_filter

```
[Syntax]
   rtl.file_filter  [-top <top_value>]
[Arguments]
o top
    type: string
    default value: None
```

## rtl.incpath.add

```
[Syntax]
   rtl.incpath.add  <inc_path>*
[Arguments]
o inc_path
    type: string
    default value: None
```

## rtl.incpath.clear

```
[Syntax]
   rtl.incpath.clear 
[Arguments]
```

## rtl.incpath.query

```
[Syntax]
   rtl.incpath.query 
[Arguments]
```

## rtl.infer_srl

```
[Syntax]
   rtl.infer_srl 
[Arguments]
```

## rtl.macro.define

```
[Syntax]
   rtl.macro.define  <macro> [<macro_val>]
[Arguments]
o macro
    type: string
    default value: None 
o macro_val
    type: string
    default value: None
```

## rtl.macro.undef

```
[Syntax]
   rtl.macro.undef  <macro>
[Arguments]
o macro
    type: string
    default value: None
```

## rtl.module.list

```
[Syntax]
   rtl.module.list 
[Arguments]
```

## rtl.mux_opt

```
[Syntax]
   rtl.mux_opt  [-timing] [-utilize_muxf]
[Arguments]
o timing
    type: switch
    default value: None 
o utilize_muxf
    type: switch
    default value: None
```

## rtl.query

```
[Syntax]
   rtl.query  [-3rd_party_directive] [-absorb_register_to_dsp] [-acc_min_width] [-all] [-bmul_min_size] [-chk_tribuf] [-complement_way] [-const_cmp_no_carry_width] [-dsp_map] [-enable_third_party_keep] [-expr_opt] [-extract_dff_sync_rs] [-fsm_opt] [-ignore_pdpram_rwconflict] [-infer_ram] [-infer_rom] [-infer_srl] [-infer_srl_length_lb] [-infer_srl_mode] [-inter_ver] [-last_FF_infer_to_SRL] [-lut_combine] [-macro_rebuild] [-map_adder_to_dsp] [-multidim_array] [-mux_opt] [-primary_FF_infer_to_SRL] [-ram] [-ram_infer_min_size] [-ramb_min_addr] [-ramb_min_size] [-ramb_outreg] [-rom] [-share_opt] [-srl] [-srl_style] [-static_srl_mode] [-system_verilog] [-tmp] [-tmp_dir] [-utilize_muxf] [-ver] [-wide_input_eq_infer]
[Arguments]
o 3rd_party_directive
    type: switch
    default value: None 
o absorb_register_to_dsp
    type: switch
    default value: None 
o acc_min_width
    type: switch
    default value: None 
o all
    type: switch
    default value: None 
o bmul_min_size
    type: switch
    default value: None 
o chk_tribuf
    type: switch
    default value: None 
o complement_way
    type: switch
    default value: None 
o const_cmp_no_carry_width
    type: switch
    default value: None 
o dsp_map
    type: switch
    default value: None 
o enable_third_party_keep
    type: switch
    default value: None 
o expr_opt
    type: switch
    default value: None 
o extract_dff_sync_rs
    type: switch
    default value: None 
o fsm_opt
    type: switch
    default value: None 
o ignore_pdpram_rwconflict
    type: switch
    default value: None 
o infer_ram
    type: switch
    default value: None 
o infer_rom
    type: switch
    default value: None 
o infer_srl
    type: switch
    default value: None 
o infer_srl_length_lb
    type: switch
    default value: None 
o infer_srl_mode
    type: switch
    default value: None 
o inter_ver
    type: switch
    default value: None 
o last_FF_infer_to_SRL
    type: switch
    default value: None 
o lut_combine
    type: switch
    default value: None 
o macro_rebuild
    type: switch
    default value: None 
o map_adder_to_dsp
    type: switch
    default value: None 
o multidim_array
    type: switch
    default value: None 
o mux_opt
    type: switch
    default value: None 
o primary_FF_infer_to_SRL
    type: switch
    default value: None 
o ram
    type: switch
    default value: None 
o ram_infer_min_size
    type: switch
    default value: None 
o ramb_min_addr
    type: switch
    default value: None 
o ramb_min_size
    type: switch
    default value: None 
o ramb_outreg
    type: switch
    default value: None 
o rom
    type: switch
    default value: None 
o share_opt
    type: switch
    default value: None 
o srl
    type: switch
    default value: None 
o srl_style
    type: switch
    default value: None 
o static_srl_mode
    type: switch
    default value: None 
o system_verilog
    type: switch
    default value: None 
o tmp
    type: switch
    default value: None 
o tmp_dir
    type: switch
    default value: None 
o utilize_muxf
    type: switch
    default value: None 
o ver
    type: switch
    default value: None 
o wide_input_eq_infer
    type: switch
    default value: None
```

## rtl.res_sharing

```
[Syntax]
   rtl.res_sharing 
[Arguments]
```

## rtl.sdb.expropt

```
[Syntax]
   rtl.sdb.expropt 
[Arguments]
```

## rtl.sdb.toudm

```
[Syntax]
   rtl.sdb.toudm 
[Arguments]
```

## rtl.sdb_opt

```
[Syntax]
   rtl.sdb_opt 
[Arguments]
```

## rtl.set

```
[Syntax]
   rtl.set  [-3rd_party_directive <3rd_party_directive_value>] [-absorb_register_to_dsp <absorb_register_to_dsp_value>] [-acc_min_width <acc_min_width_value>] [-bmul_min_size <bmul_min_size_value>] [-chk_tribuf <chk_tribuf_value>] [-const_cmp_no_carry_width <const_cmp_no_carry_width_value>] [-dsp_map <dsp_map_value>] [-enable_third_party_keep <enable_third_party_keep_value>] [-expr_opt <expr_opt_value>] [-extract_dff_sync_rs <extract_dff_sync_rs_value>] [-fsm_opt <fsm_opt_value>] [-ignore_pdpram_rwconflict] [-infer_ram <infer_ram_value>] [-infer_rom <infer_rom_value>] [-infer_srl <infer_srl_value>] [-infer_srl_length_lb <infer_srl_length_lb_value>] [-infer_srl_mode <infer_srl_mode_value>] [-last_FF_infer_to_SRL <last_FF_infer_to_SRL_value>] [-lut_combine <lut_combine_value>] [-macro_rebuild <macro_rebuild_value>] [-map_adder_to_dsp <map_adder_to_dsp_value>] [-multidim_array <multidim_array_value>] [-mux_opt <mux_opt_value>] [-primary_FF_infer_to_SRL <primary_FF_infer_to_SRL_value>] [-ram_infer_min_size <ram_infer_min_size_value>] [-ramb_min_addr <ramb_min_addr_value>] [-ramb_min_size <ramb_min_size_value>] [-ramb_outreg <ramb_outreg_value>] [-reset_all] [-share_opt <share_opt_value>] [-srl_style <srl_style_value>] [-static_srl_mode <static_srl_mode_value>] [-system_verilog <system_verilog_value>] [-wide_input_eq_infer <wide_input_eq_infer_value>]
[Arguments]
o 3rd_party_directive
    type: enumerated(on|off)
    default value: None 
o absorb_register_to_dsp
    type: enumerated(off|1|2)
    default value: None 
o acc_min_width
    type: integer
    default value: None 
o bmul_min_size
    type: integer
    default value: None 
o chk_tribuf
    type: enumerated(on|off)
    default value: None 
o const_cmp_no_carry_width
    type: integer
    default value: None 
o dsp_map
    type: enumerated(on|off)
    default value: None 
o enable_third_party_keep
    type: enumerated(on|off)
    default value: None 
o expr_opt
    type: enumerated(on|off)
    default value: None 
o extract_dff_sync_rs
    type: enumerated(on|off)
    default value: None 
o fsm_opt
    type: enumerated(on|off)
    default value: None 
o ignore_pdpram_rwconflict
    type: switch
    default value: None 
o infer_ram
    type: enumerated(on|off)
    default value: None 
o infer_rom
    type: enumerated(on|off)
    default value: None 
o infer_srl
    type: enumerated(on|off)
    default value: None 
o infer_srl_length_lb
    type: integer
    default value: None 
o infer_srl_mode
    type: enumerated(area|timing)
    default value: None 
o last_FF_infer_to_SRL
    type: enumerated(on|off)
    default value: None 
o lut_combine
    type: enumerated(on|off)
    default value: None 
o macro_rebuild
    type: enumerated(on|off)
    default value: None 
o map_adder_to_dsp
    type: enumerated(on|off)
    default value: None 
o multidim_array
    type: enumerated(on|off)
    default value: None 
o mux_opt
    type: enumerated(on|off)
    default value: None 
o primary_FF_infer_to_SRL
    type: enumerated(on|off)
    default value: None 
o ram_infer_min_size
    type: integer
    default value: None 
o ramb_min_addr
    type: integer
    default value: None 
o ramb_min_size
    type: integer
    default value: None 
o ramb_outreg
    type: enumerated(on|off)
    default value: None 
o reset_all
    type: switch
    default value: None 
o share_opt
    type: enumerated(on|off)
    default value: None 
o srl_style
    type: enumerated(registers|srl|ram|auto)
    default value: None 
o static_srl_mode
    type: enumerated(area|timing)
    default value: None 
o system_verilog
    type: enumerated(on|off)
    default value: None 
o wide_input_eq_infer
    type: enumerated(on|off)
    default value: None
```

## rtl.sfe.pp

```
[Syntax]
   rtl.sfe.pp  <src_file> [-output <output_value>]
[Arguments]
o src_file
    type: string
    default value: None 
o output
    type: string
    default value: None
```

## rtl.srcfiles.list

```
[Syntax]
   rtl.srcfiles.list  [-no_filechk] [-print]
[Arguments]
o no_filechk
    type: switch
    default value: None 
o print
    type: switch
    default value: None
```

## rtl.topmodule.list

```
[Syntax]
   rtl.topmodule.list 
[Arguments]
```

## rtl_loc_to_phy

```
[Syntax]
   rtl_loc_to_phy 
[Arguments]
```

## runChipEdit

(无 help 条目)

## runDesignExplorer

(无 help 条目)

## runHqInsDbgr

(无 help 条目)

## runHqInsImpl

(无 help 条目)

## runHqInstrumentor

(无 help 条目)

## runIpCreator

(无 help 条目)

## runNlViewer

(无 help 条目)

## runProg

(无 help 条目)

## runRtHeatmapViewer

(无 help 条目)

## runVioDebugger

(无 help 条目)

## runVlaDebugger

(无 help 条目)

## run__hq__dynamic_ucmd__0

(无 help 条目)

## run_hqprj2hqins_flow

(无 help 条目)

## run_hqprj2hqvio_flow

(无 help 条目)

## run_hqprj_flow

(无 help 条目)

## sa5tosk7_trans_xpn

(无 help 条目)

## saveUdm

(无 help 条目)

## save_timing_derate

```
[Syntax]
   save_timing_derate 
[Arguments]
```

## scan

(无 help 条目)

## sdb.read

```
[Syntax]
   sdb.read  <filename> [-pure]
[Arguments]
o filename
    type: string
    default value: None 
o pure
    type: switch
    default value: None
```

## sdb.write

```
[Syntax]
   sdb.write  <filename>
[Arguments]
o filename
    type: string
    default value: None
```

## sdc.end

```
[Syntax]
   sdc.end 
[Arguments]
```

## sdc.normalize

```
[Syntax]
   sdc.normalize  [-ignore_derived_clocks]
[Arguments]
o ignore_derived_clocks
    type: switch
    default value: None
```

## sdc.read

```
[Syntax]
   sdc.read  <filename>
[Arguments]
o filename
    type: string
    default value: None
```

## sdc.start

```
[Syntax]
   sdc.start  [-mode <mode_value>] [-view <view_value>]
[Arguments]
o mode
    type: string
    default value: None 
o view
    type: object_reference
    default value: None
```

## sdf.write

```
[Syntax]
   sdf.write  <filename> [<nview>]
[Arguments]
o filename
    type: string
    default value: None 
o nview
    type: object_reference
    default value: None
```

## seek

(无 help 条目)

## set

(无 help 条目)

## set_clock_groups

```
[Syntax]
   set_clock_groups  [-asynchronous] [-comment <comment_value>] [-derive] [-disable] [-exclusive] [-group <group_value>]* [-logically_exclusive] [-name <name_value>] [-physically_exclusive]
[Arguments]
o asynchronous
    type: switch
    default value: None 
o comment
    type: string
    default value: None 
o derive
    type: switch
    default value: None 
o disable
    type: switch
    default value: None 
o exclusive
    type: switch
    default value: None 
o group
    type: string
    default value: None 
o logically_exclusive
    type: switch
    default value: None 
o name
    type: string
    default value: None 
o physically_exclusive
    type: switch
    default value: None
```

## set_clock_latency

```
[Syntax]
   set_clock_latency  <delay> <object_list> [-clock <clock_value>] [-early] [-fall] [-late] [-max] [-min] [-rise] [-source]
[Arguments]
o delay
    type: double
    default value: None 
o object_list
    type: string
    default value: None 
o clock
    type: string
    default value: None 
o early
    type: switch
    default value: None 
o fall
    type: switch
    default value: None 
o late
    type: switch
    default value: None 
o max
    type: switch
    default value: None 
o min
    type: switch
    default value: None 
o rise
    type: switch
    default value: None 
o source
    type: switch
    default value: None
```

## set_clock_uncertainty

```
[Syntax]
   set_clock_uncertainty  <uncertainty> [<object_list>] [-fall] [-fall_from <fall_from_value>] [-fall_to <fall_to_value>] [-from <from_value>] [-hold] [-rise] [-rise_from <rise_from_value>] [-rise_to <rise_to_value>] [-setup] [-to <to_value>]
[Arguments]
o uncertainty
    type: double
    default value: None 
o object_list
    type: string
    default value: None 
o fall
    type: switch
    default value: None 
o fall_from
    type: string
    default value: None 
o fall_to
    type: string
    default value: None 
o from
    type: string
    default value: None 
o hold
    type: switch
    default value: None 
o rise
    type: switch
    default value: None 
o rise_from
    type: string
    default value: None 
o rise_to
    type: string
    default value: None 
o setup
    type: switch
    default value: None 
o to
    type: string
    default value: None
```

## set_false_path

```
[Syntax]
   set_false_path  [-fall] [-fall_from <fall_from_value>] [-fall_through <fall_through_value>]* [-fall_to <fall_to_value>] [-from <from_value>] [-hold] [-rise] [-rise_from <rise_from_value>] [-rise_through <rise_through_value>]* [-rise_to <rise_to_value>] [-setup] [-through <through_value>]* [-to <to_value>]
[Arguments]
o fall
    type: switch
    default value: None 
o fall_from
    type: string
    default value: None 
o fall_through
    type: string
    default value: None 
o fall_to
    type: string
    default value: None 
o from
    type: string
    default value: None 
o hold
    type: switch
    default value: None 
o rise
    type: switch
    default value: None 
o rise_from
    type: string
    default value: None 
o rise_through
    type: string
    default value: None 
o rise_to
    type: string
    default value: None 
o setup
    type: switch
    default value: None 
o through
    type: string
    default value: None 
o to
    type: string
    default value: None
```

## set_hierarchy_separator

```
[Syntax]
   set_hierarchy_separator  <hsc>
[Arguments]
o hsc
    type: string
    default value: None
```

## set_input_delay

```
[Syntax]
   set_input_delay  <delay_value> <port_pin_list> [-add_delay] [-clock <clock_value>] [-clock_fall] [-fall] [-level_sensitive] [-max] [-min] [-network_latency_included] [-rise] [-source_latency_included]
[Arguments]
o delay_value
    type: double
    default value: None 
o port_pin_list
    type: string
    default value: None 
o add_delay
    type: switch
    default value: None 
o clock
    type: string
    default value: None 
o clock_fall
    type: switch
    default value: None 
o fall
    type: switch
    default value: None 
o level_sensitive
    type: switch
    default value: None 
o max
    type: switch
    default value: None 
o min
    type: switch
    default value: None 
o network_latency_included
    type: switch
    default value: None 
o rise
    type: switch
    default value: None 
o source_latency_included
    type: switch
    default value: None
```

## set_max_delay

```
[Syntax]
   set_max_delay  <delay_value> [-fall] [-fall_from <fall_from_value>] [-fall_through <fall_through_value>]* [-fall_to <fall_to_value>] [-from <from_value>] [-rise] [-rise_from <rise_from_value>] [-rise_through <rise_through_value>]* [-rise_to <rise_to_value>] [-through <through_value>]* [-to <to_value>]
[Arguments]
o delay_value
    type: double
    default value: None 
o fall
    type: switch
    default value: None 
o fall_from
    type: string
    default value: None 
o fall_through
    type: string
    default value: None 
o fall_to
    type: string
    default value: None 
o from
    type: string
    default value: None 
o rise
    type: switch
    default value: None 
o rise_from
    type: string
    default value: None 
o rise_through
    type: string
    default value: None 
o rise_to
    type: string
    default value: None 
o through
    type: string
    default value: None 
o to
    type: string
    default value: None
```

## set_min_delay

```
[Syntax]
   set_min_delay  <delay_value> [-fall] [-fall_from <fall_from_value>] [-fall_through <fall_through_value>]* [-fall_to <fall_to_value>] [-from <from_value>] [-rise] [-rise_from <rise_from_value>] [-rise_through <rise_through_value>]* [-rise_to <rise_to_value>] [-through <through_value>]* [-to <to_value>]
[Arguments]
o delay_value
    type: double
    default value: None 
o fall
    type: switch
    default value: None 
o fall_from
    type: string
    default value: None 
o fall_through
    type: string
    default value: None 
o fall_to
    type: string
    default value: None 
o from
    type: string
    default value: None 
o rise
    type: switch
    default value: None 
o rise_from
    type: string
    default value: None 
o rise_through
    type: string
    default value: None 
o rise_to
    type: string
    default value: None 
o through
    type: string
    default value: None 
o to
    type: string
    default value: None
```

## set_multicycle_path

```
[Syntax]
   set_multicycle_path  <path_multiplier> [-end] [-fall] [-fall_from <fall_from_value>] [-fall_through <fall_through_value>]* [-fall_to <fall_to_value>] [-from <from_value>] [-hold] [-rise] [-rise_from <rise_from_value>] [-rise_through <rise_through_value>]* [-rise_to <rise_to_value>] [-setup] [-start] [-through <through_value>]* [-to <to_value>]
[Arguments]
o path_multiplier
    type: double
    default value: None 
o end
    type: switch
    default value: None 
o fall
    type: switch
    default value: None 
o fall_from
    type: string
    default value: None 
o fall_through
    type: string
    default value: None 
o fall_to
    type: string
    default value: None 
o from
    type: string
    default value: None 
o hold
    type: switch
    default value: None 
o rise
    type: switch
    default value: None 
o rise_from
    type: string
    default value: None 
o rise_through
    type: string
    default value: None 
o rise_to
    type: string
    default value: None 
o setup
    type: switch
    default value: None 
o start
    type: switch
    default value: None 
o through
    type: string
    default value: None 
o to
    type: string
    default value: None
```

## set_output_delay

```
[Syntax]
   set_output_delay  <delay_value> <port_pin_list> [-add_delay] [-clock <clock_value>] [-clock_fall] [-fall] [-level_sensitive] [-max] [-min] [-network_latency_included] [-rise] [-source_latency_included]
[Arguments]
o delay_value
    type: double
    default value: None 
o port_pin_list
    type: string
    default value: None 
o add_delay
    type: switch
    default value: None 
o clock
    type: string
    default value: None 
o clock_fall
    type: switch
    default value: None 
o fall
    type: switch
    default value: None 
o level_sensitive
    type: switch
    default value: None 
o max
    type: switch
    default value: None 
o min
    type: switch
    default value: None 
o network_latency_included
    type: switch
    default value: None 
o rise
    type: switch
    default value: None 
o source_latency_included
    type: switch
    default value: None
```

## set_propagated_clock

```
[Syntax]
   set_propagated_clock  <clks>
[Arguments]
o clks
    type: string
    default value: None
```

## set_timing_derate

```
[Syntax]
   set_timing_derate  <derate_value> [-cell_check] [-cell_delay] [-clock] [-data] [-early] [-fall] [-late] [-net_delay] [-rise]
[Arguments]
o derate_value
    type: double
    default value: None 
o cell_check
    type: switch
    default value: None 
o cell_delay
    type: switch
    default value: None 
o clock
    type: switch
    default value: None 
o data
    type: switch
    default value: None 
o early
    type: switch
    default value: None 
o fall
    type: switch
    default value: None 
o late
    type: switch
    default value: None 
o net_delay
    type: switch
    default value: None 
o rise
    type: switch
    default value: None
```

## showcmd

(无 help 条目)

## socket

(无 help 条目)

## source

(无 help 条目)

## spc.write

```
[Syntax]
   spc.write  <filename> [-cell <cell_value>]
[Arguments]
o filename
    type: string
    default value: None 
o cell
    type: object_reference
    default value: None
```

## split

(无 help 条目)

## srchpath.config

```
[Syntax]
   srchpath.config  <path_list> [-add]
[Arguments]
o path_list
    type: string
    default value: None 
o add
    type: switch
    default value: None
```

## srchpath.query

```
[Syntax]
   srchpath.query 
[Arguments]
```

## string

(无 help 条目)

## subst

(无 help 条目)

## svf_post_process

(无 help 条目)

## switch

(无 help 条目)

## ta.check

```
[Syntax]
   ta.check  [-detail] [-uncst_clk]
[Arguments]
o detail
    type: switch
    default value: None 
o uncst_clk
    type: switch
    default value: None
```

## ta.clock.info

```
[Syntax]
   ta.clock.info  <clock_obj> <what> [-ps]
[Arguments]
o clock_obj
    type: string
    default value: None 
o what
    type: enumerated(name|period|waveform|is_active|is_nonuser|all)
    default value: all 
o ps
    type: switch
    default value: None
```

## ta.clock.list

```
[Syntax]
   ta.clock.list  [-inc_non_active] [-name] [-objnm] [-uncst_last] [-uncst_only]
[Arguments]
o inc_non_active
    type: switch
    default value: None 
o name
    type: switch
    default value: None 
o objnm
    type: switch
    default value: None 
o uncst_last
    type: switch
    default value: None 
o uncst_only
    type: switch
    default value: None
```

## ta.clock.report

```
[Syntax]
   ta.clock.report 
[Arguments]
```

## ta.end

```
[Syntax]
   ta.end 
[Arguments]
```

## ta.fmax.report

```
[Syntax]
   ta.fmax.report  [-fields <fields_value>] [-iph]
[Arguments]
o fields
    type: string
    default value: None 
o iph
    type: switch
    default value: None
```

## ta.report

```
[Syntax]
   ta.report  [-exclude <exclude_value>] [-fields <fields_value>] [-from <from_value>] [-from_clk <from_clk_value>] [-iph] [-m <m_value>] [-max_common_paths <max_common_paths_value>] [-max_common_start <max_common_start_value>] [-max_paths <max_paths_value>] [-ms <ms_value>] [-n <n_value>] [-no_header] [-through <through_value>]* [-to <to_value>] [-to_clk <to_clk_value>] [-type <type_value>]
[Arguments]
o exclude
    type: string
    default value: None 
o fields
    type: string
    default value: None 
o from
    type: string
    default value: None 
o from_clk
    type: string
    default value: None 
o iph
    type: switch
    default value: None 
o m
    type: integer
    default value: None 
o max_common_paths
    type: integer
    default value: None 
o max_common_start
    type: integer
    default value: None 
o max_paths
    type: integer
    default value: None 
o ms
    type: integer
    default value: None 
o n
    type: integer
    default value: None 
o no_header
    type: switch
    default value: None 
o through
    type: string
    default value: None 
o to
    type: string
    default value: None 
o to_clk
    type: string
    default value: None 
o type
    type: enumerated(setup|hold)
    default value: setup
```

## ta.run

```
[Syntax]
   ta.run 
[Arguments]
```

## ta.set

```
[Syntax]
   ta.set  [-a2q <a2q_value>] [-actrl2q <actrl2q_value>] [-analysis_type <analysis_type_value>] [-at <at_value>] [-cca <cca_value>] [-clock_name_style <clock_name_style_value>] [-cns <cns_value>] [-cross_clkdom_analysis <cross_clkdom_analysis_value>] [-dlb <dlb_value>] [-dynamic_loop_breaking <dynamic_loop_breaking_value>] [-genclk_msg <genclk_msg_value>] [-io_reg_analysis <io_reg_analysis_value>] [-ira <ira_value>] [-keep_ref_obj <keep_ref_obj_value>] [-min_pulse_width <min_pulse_width_value>] [-mpw <mpw_value>] [-reset_all] [-see_thru_usr_hier <see_thru_usr_hier_value>] [-stuh <stuh_value>] [-time_unit <time_unit_value>] [-tu <tu_value>] [-ucp <ucp_value>] [-uncst_clk <uncst_clk_value>] [-uncst_clk_period <uncst_clk_period_value>]
[Arguments]
o a2q
    type: enumerated(on|off)
    default value: None 
o actrl2q
    type: enumerated(on|off)
    default value: None 
o analysis_type
    type: enumerated(setup|hold|both)
    default value: None 
o at
    type: enumerated(setup|hold|both)
    default value: None 
o cca
    type: enumerated(on|off)
    default value: None 
o clock_name_style
    type: enumerated(pin|net|pin_net|net_pin)
    default value: None 
o cns
    type: enumerated(pin|net|pin_net|net_pin)
    default value: None 
o cross_clkdom_analysis
    type: enumerated(on|off)
    default value: None 
o dlb
    type: enumerated(on|off)
    default value: None 
o dynamic_loop_breaking
    type: enumerated(on|off)
    default value: None 
o genclk_msg
    type: enumerated(on|off)
    default value: None 
o io_reg_analysis
    type: enumerated(on|off)
    default value: None 
o ira
    type: enumerated(on|off)
    default value: None 
o keep_ref_obj
    type: enumerated(on|off)
    default value: None 
o min_pulse_width
    type: enumerated(on|off)
    default value: None 
o mpw
    type: enumerated(on|off)
    default value: None 
o reset_all
    type: switch
    default value: None 
o see_thru_usr_hier
    type: enumerated(on|off)
    default value: None 
o stuh
    type: enumerated(on|off)
    default value: None 
o time_unit
    type: enumerated(1ps|10ps|100ps|1ns|10ns|100ns|1us|10us|100us|1ms|10ms|100ms|1s)
    default value: None 
o tu
    type: enumerated(1ps|10ps|100ps|1ns|10ns|100ns|1us|10us|100us|1ms|10ms|100ms|1s)
    default value: None 
o ucp
    type: double
    default value: None 
o uncst_clk
    type: enumerated(on|off)
    default value: on 
o uncst_clk_period
    type: double
    default value: None
```

## ta.slack.report

```
[Syntax]
   ta.slack.report  [-n <n_value>] [-rptf <rptf_value>]
[Arguments]
o n
    type: integer
    default value: 10 
o rptf
    type: string
    default value: None
```

## tailcall

(无 help 条目)

## tarc.begin

```
[Syntax]
   tarc.begin  <cell>
[Arguments]
o cell
    type: object_reference
    default value: None
```

## tarc.cfgval.map

```
[Syntax]
   tarc.cfgval.map  <map_list> [-cfg_mode <cfg_mode_value>]
[Arguments]
o map_list
    type: string
    default value: None 
o cfg_mode
    type: string
    default value: None
```

## tarc.def_cfg_mode

```
[Syntax]
   tarc.def_cfg_mode  <cfg_mode> <mode_cond>
[Arguments]
o cfg_mode
    type: string
    default value: None 
o mode_cond
    type: string
    default value: None
```

## tarc.derate.clear

```
[Syntax]
   tarc.derate.clear 
[Arguments]
```

## tarc.derate.query

```
[Syntax]
   tarc.derate.query  <cell>
[Arguments]
o cell
    type: object_reference
    default value: None
```

## tarc.derate.set

```
[Syntax]
   tarc.derate.set  <cell> <factor>
[Arguments]
o cell
    type: object_reference
    default value: None 
o factor
    type: double
    default value: None
```

## tarc.end

```
[Syntax]
   tarc.end 
[Arguments]
```

## tarc.set

```
[Syntax]
   tarc.set  <type> <value> <from> <to> [-abs_adjust] [-adjust <adjust_value>]* [-cfg_mode <cfg_mode_value>] [-cond <cond_value>] [-conn <conn_value>] [-logic_sense <logic_sense_value>] [-name <name_value>] [-seq2comb <seq2comb_value>] [-switch_cfg <switch_cfg_value>]
[Arguments]
o type
    type: enumerated(setup_rising|hold_rising|combinational|preset|clear|setup_falling|hold_falling|rising_edge|falling_edge|three_state_enable|three_state_disable|recovery_rising|recovery_falling|removal_rising|removal_falling|min_pulse_width_high|min_pulse_width_low)
    default value: None 
o value
    type: string
    default value: None 
o from
    type: string
    default value: None 
o to
    type: string
    default value: None 
o abs_adjust
    type: switch
    default value: None 
o adjust
    type: string
    default value: None 
o cfg_mode
    type: string
    default value: None 
o cond
    type: string
    default value: None 
o conn
    type: string
    default value: None 
o logic_sense
    type: enumerated(pos_unate|neg_unate|non_unate)
    default value: non_unate 
o name
    type: string
    default value: None 
o seq2comb
    type: string
    default value: None 
o switch_cfg
    type: string
    default value: None
```

## taset.query

```
[Syntax]
   taset.query  [-a2q] [-actrl2q] [-all] [-analysis_type] [-at] [-cca] [-clock_name_style] [-cns] [-cross_clkdom_analysis] [-dlb] [-dynamic_loop_breaking] [-genclk_msg] [-io_reg_analysis] [-ira] [-keep_ref_obj] [-max_logic_level] [-min_pulse_width] [-mll] [-mpw] [-see_thru_usr_hier] [-stuh] [-time_unit] [-tu] [-ucp] [-uncst_clk] [-uncst_clk_period]
[Arguments]
o a2q
    type: switch
    default value: None 
o actrl2q
    type: switch
    default value: None 
o all
    type: switch
    default value: None 
o analysis_type
    type: switch
    default value: None 
o at
    type: switch
    default value: None 
o cca
    type: switch
    default value: None 
o clock_name_style
    type: switch
    default value: None 
o cns
    type: switch
    default value: None 
o cross_clkdom_analysis
    type: switch
    default value: None 
o dlb
    type: switch
    default value: None 
o dynamic_loop_breaking
    type: switch
    default value: None 
o genclk_msg
    type: switch
    default value: None 
o io_reg_analysis
    type: switch
    default value: None 
o ira
    type: switch
    default value: None 
o keep_ref_obj
    type: switch
    default value: None 
o max_logic_level
    type: switch
    default value: None 
o min_pulse_width
    type: switch
    default value: None 
o mll
    type: switch
    default value: None 
o mpw
    type: switch
    default value: None 
o see_thru_usr_hier
    type: switch
    default value: None 
o stuh
    type: switch
    default value: None 
o time_unit
    type: switch
    default value: None 
o tu
    type: switch
    default value: None 
o ucp
    type: switch
    default value: None 
o uncst_clk
    type: switch
    default value: None 
o uncst_clk_period
    type: switch
    default value: None
```

## tc.autogen

```
[Syntax]
   tc.autogen  [-force] [-idly <idly_value>] [-odly <odly_value>] [-period <period_value>] [-print] [-use_detclk]
[Arguments]
o force
    type: switch
    default value: None 
o idly
    type: double
    default value: None 
o odly
    type: double
    default value: None 
o period
    type: double
    default value: 10.0 
o print
    type: switch
    default value: None 
o use_detclk
    type: switch
    default value: None
```

## tc.clear

```
[Syntax]
   tc.clear 
[Arguments]
```

## tc.query

```
[Syntax]
   tc.query  <what>
[Arguments]
o what
    type: enumerated(ifany|clocks)
    default value: None
```

## tc.synclocks.set

```
[Syntax]
   tc.synclocks.set  <clock_list>
[Arguments]
o clock_list
    type: string
    default value: None
```

## tclLog

(无 help 条目)

## tclPkgSetup

(无 help 条目)

## tclPkgUnknown

(无 help 条目)

## tell

(无 help 条目)

## test.legalizor

```
[Syntax]
   test.legalizor 
[Arguments]
```

## test.part

```
[Syntax]
   test.part  <part> <size> <pass>
[Arguments]
o part
    type: integer
    default value: None 
o size
    type: integer
    default value: None 
o pass
    type: integer
    default value: None
```

## test.proute

```
[Syntax]
   test.proute 
[Arguments]
```

## test.silicon

```
[Syntax]
   test.silicon 
[Arguments]
```

## test.track

```
[Syntax]
   test.track  <seed> <nregion> <limit>
[Arguments]
o seed
    type: integer
    default value: None 
o nregion
    type: integer
    default value: None 
o limit
    type: integer
    default value: None
```

## test.udm2graph

```
[Syntax]
   test.udm2graph 
[Arguments]
```

## test.vlahub.insert

```
[Syntax]
   test.vlahub.insert  [-flatten]
[Arguments]
o flatten
    type: switch
    default value: None
```

## throw

(无 help 条目)

## time

(无 help 条目)

## timing.report

```
[Syntax]
   timing.report  <obj> [-cell_only] [-int_only]
[Arguments]
o obj
    type: object_reference
    default value: ~ 
o cell_only
    type: switch
    default value: None 
o int_only
    type: switch
    default value: None
```

## topview.lo.decomp

(无 help 条目)

## topview.lo.tdo

(无 help 条目)

## trace

(无 help 条目)

## trans_lo_args

(无 help 条目)

## trans_rsyn_args

(无 help 条目)

## trpt.end

```
[Syntax]
   trpt.end 
[Arguments]
```

## trpt.start

```
[Syntax]
   trpt.start  [-mode <mode_value>] [-view <view_value>]
[Arguments]
o mode
    type: string
    default value: None 
o view
    type: object_reference
    default value: None
```

## try

(无 help 条目)

## ucf.write

```
[Syntax]
   ucf.write  <fname> [-period <period_value>]
[Arguments]
o fname
    type: string
    default value: None 
o period
    type: double
    default value: None
```

## ucf2upc

```
[Syntax]
   ucf2upc  <ucfnm> <upcfnm> [-conv_instloc]
[Arguments]
o ucfnm
    type: string
    default value: None 
o upcfnm
    type: string
    default value: None 
o conv_instloc
    type: switch
    default value: None
```

## ucmd.arg.is_switch

```
[Syntax]
   ucmd.arg.is_switch  <value>
[Arguments]
o value
    type: string
    default value: None
```

## ucmd.define

```
[Syntax]
   ucmd.define  <name> <format> <script>
[Arguments]
o name
    type: string
    default value: None 
o format
    type: string
    default value: None 
o script
    type: string
    default value: None
```

## udb.info

```
[Syntax]
   udb.info  <file> <what>
[Arguments]
o file
    type: string
    default value: None 
o what
    type: enumerated(version|has_tcst)
    default value: None
```

## udev.add_comp

```
[Syntax]
   udev.add_comp  <tile> <comp> <loc> [-pin_map <pin_map_value>]
[Arguments]
o tile
    type: string
    default value: None 
o comp
    type: string
    default value: None 
o loc
    type: string
    default value: None 
o pin_map
    type: string
    default value: None
```

## udev.bank.info

```
[Syntax]
   udev.bank.info  <key> <val>
[Arguments]
o key
    type: string
    default value: None 
o val
    type: string
    default value: None
```

## udev.bank.iotype

```
[Syntax]
   udev.bank.iotype  <id> <type>
[Arguments]
o id
    type: integer
    default value: None 
o type
    type: string
    default value: None
```

## udev.clear

```
[Syntax]
   udev.clear 
[Arguments]
```

## udev.comp

```
[Syntax]
   udev.comp  <name>
[Arguments]
o name
    type: string
    default value: None
```

## udev.conn

```
[Syntax]
   udev.conn  <sink> <src>*
[Arguments]
o sink
    type: string
    default value: None 
o src
    type: string
    default value: None
```

## udev.device

```
[Syntax]
   udev.device  <family>
[Arguments]
o family
    type: string
    default value: None
```

## udev.fill

```
[Syntax]
   udev.fill 
[Arguments]
```

## udev.fp.add_tile

```
[Syntax]
   udev.fp.add_tile  <loc> <tile> <row> <col>
[Arguments]
o loc
    type: string
    default value: None 
o tile
    type: string
    default value: None 
o row
    type: integer
    default value: None 
o col
    type: integer
    default value: None
```

## udev.group

```
[Syntax]
   udev.group  <grp>*
[Arguments]
o grp
    type: string
    default value: None
```

## udev.init_floorplan

```
[Syntax]
   udev.init_floorplan  <row> <col>
[Arguments]
o row
    type: integer
    default value: None 
o col
    type: integer
    default value: None
```

## udev.loc.conn

```
[Syntax]
   udev.loc.conn  <loc> <port>
[Arguments]
o loc
    type: string
    default value: None 
o port
    type: string
    default value: None
```

## udev.model

```
[Syntax]
   udev.model  <name> <comp>
[Arguments]
o name
    type: string
    default value: None 
o comp
    type: string
    default value: None
```

## udev.pad.bind

```
[Syntax]
   udev.pad.bind  <pad> <loc> <desc> <bank>
[Arguments]
o pad
    type: string
    default value: None 
o loc
    type: string
    default value: None 
o desc
    type: string
    default value: None 
o bank
    type: integer
    default value: None
```

## udev.pinmap.begin

```
[Syntax]
   udev.pinmap.begin  <name> <pin_cnt>
[Arguments]
o name
    type: string
    default value: None 
o pin_cnt
    type: integer
    default value: None
```

## udev.pinmap.end

```
[Syntax]
   udev.pinmap.end 
[Arguments]
```

## udev.pinmap.pin

```
[Syntax]
   udev.pinmap.pin  <name> <wire> <dir> <type> <yoff> <xoff>
[Arguments]
o name
    type: string
    default value: None 
o wire
    type: string
    default value: None 
o dir
    type: string
    default value: None 
o type
    type: string
    default value: None 
o yoff
    type: integer
    default value: None 
o xoff
    type: integer
    default value: None
```

## udev.port

```
[Syntax]
   udev.port  <model> <port> <type> [<row>] [<col>]
[Arguments]
o model
    type: string
    default value: None 
o port
    type: string
    default value: None 
o type
    type: string
    default value: None 
o row
    type: integer
    default value: None 
o col
    type: integer
    default value: None
```

## udev.query.resource

```
[Syntax]
   udev.query.resource  <name>
[Arguments]
o name
    type: string
    default value: None
```

## udev.test

```
[Syntax]
   udev.test 
[Arguments]
```

## udev.tile

```
[Syntax]
   udev.tile  <name> <num>
[Arguments]
o name
    type: string
    default value: None 
o num
    type: integer
    default value: None
```

## udtBitGen

(无 help 条目)

## unknown

(无 help 条目)

## unload

(无 help 条目)

## unset

(无 help 条目)

## unset_glbl_vars

(无 help 条目)

## upc.clear

```
[Syntax]
   upc.clear 
[Arguments]
```

## upc.read

```
[Syntax]
   upc.read  <file_name> [-encoding <encoding_value>]
[Arguments]
o file_name
    type: string
    default value: None 
o encoding
    type: string
    default value: utf-8
```

## updAllRtlSrcFileList

(无 help 条目)

## updModuleList

(无 help 条目)

## update

(无 help 条目)

## uplevel

(无 help 条目)

## upvar

(无 help 条目)

## variable

(无 help 条目)

## vio.en.write

```
[Syntax]
   vio.en.write  <ovalue>
[Arguments]
o ovalue
    type: string
    default value: None
```

## vio.ip.create

```
[Syntax]
   vio.ip.create  [-I <I_value>] [-O <O_value>] [-output_module <output_module_value>]
[Arguments]
o I
    type: string
    default value: None 
o O
    type: string
    default value: None 
o output_module
    type: string
    default value: None
```

## vio.read

```
[Syntax]
   vio.read  <ilength>
[Arguments]
o ilength
    type: integer
    default value: None
```

## vio.write

```
[Syntax]
   vio.write  <ovalue>
[Arguments]
o ovalue
    type: string
    default value: None
```

## vla.condition

```
[Syntax]
   vla.condition  <cmd> <la> <is_continuous> <is_te> <expr_op> [-cond <cond_value>] [-cond_path <cond_path_value>] [-op <op_value>] [-operand <operand_value>] [-te <te_value>] [-vio_ovalue <vio_ovalue_value>]
[Arguments]
o cmd
    type: enumerated(get|set)
    default value: None 
o la
    type: integer
    default value: None 
o is_continuous
    type: string
    default value: None 
o is_te
    type: string
    default value: None 
o expr_op
    type: string
    default value: None 
o cond
    type: integer
    default value: None 
o cond_path
    type: string
    default value: None 
o op
    type: string
    default value: None 
o operand
    type: string
    default value: None 
o te
    type: string
    default value: None 
o vio_ovalue
    type: string
    default value: None
```

## vla.offset

```
[Syntax]
   vla.offset  <cmd> <la> [-offset <offset_value>] [-vio_ovalue <vio_ovalue_value>]
[Arguments]
o cmd
    type: enumerated(get|set)
    default value: None 
o la
    type: integer
    default value: None 
o offset
    type: integer
    default value: None 
o vio_ovalue
    type: string
    default value: None
```

## vla.reset

```
[Syntax]
   vla.reset  <la> [-vio_ovalue <vio_ovalue_value>]
[Arguments]
o la
    type: integer
    default value: None 
o vio_ovalue
    type: string
    default value: None
```

## vla.status

```
[Syntax]
   vla.status  <la> [-vio_ovalue <vio_ovalue_value>]
[Arguments]
o la
    type: integer
    default value: None 
o vio_ovalue
    type: string
    default value: None
```

## vla.waveform

```
[Syntax]
   vla.waveform  <la> <hier> [-out <out_value>] [-vio_ovalue <vio_ovalue_value>]
[Arguments]
o la
    type: integer
    default value: None 
o hier
    type: integer
    default value: None 
o out
    type: string
    default value: None 
o vio_ovalue
    type: string
    default value: None
```

## vwait

(无 help 条目)

## while

(无 help 条目)

## wrap_cmd

(无 help 条目)

## writeDesignImportClkReport

(无 help 条目)

## writeRouteClkReport

(无 help 条目)

## writeXstPrj

(无 help 条目)

## writeXstXst

(无 help 条目)

## write_Kill_List

(无 help 条目)

## xdata.delete

```
[Syntax]
   xdata.delete  <xdata_name>
[Arguments]
o xdata_name
    type: string
    default value: None
```

## xdata.fix

```
[Syntax]
   xdata.fix 
[Arguments]
```

## xdata.normalize

```
[Syntax]
   xdata.normalize 
[Arguments]
```

## xdl.cfg.simplify

```
[Syntax]
   xdl.cfg.simplify 
[Arguments]
```

## xdl.icdelay.annotate

```
[Syntax]
   xdl.icdelay.annotate 
[Arguments]
```

## xdl.read

```
[Syntax]
   xdl.read  <filename> <family> [-no_openup] [-tolib <tolib_value>]
[Arguments]
o filename
    type: string
    default value: None 
o family
    type: string
    default value: None 
o no_openup
    type: switch
    default value: None 
o tolib
    type: object_reference
    default value: None
```

## xdl.write

```
[Syntax]
   xdl.write  <filename> [<fm_nmmap>] [<fm_tool>]
[Arguments]
o filename
    type: string
    default value: None 
o fm_nmmap
    type: string
    default value: None 
o fm_tool
    type: enumerated(formality|lec)
    default value: None
```

## xist_bit2burstsvf

(无 help 条目)

## xist_bit2svf

(无 help 条目)

## xpn.read

```
[Syntax]
   xpn.read  <filename> [-incr] [-no_openup] [-strict] [-tolib <tolib_value>]
[Arguments]
o filename
    type: string
    default value: None 
o incr
    type: switch
    default value: None 
o no_openup
    type: switch
    default value: None 
o strict
    type: switch
    default value: None 
o tolib
    type: object_reference
    default value: None
```

## xpn.write

```
[Syntax]
   xpn.write  <filename>
[Arguments]
o filename
    type: string
    default value: None
```

## xsdc.get_regs

```
[Syntax]
   xsdc.get_regs  [<patterns>] [-hierarchical] [-hsc <hsc_value>] [-nocase] [-of_objects <of_objects_value>] [-regexp]
[Arguments]
o patterns
    type: string
    default value: None 
o hierarchical
    type: switch
    default value: None 
o hsc
    type: string
    default value: None 
o nocase
    type: switch
    default value: None 
o of_objects
    type: string
    default value: None 
o regexp
    type: switch
    default value: None
```

## xstRtlSysExec

(无 help 条目)

## yield

(无 help 条目)

## yieldto

(无 help 条目)

## zlib

(无 help 条目)
