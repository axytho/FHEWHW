
set topname   [get_property top [current_fileset]]

if { $topname == "INTT_wrapper"} {
create_clock -period 5 -name clk_gen -add [get_ports clk];
set_property PACKAGE_PIN AL8      [get_ports clk];# Bank  64 VCCO - VCC1V2   - IO_L12P_T1U_N10_GC_64
set_property IOSTANDARD  DIFF_SSTL12 [get_ports clk];# Bank  64 VCCO - VCC1V2   - IO_L12P_T1U_N10_GC_64
set_property PACKAGE_PIN AM14     [get_ports reset] ;# Bank  44 VCCO - VCC3V3   - IO_L2P_AD10P_44
set_property IOSTANDARD  LVCMOS33 [get_ports reset] ;# Bank  44 VCCO - VCC3V3   - IO_L2P_AD10P_44
set_property PACKAGE_PIN AJ15     [get_ports done_to_pin] ;# Bank  44 VCCO - VCC3V3   - IO_L8P_HDGC_AD4P_44
set_property IOSTANDARD  LVCMOS33 [get_ports done_to_pin] ;# Bank  44 VCCO - VCC3V3   - IO_L8P_HDGC_AD4P_44
}