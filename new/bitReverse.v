`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 04/11/2021 08:36:30 PM
// Design Name: 
// Module Name: bitReverse
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

module bitReverse(
input clk, reset,
input[3:0] cycle,
input [`DATA_SIZE_ARB*`PE_NUMBER-1:0] data_in, //data comes in in 32 bit chunks
output reg [`PE_NUMBER*`PE_NUMBER-1:0] data_out

    );
reg [`PE_NUMBER*`PE_NUMBER-1:0] data_out_reg;
//reg [3:0] cycleDelay;
always @(posedge clk or posedge reset) begin
    if (reset) begin
        data_out <= 0;
    end
    else begin
        data_out <= data_out_reg;
    end
end



reg [`DATA_SIZE_ARB-1:0] data_in_array [`PE_NUMBER-1:0];
reg [`DATA_SIZE_ARB-1:0] data_indices [31:0];
always @(*) begin: DATA_IN_ARRAY
    integer k;
    for(k=0; k < (`PE_NUMBER); k=k+1) begin: LOOP_1 
        if (reset) begin
            data_in_array[k] = 0;
        end
        else begin
            data_in_array[k] = data_in[(`DATA_SIZE_ARB*k)+:`DATA_SIZE_ARB];
       end
    end
end

always @(posedge clk) begin: BITREVERSE_BLOCK
    integer n;
    for(n=0; n < (`PE_NUMBER); n=n+1) begin: LOOP_1 
        if (reset) begin
            data_out_reg[(`DATA_SIZE_ARB*n)+:`DATA_SIZE_ARB] <= 0;
        end
        else begin 
            //data_out[(`DATA_SIZE_ARB*( (((n[4:1]+cycleDelay) & 4'b1000) >> 3) +((n[4:1]+cycleDelay) & 4'b100) >> 1)+  ((n[4:1]+cycleDelay) & 4'b100) << 1)+ ((n[4:1]+cycleDelay) & 4'b100) << 3)))+:`DATA_SIZE_ARB] = data_in_array[n];
             //k = ((((((n[4:1]+cycleDelay) & 4'b1000) >> 3) +(((n[4:1]+cycleDelay) & 4'b100) >> 1)+  (((n[4:1]+cycleDelay) & 4'b10) << 1)+ (((n[4:1]+cycleDelay) & 4'b1) << 3)) << 1) + n[0]);
             //data_indices[n] <= ((((((n[4:1]+cycle[3:0]) & 4'b1000) >> 3) +(((n[4:1]+cycle) & 4'b100) >> 1)+  (((n[4:1]+cycle) & 4'b10) << 1)+ (((n[4:1]+cycle) & 4'b1) << 3)) << 1) + n[0]);
             data_out_reg[(`PE_NUMBER*(((((n[3:0]+cycle) & 4'b1000) >> 3) +(((n[3:0]+cycle) & 4'b100) >> 1)+  (((n[3:0]+cycle) & 4'b10) << 1)+ (((n[3:0]+cycle) & 4'b1) << 3)) + (n[4]  << 4)))+:`PE_NUMBER] <= {1'b0,n[0], n[1], n[2], n[3],data_in_array[n]};
        end
    end
end
//wire [3:0] subtraction;

 
   



//for tomorrow: use genvar!!!
/*
always @(posedge clk or posedge reset) begin: B_BLOCK    
   integer n;
integer k2TO5;
for(n=0; n < (`PE_NUMBER); n=n+1) begin: LOOP_1 
     k2TO5 = {n[2], n[3], n[4], n[5]};
        case ({n[1],(k2TO5+(5'b10000-cycle[3:0])) & ((`PE_DEPTH >> 1) - 1)})
            //"5'd{0}: data_out[`DATA_SIZE_ARB*(n+1)-1:`DATA_SIZE_ARB*n] = inputReg[`DATA_SIZE_ARB*({0+1)-1:`DATA_SIZE_ARB*{0}];"
            5'd0: data_out[(`DATA_SIZE_ARB*n)+:`DATA_SIZE_ARB] = inputReg[(`DATA_SIZE_ARB*0)+:`DATA_SIZE_ARB];
            5'd1: data_out[(`DATA_SIZE_ARB*n)+:`DATA_SIZE_ARB] = inputReg[(`DATA_SIZE_ARB*1)+:`DATA_SIZE_ARB];
            5'd2: data_out[(`DATA_SIZE_ARB*n)+:`DATA_SIZE_ARB] = inputReg[(`DATA_SIZE_ARB*2)+:`DATA_SIZE_ARB];
            5'd3: data_out[(`DATA_SIZE_ARB*n)+:`DATA_SIZE_ARB] = inputReg[(`DATA_SIZE_ARB*3)+:`DATA_SIZE_ARB];
            5'd4: data_out[(`DATA_SIZE_ARB*n)+:`DATA_SIZE_ARB] = inputReg[(`DATA_SIZE_ARB*4)+:`DATA_SIZE_ARB];
            5'd5: data_out[(`DATA_SIZE_ARB*n)+:`DATA_SIZE_ARB] = inputReg[(`DATA_SIZE_ARB*5)+:`DATA_SIZE_ARB];
            5'd6: data_out[(`DATA_SIZE_ARB*n)+:`DATA_SIZE_ARB] = inputReg[(`DATA_SIZE_ARB*6)+:`DATA_SIZE_ARB];
            5'd7: data_out[(`DATA_SIZE_ARB*n)+:`DATA_SIZE_ARB] = inputReg[(`DATA_SIZE_ARB*7)+:`DATA_SIZE_ARB];
            5'd8: data_out[(`DATA_SIZE_ARB*n)+:`DATA_SIZE_ARB] = inputReg[(`DATA_SIZE_ARB*8)+:`DATA_SIZE_ARB];
            5'd9: data_out[(`DATA_SIZE_ARB*n)+:`DATA_SIZE_ARB] = inputReg[(`DATA_SIZE_ARB*9)+:`DATA_SIZE_ARB];
            5'd10: data_out[(`DATA_SIZE_ARB*n)+:`DATA_SIZE_ARB] = inputReg[(`DATA_SIZE_ARB*10)+:`DATA_SIZE_ARB];
            5'd11: data_out[(`DATA_SIZE_ARB*n)+:`DATA_SIZE_ARB] = inputReg[(`DATA_SIZE_ARB*11)+:`DATA_SIZE_ARB];
            5'd12: data_out[(`DATA_SIZE_ARB*n)+:`DATA_SIZE_ARB] = inputReg[(`DATA_SIZE_ARB*12)+:`DATA_SIZE_ARB];
            5'd13: data_out[(`DATA_SIZE_ARB*n)+:`DATA_SIZE_ARB] = inputReg[(`DATA_SIZE_ARB*13)+:`DATA_SIZE_ARB];
            5'd14: data_out[(`DATA_SIZE_ARB*n)+:`DATA_SIZE_ARB] = inputReg[(`DATA_SIZE_ARB*14)+:`DATA_SIZE_ARB];
            5'd15: data_out[(`DATA_SIZE_ARB*n)+:`DATA_SIZE_ARB] = inputReg[(`DATA_SIZE_ARB*15)+:`DATA_SIZE_ARB];
            5'd16: data_out[(`DATA_SIZE_ARB*n)+:`DATA_SIZE_ARB] = inputReg[(`DATA_SIZE_ARB*16)+:`DATA_SIZE_ARB];
            5'd17: data_out[(`DATA_SIZE_ARB*n)+:`DATA_SIZE_ARB] = inputReg[(`DATA_SIZE_ARB*17)+:`DATA_SIZE_ARB];
            5'd18: data_out[(`DATA_SIZE_ARB*n)+:`DATA_SIZE_ARB] = inputReg[(`DATA_SIZE_ARB*18)+:`DATA_SIZE_ARB];
            5'd19: data_out[(`DATA_SIZE_ARB*n)+:`DATA_SIZE_ARB] = inputReg[(`DATA_SIZE_ARB*19)+:`DATA_SIZE_ARB];
            5'd20: data_out[(`DATA_SIZE_ARB*n)+:`DATA_SIZE_ARB] = inputReg[(`DATA_SIZE_ARB*20)+:`DATA_SIZE_ARB];
            5'd21: data_out[(`DATA_SIZE_ARB*n)+:`DATA_SIZE_ARB] = inputReg[(`DATA_SIZE_ARB*21)+:`DATA_SIZE_ARB];
            5'd22: data_out[(`DATA_SIZE_ARB*n)+:`DATA_SIZE_ARB] = inputReg[(`DATA_SIZE_ARB*22)+:`DATA_SIZE_ARB];
            5'd23: data_out[(`DATA_SIZE_ARB*n)+:`DATA_SIZE_ARB] = inputReg[(`DATA_SIZE_ARB*23)+:`DATA_SIZE_ARB];
            5'd24: data_out[(`DATA_SIZE_ARB*n)+:`DATA_SIZE_ARB] = inputReg[(`DATA_SIZE_ARB*24)+:`DATA_SIZE_ARB];
            5'd25: data_out[(`DATA_SIZE_ARB*n)+:`DATA_SIZE_ARB] = inputReg[(`DATA_SIZE_ARB*25)+:`DATA_SIZE_ARB];
            5'd26: data_out[(`DATA_SIZE_ARB*n)+:`DATA_SIZE_ARB] = inputReg[(`DATA_SIZE_ARB*26)+:`DATA_SIZE_ARB];
            5'd27: data_out[(`DATA_SIZE_ARB*n)+:`DATA_SIZE_ARB] = inputReg[(`DATA_SIZE_ARB*27)+:`DATA_SIZE_ARB];
            5'd28: data_out[(`DATA_SIZE_ARB*n)+:`DATA_SIZE_ARB] = inputReg[(`DATA_SIZE_ARB*28)+:`DATA_SIZE_ARB];
            5'd29: data_out[(`DATA_SIZE_ARB*n)+:`DATA_SIZE_ARB] = inputReg[(`DATA_SIZE_ARB*29)+:`DATA_SIZE_ARB];
            5'd30: data_out[(`DATA_SIZE_ARB*n)+:`DATA_SIZE_ARB] = inputReg[(`DATA_SIZE_ARB*30)+:`DATA_SIZE_ARB];
            5'd31: data_out[(`DATA_SIZE_ARB*n)+:`DATA_SIZE_ARB] = inputReg[(`DATA_SIZE_ARB*31)+:`DATA_SIZE_ARB]; 
          endcase 
        
        
        
        
        
        
        
        
        
        
   end
end
*/
endmodule
