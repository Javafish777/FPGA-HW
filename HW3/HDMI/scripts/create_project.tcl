# Create the HW3 HDMI project for EGO-XZ7 V1.2 / XC7Z020-CLG484-1.
set script_dir [file dirname [file normalize [info script]]]
set hdmi_dir [file normalize [file join $script_dir ..]]
set project_dir [file normalize [file join $hdmi_dir build HW3_HDMI_EGO_XZ7]]

create_project HW3_HDMI_EGO_XZ7 $project_dir -part xc7z020clg484-1 -force
set_property target_language VHDL [current_project]
add_files [file join $hdmi_dir src ADV7511_INIT.vhd]
add_files [file join $hdmi_dir src HW3_HDMI_TOP.vhd]
add_files -fileset constrs_1 [file join $hdmi_dir constraints EGO_XZ7_HDMI.xdc]
add_files -fileset sim_1 [file join $hdmi_dir sim HW3_HDMI_TOP_tb.vhd]
set_property top HW3_HDMI_TOP [current_fileset]
set_property top HW3_HDMI_TOP_tb [get_filesets sim_1]
update_compile_order -fileset sources_1
update_compile_order -fileset sim_1
puts "HW3 HDMI project created at: $project_dir"
