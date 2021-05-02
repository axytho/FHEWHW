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

module resultAdder(
    input [`NTT_NUMBER*`DATA_SIZE_ARB-1:0]  value_in,
    output [`DATA_SIZE_ARB-1:0] result
    );
    
    reg [`DATA_SIZE_ARB-1:0] params    [0:7];
        initial begin
            // params
            $readmemh("D:/Jonas/Documents/Huiswerk/KULeuven5/VerilogThesis/edt_zcu102/edt_zcu102.srcs/sources_1/imports/VerilogThesis/test/PARAM.txt"    , params);
        end
    
    //one adder unit
    wire [`DATA_SIZE_ARB:0] modular_add [(`NTT_NUMBER)-2:0];
    wire [`DATA_SIZE_ARB+1:0] modular_add_minus_q [(`NTT_NUMBER)-2:0];
    wire [`DATA_SIZE_ARB-1:0] modular_add_res [(`NTT_NUMBER<<1)-2:0];
    genvar k;
    generate
    for (k=0; (k<`NTT_NUMBER); k= k+1) begin
        assign modular_add_res[k] = value_in[(`DATA_SIZE_ARB*k)+:`DATA_SIZE_ARB];
    end
    endgenerate
    
    genvar i;
    genvar n;
    genvar index;
    generate
    // the idea is that the index = +(`NTT_NUMBER << 1) - (`NTT_NUMBER>>i)
    // so effectively we start at 4 and then go to 6
    for (i=0; i<`NTT_NUMBER; i= i+1) begin
        for (n=0; (n<(`NTT_NUMBER>>(1+i))); n= n+1) begin
            assign modular_add[n+(`NTT_NUMBER) - (`NTT_NUMBER>>(i))] = modular_add_res[2*n+(`NTT_NUMBER << 1) - (`NTT_NUMBER<<1 >>i)]
             + modular_add_res[2*n+1+(`NTT_NUMBER << 1) - (`NTT_NUMBER<<1>>i)]; 
            assign modular_add_minus_q[n+(`NTT_NUMBER) - (`NTT_NUMBER>>i)] = 
            modular_add[n+(`NTT_NUMBER) - (`NTT_NUMBER>>i)]-params[1];
            assign modular_add_res[(`NTT_NUMBER << 1) - (`NTT_NUMBER>>i)+ n] = 
        (modular_add_minus_q[n+(`NTT_NUMBER) - (`NTT_NUMBER>>i)][`DATA_SIZE_ARB+1] == 1'b0)
         ? modular_add_minus_q[n+(`NTT_NUMBER) - (`NTT_NUMBER>>i)][`DATA_SIZE_ARB-1:0] 
         : modular_add[n+(`NTT_NUMBER) - (`NTT_NUMBER>>i)][`DATA_SIZE_ARB-1:0];
        end 
        
    end
    endgenerate

assign result = modular_add_res[(`NTT_NUMBER<<1)-2];



endmodule
