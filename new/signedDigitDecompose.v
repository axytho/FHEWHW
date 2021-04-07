`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 04/02/2021 10:24:28 PM
// Design Name: 
// Module Name: signedDigitDecompose
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

module signedDigitDecompose(
    //input clk
    input [`DATA_SIZE_ARB-1:0]  value_in,
    output [`DATA_SIZE_ARB-1:0] firstResult,
    output [`DATA_SIZE_ARB-1:0] secondResult,
    output [`DATA_SIZE_ARB-1:0] thirdResult,
    output [`DATA_SIZE_ARB-1:0] fourthResult
    );
    
wire [6:0] firstSeven;
wire [6:0] secondSeven;
wire [6:0] thirdSeven;
wire [6:0] fourthSeven;

wire [`DATA_SIZE_ARB-1:0] tMinusQ;
assign tMinusQ = value_in - `MODULUS;
wire tSelect;
wire [`DATA_SIZE_ARB:0] tSelectValue;
wire [`DATA_SIZE_ARB:0] value_in_decision;
assign tSelectValue = {1'b0, value_in} - `MODULUSHALF;
assign tSelect = tSelectValue[`DATA_SIZE_ARB];

wire [`DATA_SIZE_ARB-1:0] d;
assign d = (tSelect) ? value_in : tMinusQ;

assign firstSeven = d[6:0];
wire [6:0] firstSelectValue;
wire firstSelect;
assign firstSelectValue = firstSeven - 7'd64;
assign firstSelect = firstSelectValue[6];
wire [`DATA_SIZE_ARB-1:0] rFirstMinusBasePlusModulus;
assign rFirstMinusBasePlusModulus = firstSeven + (`MODULUS - 8'd128);
assign firstResult = firstSelect ? firstSeven : rFirstMinusBasePlusModulus; // ARB ? 1:0
wire [`DATA_SIZE_ARB-1-7:0] rNext3 = d[`DATA_SIZE_ARB-1:7] + {1'b0, ~firstSelect};

assign secondSeven = rNext3[6:0];
wire [6:0] secondSelectValue;
wire secondSelect;
assign secondSelectValue = secondSeven - 7'd64;
assign secondSelect = secondSelectValue[6];
wire [`DATA_SIZE_ARB-1:0] rSecondMinusBasePlusModulus = secondSeven + (`MODULUS - 8'd128);
assign secondResult = secondSelect ? secondSeven : rSecondMinusBasePlusModulus;
wire [`DATA_SIZE_ARB-1-14:0] rNext2 = rNext3[`DATA_SIZE_ARB-1-7:7] + {1'b0, ~secondSelect};

assign thirdSeven = rNext2[6:0];
wire [6:0] thirdSelectValue;
wire thirdSelect;
assign thirdSelectValue = thirdSeven - 7'd64;
assign thirdSelect = thirdSelectValue[6];
wire [`DATA_SIZE_ARB-1:0] rThirdMinusBasePlusModulus = thirdSeven + (`MODULUS - 8'd128);
assign thirdResult = thirdSelect ? thirdSeven : rThirdMinusBasePlusModulus;
wire [`DATA_SIZE_ARB-1-21:0] rNext1 = rNext2[`DATA_SIZE_ARB-1-14:7] + {1'b0,~thirdSelect};

//YOU NEED A FOURTH BECAUSE d CAN BE NEGATIVE AND THEREFORE HIGHER THAN MODULUS
assign fourthSeven = {rNext1[5], rNext1[5:0]}; //signed bit logic
wire [6:0] fourthSelectValue;
wire fourthSelect;
assign fourthSelectValue = fourthSeven - 7'd64;
assign fourthSelect = fourthSelectValue[6];
wire [`DATA_SIZE_ARB-1:0] rFourthMinusBasePlusModulus = fourthSeven + (`MODULUS - 8'd128);
assign fourthResult = fourthSelect ? fourthSeven : rFourthMinusBasePlusModulus;










endmodule
