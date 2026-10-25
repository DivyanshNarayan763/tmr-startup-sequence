# TMR VCU 32 MHz -- preliminary block-level functional constraints.
# Elaborate RTL with CLK_HZ=32000000; this SDC does NOT change timer counts.
# Electrical values and margins below are STARTING ASSUMPTIONS, not PDK specs.
# Check accepted units in Genus/Innovus logs and the loaded Liberty files.
set_units -time ns -capacitance pF
create_clock -name core_clk -period 31.25 -waveform {0 15.625} [get_ports clk]
set_clock_transition 0.200 [get_clocks core_clk]
# Pre-CTS setup margin includes a provisional skew allowance plus jitter.
set_clock_uncertainty -setup 0.300 [get_clocks core_clk]
set_clock_uncertainty -hold 0.100 [get_clocks core_clk]

# Unrelated external inputs: no valid phase relationship to core_clk.
# Zero arrival is a bookkeeping reference; false paths below remove synchronous
# timing at their FIRST capture/control endpoint, not between internal flops.
set async_ports [get_ports {START_BTN MODE_BTN BOOST_BTN T B N IMD rst}]
set_input_delay -clock core_clk -max 0.0 $async_ports
set_input_delay -clock core_clk -min 0.0 $async_ports
set_input_transition 0.500 $async_ports
set_false_path -from $async_ports
# rst/IMD directly drive async controls only. Their external recovery/removal
# is intentionally excluded. Internal release-stage recovery/removal is NOT cut.
# Verify mapped connectivity; preserve and place synchronizer stages together.
# Do not add exceptions from reset_ff, imd_fault_ff, or FF_synch stage outputs.

# Outputs are status/control levels; no MCU sampling clock was supplied.
# Provisional 5 ns internal output-path budget, not an MCU setup/hold guarantee.
# Unlike a false path to all outputs, these bounds keep output logic optimized.
set_max_delay 5.000 -to [all_outputs]
set_min_delay 0.000 -to [all_outputs]
# Assumed block boundary load 0.05 pF (50 fF); replace using pad/receiver models.
# This does NOT represent a buzzer, LED, or full board load driven by core cells.
set_load 0.050 [all_outputs]

# Clock is ideal for synthesis/pre-CTS. Do NOT mark it dont_touch_network.
# After CTS, use propagated clock timing and replace pre-CTS uncertainty with
# measured/spec-derived jitter margins; see post_cts.tcl and README.txt.
