# TMR VCU: initial 32 MHz Innovus physical-design study.
# Legacy Innovus command interface, matching the lab's Innovus 17.x flow.
# Run: innovus -files innovus_32mhz.tcl
# Put this script, the mapped netlist and exported Genus SDC together.
# This is a block-level timing flow, not a tape-out/signoff script.

# ---------- Files ----------
set ROOT [file dirname [file normalize [info script]]]
cd $ROOT
set TOP startup_controller
set PDK /home/install/FOUNDRY/digital/90nm/dig

set NETLIST [file join $ROOT startup_controller_mapped.v]
# Use the export from the SAME 32 MHz Genus run as the netlist.
set SDC [file join $ROOT startup_controller_mapped.sdc]

# LEF pair selected in the lab manual, page 30.
set LEFS [list \
    $PDK/lef/gsclib090_translated.lef \
    $PDK/lef/gsclib090_translated_ref.lef]
set SLOW_LIB $PDK/lib/slow.lib
set FAST_LIB $PDK/lib/fast.lib
set CAP_TABLE $PDK/captable/gpdk090.lef.extended.CapTbl
set QRC_TECH $PDK/qrc/gpdk090_9l.tch

# Names/case follow the manual.
set PWR Vdd
set GND Vss
# Empty: use the sole site defined in the loaded LEFs.
# If multiple sites exist, enter the standard-cell site name here.
set SITE gsclib090site

set RUN [file join $ROOT pd_32mhz]
set RPT [file join $RUN reports]
set DB [file join $RUN checkpoints]
file mkdir $RPT $DB

foreach f [concat [list $NETLIST $SDC $SLOW_LIB $FAST_LIB $CAP_TABLE $QRC_TECH] $LEFS] {
    if {![file isfile $f]} {error "Required input not found: $f"}
}

# ---------- Timing-corner setup ----------
# Generate the MMMC file internally: no separate hand-written .view needed.
# Lab convention: slow/125 C for setup, fast/0 C for hold.
# Both RC views use the lab's supplied extraction files at those temperatures.
set MMMC [file join $RUN mmmc.tcl]
set fp [open $MMMC w]
puts $fp [list create_library_set -name LIB_SLOW -timing [list $SLOW_LIB]]
puts $fp [list create_library_set -name LIB_FAST -timing [list $FAST_LIB]]
puts $fp [list create_rc_corner -name RC_SLOW -cap_table $CAP_TABLE -qx_tech_file $QRC_TECH -T 125]
puts $fp [list create_rc_corner -name RC_FAST -cap_table $CAP_TABLE -qx_tech_file $QRC_TECH -T 0]
puts $fp {create_delay_corner -name DELAY_SLOW -library_set LIB_SLOW -rc_corner RC_SLOW}
puts $fp {create_delay_corner -name DELAY_FAST -library_set LIB_FAST -rc_corner RC_FAST}
puts $fp [list create_constraint_mode -name FUNC -sdc_files [list $SDC]]
puts $fp {create_analysis_view -name SETUP_VIEW -constraint_mode FUNC -delay_corner DELAY_SLOW}
puts $fp {create_analysis_view -name HOLD_VIEW -constraint_mode FUNC -delay_corner DELAY_FAST}
puts $fp {set_analysis_view -setup {SETUP_VIEW} -hold {HOLD_VIEW}}
close $fp

# ---------- Import ----------
set init_verilog $NETLIST
set init_top_cell $TOP
set init_lef_file $LEFS
set init_pwr_net $PWR
set init_gnd_net $GND
set init_mmmc_file $MMMC
init_design
checkDesign -all
# Keep the same OCV/CPPR analysis choice through all implementation stages.
setAnalysisMode -analysisType onChipVariation -cppr both

# ---------- Floorplan ----------
if {$SITE eq ""} {
    set sites [lsort -unique [dbGet head.sites.name]]
    if {[llength $sites] != 1 || $sites eq "0x0"} {
        error "Set SITE to the standard-cell placement site. Available sites: $sites"
    }
    set SITE [lindex $sites 0]
}
# Manual: aspect ratio 1, utilization 0.70, margins 5 um.
floorPlan -site $SITE -r 1.0 0.70 5 5 5 5

# ---------- Power planning ----------
globalNetConnect $PWR -type pgpin -pin $PWR -inst *
globalNetConnect $GND -type pgpin -pin $GND -inst *
set PG [list $PWR $GND]

