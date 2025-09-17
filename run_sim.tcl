#!/usr/bin/env tclsh

# run_sim.tcl
# - Opens existing Vivado project if present, otherwise sources create_project.tcl to create it.
# - Ensures sim_1 fileset has the testbench and hex.
# - Launches simulation and shows waveforms.

proc info_msg {msg} { puts "[clock format [clock seconds] -format {%H:%M:%S}] $msg" }

set script_dir [file normalize [file dirname [info script]]]
cd $script_dir

set proj_name "mini-riscv-fp"
set proj_dir  "vivado_project"
set xpr_path  [file join $proj_dir "$proj_name.xpr"]

# Open existing project, or create it using create_project.tcl
if {[llength [get_projects -quiet]] == 0} {
  if {[file exists $xpr_path]} {
    info_msg "Opening existing project: $xpr_path"
    open_project $xpr_path
  } else {
    info_msg "Project not found. Creating via create_project.tcl"
    source [file join $script_dir create_project.tcl]
  }
} else {
  info_msg "Project already open: [current_project]"
}

# Ensure simulation fileset and testbench are set up
set simset_name sim_1
if {[llength [get_filesets -quiet $simset_name]] == 0} {
  create_fileset -simset $simset_name
}
set simfs [get_filesets $simset_name]

set tb_file  [file join $script_dir tb tb_minirv_fmul.v]
set hex_file [file join $script_dir tb prog.hex]

if {![llength [get_files -quiet -of_objects $simfs $tb_file]]} {
  if {[file exists $tb_file]} {
    info_msg "Adding testbench to sim set: $tb_file"
    add_files -fileset $simfs -norecurse $tb_file
  } else {
    error "Testbench file not found: $tb_file"
  }
}

if {[file exists $hex_file] && ![llength [get_files -quiet -of_objects $simfs $hex_file]]} {
  info_msg "Adding program hex to sim set: $hex_file"
  add_files -fileset $simfs -norecurse $hex_file
}

# Do not use TB/hex in synthesis/implementation
catch { set_property used_in_synthesis false       [get_files -quiet -of_objects $simfs $tb_file] }
catch { set_property used_in_implementation false  [get_files -quiet -of_objects $simfs $tb_file] }
catch { set_property used_in_synthesis false       [get_files -quiet -of_objects $simfs $hex_file] }
catch { set_property used_in_implementation false  [get_files -quiet -of_objects $simfs $hex_file] }

# Set simulation top if not already set
if {[string length [get_property top $simfs]] == 0} {
  info_msg "Setting simulation top: tb_minirv_fmul"
  set_property top tb_minirv_fmul $simfs
}

update_compile_order -fileset $simfs

# Start GUI if not already in GUI mode (so waveforms are visible)
catch { start_gui }

info_msg "Launching simulation..."
launch_simulation -simset $simfs

# Prepare wave window and logging
set wdb_path ""
catch { set wdb_path [get_property WDB_FILE [current_simulation]] }
if {[string length $wdb_path] > 0} {
  catch { open_wave_database $wdb_path }
}

# Try to open existing wave configuration (if present)
file mkdir [file join $script_dir sim]
set wcfg_path [file join $script_dir sim wave.wcfg]
if {[file exists $wcfg_path]} {
  info_msg "Opening wave config: $wcfg_path"
  catch { open_wave_config $wcfg_path }
}

# Clear any stale signals and add everything recursively
catch { delete_wave -all }
if {[catch { log_wave -r /* }]} {
  info_msg "log_wave not available (already logging or non-GUI)."
}
if {[catch { add_wave -recursive /* }]} {
  info_msg "add_wave not available in this mode; proceeding."
}

# Color key FP signals already present in the wave
proc color_and_style {sig} {
  set done 0
  if {[llength [info commands get_waves]]} {
    set w [get_waves -quiet $sig]
    if {[llength $w]} {
      catch { set_property color pink $w }
      catch { set_property radix hex $w }
      set done 1
    }
  }
  if {!$done && [llength [info commands get_wave_objects]]} {
    set w [get_wave_objects -quiet $sig]
    if {[llength $w]} {
      catch { set_property color pink $w }
      catch { set_property radix hex $w }
      set done 1
    }
  }
  if {!$done} {
    # If not in the wave yet, add it with color
    if {[catch { add_wave -color pink -radix hex $sig }]} {
      catch { add_wave -color magenta -radix hex $sig }
    }
  }
}

color_and_style /tb_minirv_fmul/dut/u_core/fmul_A
color_and_style /tb_minirv_fmul/dut/u_core/fmul_B
color_and_style /tb_minirv_fmul/dut/u_core/fmul_out
color_and_style /tb_minirv_fmul/dut/dmem_wdata

# Ensure we start from time 0 if a prior run already completed
catch { restart }

# Run the testbench; it should call $finish when done. Otherwise, adjust the time.
run all

# Save wave configuration for later reuse
catch { save_wave_config $wcfg_path }
info_msg "Wave configuration saved (if supported) to: $wcfg_path"

info_msg "Simulation complete. Waveform window should be visible in GUI."
