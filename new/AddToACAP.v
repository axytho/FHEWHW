`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 04/10/2021 12:12:50 PM
// Design Name: 
// Module Name: AddToACAP
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


module AddToACAP(
                input                           clk,reset,
               input                           load_w,
               input                           load_b,
               input                           start,
               input                           start_intt,
               input [`DATA_SIZE_ARB-1:0]      din,
               output reg                      done,
               output reg [`DATA_SIZE_ARB-1:0] dout//### WE SAVE SPACE AND ONLY OUTPUT 1 thing at a time? I think this makes sense
               // ###output reg [`DATA_SIZE_ARB-1:0] dout
               );
               
 reg [`RING_DEPTH+3:0] sys_cntr;
 reg [2:0] state;

 always @(posedge clk or posedge reset) begin
                   if(reset) begin
                       state <= 3'd0;
                       sys_cntr <= 0;
                   end
                   else begin
                       case(state)
                       3'd0: begin
                           if(load_w)
                               state <= 3'd1;
                           else if(load_b)
                               state <= 3'd2;
                           else if(start | start_intt)
                               state <= 3'd3;
                           else
                               state <= 3'd0;
                           sys_cntr <= 0;
                       end
                       3'd1: begin //should be done only once in our entire NTT
                           if(sys_cntr == ((((((1<<(`RING_DEPTH-`PE_DEPTH))-1)+`PE_DEPTH)<<`PE_DEPTH)<<1)+2-1)) begin
                               state <= 3'd0;
                               sys_cntr <= 0;
                           end
                           else begin
                               state <= 3'd1;
                               sys_cntr <= sys_cntr + 1;
                           end
                       end
                       3'd2: begin //only run at the start, afterwards the bit reversing must be done while writing away.
                           if(sys_cntr == (`RING_SIZE-1)) begin //because it takes 1024 cycles, so we really don't want to do this every time
                               state <= 3'd0;
                               sys_cntr <= 0;
                           end
                           else begin
                               state <= 3'd2;
                               sys_cntr <= sys_cntr + 1;
                           end
                       end

                       3'd4: begin
                           if(sys_cntr == ((`RING_SIZE >> (`PE_DEPTH+1)) + `STAGE_DELAY)) begin
                               state <= 3'd0;
                               sys_cntr <= 0;
                           end
                           else begin
                               state <= 3'd4;
                               sys_cntr <= sys_cntr + 1;
                           end
                       end
                       3'd5: begin
                           if(sys_cntr == (((`RING_SIZE >> (`PE_DEPTH+1))<<1) + `INTMUL_DELAY+`MODRED_DELAY+`STAGE_DELAY)) begin
                               state <= 3'd4;
                               sys_cntr <= 0;
                           end
                           else begin
                               state <= 3'd5;
                               sys_cntr <= sys_cntr + 1;
                           end
                       end
                       default: begin
                           state <= 3'd0;
                           sys_cntr <= 0;
                       end
                       endcase
                   end
               end

 
 
               
// ### important: we can (and should) initialize or weights from an external file https://studfile.net/preview/4643996/page:29/ instead of loading it in

// ---------------------------------------------------------------- UUT

NTTN uut    (clk,reset,
             load_w,
             load_data,
             start,
             start_intt,
             din,
             done,
             bramOut);



endmodule
