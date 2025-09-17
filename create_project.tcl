set root_dir [pwd]
set project_dir vivado_project

file mkdir $project_dir

create_project mini-riscv-fp $project_dir -part xc7z010clg400-1
set_property board_part digilentinc.com:zybo:part0:2.0 [current_project]

add_files -norecurse hdl/rv_dmem.v
add_files -norecurse hdl/rv_imem.v
add_files -norecurse hdl/RVCore_FMUL.v
add_files -norecurse hdl/MultNorm.v
add_files -norecurse hdl/MiniRV_FMUL_Top.v
add_files -norecurse hdl/Mant_Mult.v
add_files -norecurse hdl/FPMul_unit.v
add_files -norecurse hdl/FP_Mul.v


update_compile_order -fileset sources_1

update_compile_order -fileset sources_1
set_property target_language Verilog [current_project]
# update_compile_order -fileset sim_1

