set root_dir [pwd]
set project_dir vivado_project

file mkdir $project_dir

create_project mini-riscv-fp $project_dir -part xc7z010clg400-1
set_property board_part digilentinc.com:zybo:part0:2.0 [current_project]

# add_files -norecurse hdl/util_pkg.vhd
# add_files -norecurse hdl/txt_util.vhd

update_compile_order -fileset sources_1

update_compile_order -fileset sources_1
set_property target_language Verilog [current_project]
# update_compile_order -fileset sim_1

