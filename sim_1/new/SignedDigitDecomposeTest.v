`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 04/04/2021 09:44:22 AM
// Design Name: 
// Module Name: SignedDigitDecomposeTest
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////
`include "defines.v"

module SignedDigitDecomposeTest();

reg [`DATA_SIZE_ARB-1:0] value_in;
reg [`DATA_SIZE_ARB-1:0] firstResult;
reg [`DATA_SIZE_ARB-1:0] secondResult;
reg [`DATA_SIZE_ARB-1:0] thirdResult;
reg [`DATA_SIZE_ARB-1:0] fourthResult;
wire [`DATA_SIZE_ARB-1:0] first_Result;
wire [`DATA_SIZE_ARB-1:0] second_Result;
wire [`DATA_SIZE_ARB-1:0] third_Result;
wire [`DATA_SIZE_ARB-1:0] fourth_Result;

reg [`DATA_SIZE_ARB-1:0] signed_in   [0:2*`RING_SIZE-1];
reg [`DATA_SIZE_ARB-1:0] signed_out   [0:8*`RING_SIZE-1];


reg clk;
parameter HP = 5;
always #HP clk = ~clk;
always @(posedge clk) begin
firstResult = first_Result;
secondResult = second_Result;
thirdResult = third_Result;
fourthResult = fourth_Result;
end

signedDigitDecompose sdd (
    value_in,
    first_Result,
    second_Result,
    third_Result,
    fourth_Result
);

//reg [`DATA_SIZE_ARB-1:0] signed_in    [0:7];



initial begin
    $readmemh("D:/Jonas/Documents/Huiswerk/KULeuven5/VerilogThesis/edt_zcu102/edt_zcu102.srcs/sources_1/imports/VerilogThesis/test/TESTVECTOR.txt"    , signed_in);
    $readmemh("D:/Jonas/Documents/Huiswerk/KULeuven5/VerilogThesis/edt_zcu102/edt_zcu102.srcs/sources_1/imports/VerilogThesis/test/DCT_IN.txt"    , signed_out);
    
end

initial begin: PROCESS
integer m;
integer en,ei;
	// clk & reset (150 cc)
	en =0;
	clk       = 0;
	#2000;
	for(m=0; m<(2*`RING_SIZE); m=m+1) begin
    value_in = signed_in[m];
    #10//this is our clk

//    if(first_Result == 27'h7fff7f8 && second_Result == 27'h2e && third_Result == 27'h7fff7ce && fourth_Result == 27'h7fff7f0) begin
//        $display("Success!");
//     end
//     else begin
//         $display("Hello: %d %d %d %d",first_Result, second_Result, third_Result, fourth_Result);
//     end
    

    firstResult = first_Result;
    secondResult = second_Result;
    thirdResult = third_Result;
    fourthResult = fourth_Result;
    
    if((firstResult == signed_out[m]) && (secondResult == signed_out[2*`RING_SIZE+m]) && (thirdResult == signed_out[4*`RING_SIZE+m]) &&  (fourthResult == signed_out[6*`RING_SIZE+m])) begin
        en = en+1;
    end
    else begin
        $display("NTT:  Index-%d -- Calculated:%d, Expected:%d",m, fourthResult ,signed_out[6*`RING_SIZE+m]);
    end
    end
    if (en ==`RING_SIZE<<1) begin
        $display("All Correct");
    end
	$stop();
end




endmodule
