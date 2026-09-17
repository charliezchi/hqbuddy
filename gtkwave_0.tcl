#=====first: load file=====
set file_name_0 C:/Users/XiST/Desktop/Git/hqbuddy/bd8_r21a_0_ww.vcd
gtkwave::loadFile $file_name_0
#=====second: get signals=====nlist
lappend list_0 clock_cycle
lappend list_0 trigger_event
lappend list_0 {r21a_top/u_cnt/cnt[7:0]}
lappend list_0 {r21a_top/u_lfsr/lfsr[7:0]}
lappend list_0 {clk}
#======third: add signals to gtkwave====
#======third: add signals to gtkwave====
foreach str_var $list_0 {
gtkwave::addSignalsFromList $str_var
}

gtkwave::/Edit/UnHighlight_All
gtkwave::/Edit/Highlight_Regexp clock_cycle
gtkwave::/Edit/Data_Format/Signed_Decimal clock_cycle
gtkwave::setMarker 1280

#=====Zoom====
gtkwave::/Time/Zoom/Zoom_Best_Fit

#====offset-8,offset+12====
gtkwave::setZoomRangeTimes 1200 1400
