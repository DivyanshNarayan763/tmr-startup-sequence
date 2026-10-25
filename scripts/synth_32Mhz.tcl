read_libs /home/install/FOUNDRY/digital/90nm/dig/lib/slow.lib
read_hdl {
2FF_synchronizer.v
edge_detector.v
start_synced.v
modes_FSM_clocked.v
RTDS_clocked.v
flasher_synced.v
top_module.v
}
elaborate startup_controller
check_design -unresolved
read_sdc vcu_32mhz.sdc
check_timing_intent
set_db syn_generic_effort medium
set_db syn_map_effort medium
set_db syn_opt_effort medium
set_db auto_ungroup none
syn_generic
syn_map
syn_opt
ungroup -all -flatten
report_area > area_32mhz.rpt
report_gates > gates_32mhz.rpt
report_timing > timing_32mhz.rpt
report_qor > qor_32mhz.rpt
report_power > power_32mhz.rpt
write_hdl > startup_controller_mapped.v
write_sdc > startup_controller_mapped.sdc