# Manual: Metal9 horizontal, Metal8 vertical; ring width 1.2, spacing 0.4.
addRing -nets $PG -type core_rings -follow core \
    -layer {top Metal9 bottom Metal9 left Metal8 right Metal8} \
    -width 1.2 -spacing 0.4 -center 1

# Manual: four stripe sets, width 0.6, spacing 0.4.
addStripe -nets $PG -layer Metal9 -direction horizontal \
    -width 0.6 -spacing 0.4 -number_of_sets 4 -start_from bottom
addStripe -nets $PG -layer Metal8 -direction vertical \
    -width 0.6 -spacing 0.4 -number_of_sets 4 -start_from left

# The lab uses FILL1 for its boundary-cell demonstration.
addEndCap -preCap FILL1 -postCap FILL1 -prefix ENDCAP
sroute -nets $PG -connect {corePin} -allowLayerChange 1 -allowJogging 1
saveDesign [file join $DB floorplan.enc]

# ---------- Placement and pre-CTS setup timing ----------
setPlaceMode -placeIoPins true
placeDesign
optDesign -preCTS
timeDesign -preCTS -pathReports -slackReports -numPaths 20 \
    -prefix preCTS_setup -outDir [file join $RPT preCTS]
saveDesign [file join $DB placed.enc]

# ---------- Clock-tree synthesis ----------
# Select available clock buffers from the loaded library.
# Fall back to ordinary non-inverting buffers if no CLKBUF cells exist.
set CTS_BUFFERS [dbGet head.libCells.name CLKBUF*]
if {$CTS_BUFFERS eq "0x0" || [llength $CTS_BUFFERS] == 0} {
    set CTS_BUFFERS [dbGet head.libCells.name BUF*]
}
if {$CTS_BUFFERS eq "0x0" || [llength $CTS_BUFFERS] == 0} {
    error "No buffer cells found for CTS. Set CTS_BUFFERS to actual library buffer names."
}
set_ccopt_property buffer_cells $CTS_BUFFERS
# No -file: generate and apply the clock-tree specification in memory.
create_ccopt_clock_tree_spec
clock_opt_design
set_interactive_constraint_modes [all_constraint_modes -active]
set_propagated_clock [all_clocks]

# Keep imported uncertainty for this initial comparison; it is conservative
# after CTS because the original setup margin includes a skew allowance.
# Do not silently remove uncertainty to improve reported slack.
optDesign -postCTS
optDesign -postCTS -hold
timeDesign -postCTS -pathReports -slackReports -numPaths 20 \
    -prefix postCTS_setup -outDir [file join $RPT postCTS]
timeDesign -postCTS -hold -pathReports -slackReports -numPaths 20 \
    -prefix postCTS_hold -outDir [file join $RPT postCTS]
saveDesign [file join $DB postCTS.enc]

# ---------- Routing and post-route optimization ----------
setNanoRouteMode -routeWithTimingDriven true
setNanoRouteMode -routeWithSiDriven true
routeDesign
optDesign -postRoute
optDesign -postRoute -hold

# Fill remaining row gaps, reconnect power, then extract final routing RC.
addFiller -cell {FILL1} -prefix FILLER
globalNetConnect $PWR -type pgpin -pin $PWR -inst *
globalNetConnect $GND -type pgpin -pin $GND -inst *
sroute -nets $PG -connect {corePin} -allowLayerChange 1 -allowJogging 1
extractRC

# ---------- Final timing reports (WNS/TNS summaries) ----------
timeDesign -postRoute -pathReports -slackReports -numPaths 20 \
    -prefix postRoute_setup -outDir [file join $RPT postRoute]
timeDesign -postRoute -hold -pathReports -slackReports -numPaths 20 \
    -prefix postRoute_hold -outDir [file join $RPT postRoute]

# Save before physical checks, so the routed result is available for inspection.
saveDesign [file join $DB routed.enc]
saveNetlist [file join $RUN startup_controller_routed.v]
verifyGeometry -report [file join $RPT geometry.rpt]
verifyConnectivity -type all -report [file join $RPT connectivity.rpt]

puts "PD flow completed; this does not imply timing or physical checks passed."
puts "Read setup/hold WNS and TNS in the timing summaries under $RPT."
puts "Routed checkpoint: [file join $DB routed.enc]"
# Leave the GUI/session open. No GDS or signoff export is needed for this study.
