`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 05/02/2021 02:23:44 PM
// Design Name: 
// Module Name: testAdder
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
module testAdder(

    );
    reg [`DATA_SIZE_ARB-1:0] params    [0:7];
        initial begin
            // params
            $readmemh("D:/Jonas/Documents/Huiswerk/KULeuven5/VerilogThesis/edt_zcu102/edt_zcu102.srcs/sources_1/imports/VerilogThesis/test/PARAM.txt"    , params);
        end
    
reg clk;
parameter HP = 5;
always #HP clk = ~clk;

reg [`DATA_SIZE_ARB-1:0] value1;
reg [`DATA_SIZE_ARB-1:0] value2;
reg [`DATA_SIZE_ARB-1:0] value3;
reg [`DATA_SIZE_ARB-1:0] value4;
wire [`DATA_SIZE_ARB*`NTT_NUMBER-1:0] inputValue;
wire [`DATA_SIZE_ARB-1:0] result;

assign inputValue = {value4, value3, value2, value1};

initial begin: PROCESS
integer m;
integer en,ei;
	// clk & reset (150 cc)
	clk       = 0;
	#20;



//    if(first_Result == 27'h7fff7f8 && second_Result == 27'h2e && third_Result == 27'h7fff7ce && fourth_Result == 27'h7fff7f0) begin
//        $display("Success!");
//     end
//     else begin
//         $display("Hello: %d %d %d %d",first_Result, second_Result, third_Result, fourth_Result);
//     end
    

    value1 = params[1] - 1;
    value2 = params[1] +6 ;
    value3 = 3;
    value4 = 4;
    #300
    if((value1+value2+value3+value4-2*params[1]) == result) begin
        $display("sucess!");
    end
    else begin
        $display(" Calculated:%d, Expected:%d",  (value1+value2+value3+value4),result);
    end


	$stop();
end
resultAdder addition (inputValue, result);
endmodule
