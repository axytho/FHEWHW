
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


`include "defines.v"


module AddToACAP(
               input                           clk,
               input                           reset,
               input                           initialize,
               input                           load_b,
               input                           start,
               input                           start_intt,
               input [(`DATA_SIZE_ARB * 2 * `PE_NUMBER)-1:0] data_in,
               input [(`DATA_SIZE_ARB * 4 * 2 *`PE_NUMBER)-1:0] key_in,
               output reg                      done,
               output reg                      done_initialization,
               output reg [(`DATA_SIZE_ARB * 2*`PE_NUMBER)-1:0] data_out//### WE SAVE SPACE AND ONLY OUTPUT 1 thing at a time? I think this makes sense
               // ###output reg [`DATA_SIZE_ARB-1:0] dout
               );
               
 reg [`RING_DEPTH+3:0] sys_cntr;
 reg [2:0] state;
 
 reg [`DATA_SIZE_ARB-1:0] params    [0:7];
 reg [`DATA_SIZE_ARB-1:0] w            [0:((((1<<(`RING_DEPTH-`PE_DEPTH))-1)+`PE_DEPTH)<<`PE_DEPTH)-1];
 reg [`DATA_SIZE_ARB-1:0] winv       [0:((((1<<(`RING_DEPTH-`PE_DEPTH))-1)+`PE_DEPTH)<<`PE_DEPTH)-1];
 

 reg                       load_w;
 reg                       load_data;

reg  [(`DATA_SIZE_ARB * 2*`PE_NUMBER)-1:0] bramIn;
reg  [`DATA_SIZE_ARB-1:0] din;
wire [(`DATA_SIZE_ARB * 2*`PE_NUMBER)-1:0] bramOut;
 
 
 initial begin
 $readmemh("D:/Jonas/Documents/Huiswerk/KULeuven5/VerilogThesis/edt_zcu102/edt_zcu102.srcs/sources_1/imports/VerilogThesis/test/PARAM.txt"    , params);
 $readmemh("D:/Jonas/Documents/Huiswerk/KULeuven5/VerilogThesis/edt_zcu102/edt_zcu102.srcs/sources_1/imports/VerilogThesis/test/W.txt"        , w);
 $readmemh("D:/Jonas/Documents/Huiswerk/KULeuven5/VerilogThesis/edt_zcu102/edt_zcu102.srcs/sources_1/imports/VerilogThesis/test/WINV.txt"     , winv);
end

 always @(posedge clk or posedge reset) begin
                   if(reset) begin
                       state <= 3'd0;
                       sys_cntr <= 0;
                   end
                   else begin
                       case(state)
                       3'd0: begin
                           if(initialize)//load all parameters in all things
                               state <= 3'd1;
                           else if(start) 
                               state <= 3'd2;//load data into intt (either from the input or from the ntt brams

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
                       3'd2: begin //(only run at the start, afterwards the bit reversing must be done while writing away.) --> WRONG
                       // actually bit reversing should be done while writing into the bram anyway, so just do it properly 
                       // by having one 16 cycle writeaway that bitreverses as we go
                           if(sys_cntr == (`RING_SIZE-1)) begin //because it takes 1024 cycles, so we really don't want to do this every time
                               state <= 3'd0;
                               sys_cntr <= 0;
                           end
                           else begin
                               state <= 3'd2;
                               sys_cntr <= sys_cntr + 1;
                           end
                       end
                       
                       3'd3: begin //run the inntt
                       
                       
                       end
                       3'd4: begin// wait for innt to finish going through the signed bit decompose and writing to ntt
                           if(sys_cntr == ((`RING_SIZE >> (`PE_DEPTH+1)) + `STAGE_DELAY)) begin
                               state <= 3'd5;
                               sys_cntr <= 0;
                           end
                           else begin
                               state <= 3'd4;
                               sys_cntr <= sys_cntr + 1;
                           end
                       end
                       3'd5: begin//run the ntt
                           
                       end
                       
                       3'd6: begin//manipulate the ntt's to do secret key multiplication for you
                           if((sys_cntr == ((`RING_SIZE >> (`PE_DEPTH+1)) + `STAGE_DELAY)) && (start)) begin
                              state <= 3'd1;//we keep going until some bigger timer , output done too to help bigger counter understand we've
                              sys_cntr <= 0;// finished one loop
                          end 
                          else begin
                             state <= 3'd6;
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


always @(posedge clk or posedge reset) begin: LOAD_W
    if (reset) begin
        load_w <=0;
    end
    else if (state == 3'd1)begin
        load_w <= (sys_cntr==0);
        
    
    end


end
 
 
               
// ### important: we can (and should) initialize or weights from an external file https://studfile.net/preview/4643996/page:29/ instead of loading it in
// ### actually no, that's a terrible idea


// ---------------------------------------------------------------- UUT

INTT uut    (clk,reset,
             load_w,
             load_data,
             start,
             start_intt,
             din,
             bramIn,
             done,
             bramOut);



endmodule
