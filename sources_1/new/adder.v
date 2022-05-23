`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 02/27/2021 04:53:42 PM
// Design Name: 
// Module Name: adder
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


module adder(
    input wire clk,
    input wire resetn,
    input wire [31:0] input_adder,
    output wire [31:0] output_adder
    );
    
reg [16:0] sum;
always @(posedge clk)
begin
    if (~resetn)   sum <= 16'b0;
    else sum <= input_adder[31:16] + input_adder[15:0];
end
assign output_adder = {16'b0, sum[15:0]}; 
endmodule
