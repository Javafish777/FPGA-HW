# Create the HW2 project for EGO-XZ7 V1.2 / XC7Z020-CLG484-1.
set script_dir [file dirname [file normalize [info script]]]
set hw2_dir [file normalize [file join $script_dir ..]]
set project_dir [file normalize [file join $hw2_dir build HW2_EGO_XZ7]]

create_project HW2_EGO_XZ7 $project_dir -part xc7z020clg484-1 -force
set_property target_language VHDL [current_project]
add_files [file join $hw2_dir src HW2.vhd]
add_files -fileset sim_1 [file join $hw2_dir sim HW2_tb.vhd]
add_files -fileset constrs_1 [file join $hw2_dir constraints HW2.xdc]
set_property top HW2 [current_fileset]
set_property top HW2_tb [get_filesets sim_1]
update_compile_order -fileset sources_1
update_compile_order -fileset sim_1
puts "HW2 project created at: $project_dir"
