
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
               input                           load_input,  //once very 2.5ms = 500 000 CC
               input                           load_a, //for secret key adressing module
               input                           start_addToACAP,
               input [`DATA_SIZE_ARB-1:0] data_in,
               input [(`DATA_SIZE_ARB * 4 * 2 *`PE_NUMBER)-1:0] key_in,
               output reg                      done,
               output reg                      done_initialization,
               output reg [`DATA_SIZE_ARB-1:0] data_out//### WE SAVE SPACE AND ONLY OUTPUT 1 thing at a time? I think this makes sense
               // ###output reg [`DATA_SIZE_ARB-1:0] dout
               );
               
 reg [`RING_DEPTH+3:0] sys_cntr;
 reg [2:0] state;
 
reg                       load_w_ntt [`NTT_NUMBER-1:0];
 reg                       load_w_intt;
 reg                       load_data_ntt [`NTT_NUMBER-1:0];
 reg                       load_data_intt;
 reg                       start;
 reg                       start_intt;
 reg  [`DATA_SIZE_ARB-1:0] din_ntt [`NTT_NUMBER-1:0];
 reg  [`DATA_SIZE_ARB-1:0] din_intt;
 wire [(`DATA_SIZE_ARB * `PE_NUMBER)-1:0] bramIn;
 wire                      done_ntt [`NTT_NUMBER-1:0];
 wire                      done_intt;
 wire [(`DATA_SIZE_ARB *`PE_NUMBER)-1:0] decompose_out [`NTT_NUMBER-1:0];
 wire [(`DATA_SIZE_ARB *`PE_NUMBER)-1:0] bramOut_ntt [`NTT_NUMBER-1:0];
 wire [(`DATA_SIZE_ARB *`PE_NUMBER)-1:0] bramOut_intt;
 wire [(`PE_NUMBER *`PE_NUMBER)-1:0] reverse_out_from_intt;
 wire [(`PE_NUMBER *`PE_NUMBER)-1:0] reverse_out_from_ntt;
  wire [(`DATA_SIZE_ARB *`PE_NUMBER)-1:0] decompose_in;
 wire [(4 *`PE_NUMBER)-1:0] write_addr_ntt;
  wire [(4 *`PE_NUMBER)-1:0] write_addr_intt;
 generate
 genvar r;
 for (r=0; r<`PE_NUMBER; r=r+1) begin
    assign write_addr_ntt[4*r+:4] = reverse_out_from_intt[(`PE_NUMBER *(r+1) - 5)+:4];
    assign decompose_in[(r*`DATA_SIZE_ARB):+`DATA_SIZE_ARB] = reverse_out_from_intt[(r*`DATA_SIZE_ARB):+`DATA_SIZE_ARB];
 end
endgenerate

generate
genvar t;
for (t=0; t<`PE_NUMBER; t=t+1) begin
   assign write_addr_intt[4*t+:4] = reverse_out_from_ntt[(`PE_NUMBER *(t+1) - 5)+:4];
   assign bramIn[(t*`DATA_SIZE_ARB):+`DATA_SIZE_ARB] = reverse_out_from_ntt[(t*`DATA_SIZE_ARB):+`DATA_SIZE_ARB];
end
endgenerate

 always @(posedge clk or posedge reset) begin
                   if(reset) begin
                       state <= 3'd0;
                       sys_cntr <= 0;
                   end
                   else begin
                       case(state)
                       3'd0: begin
                          if(start) begin
                               state <= 3'd1;//load data into intt (either from the input or from the ntt brams
                           end
                           else begin
                               state <= 3'd0;     
                           end
                           sys_cntr <= 0;
                       end

                       3'd1: begin //(only run at the start, afterwards the bit reversing must be done while writing away.) --> WRONG
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
                       
                       3'd2: begin //run the inntt
                       
                       
                       end
                       3'd3: begin// wait for innt to finish going through the signed bit decompose and writing to ntt
                           if(sys_cntr == ((`RING_SIZE >> (`PE_DEPTH+1)) + `STAGE_DELAY)) begin
                               state <= 3'd5;
                               sys_cntr <= 0;
                           end
                           else begin
                               state <= 3'd4;
                               sys_cntr <= sys_cntr + 1;
                           end
                       end
                       3'd4: begin//run the ntt
                           
                       end
                       
                       3'd5: begin//manipulate the ntt's to do secret key multiplication for you
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




 
 
               
// ### important: we can (and should) initialize or weights from an external file https://studfile.net/preview/4643996/page:29/ instead of loading it in
// ### actually no, that's a terrible idea
// ### actually yes, it's a great idea, verilog is just terrible at the implementation of it.


// ---------------------------------------------------------------- UUT

INTT inverse_ntt    (clk,reset,
             load_w_intt,
             load_data_intt,
             start,
             din_intt,
             bramIn,
             done_intt,
             bramOut_intt);
             
bitReverse reverser (
    clk, reset,
    cycle,
    bramOut_intt,
    reverse_out_from_intt
);
             
             
generate
genvar k;
       for (k=0; k<`PE_NUMBER; k=k+1) begin     
            signedDigitDecompose decompose (clk, reset, //TODO: parametrize signedDec
            decompose_in[`DATA_SIZE_ARB*k+:`DATA_SIZE_ARB],
            decompose_out[0][`DATA_SIZE_ARB*k+:`DATA_SIZE_ARB],
            decompose_out[1][`DATA_SIZE_ARB*k+:`DATA_SIZE_ARB],
            decompose_out[2][`DATA_SIZE_ARB*k+:`DATA_SIZE_ARB],
            decompose_out[3][`DATA_SIZE_ARB*k+:`DATA_SIZE_ARB]);                                              
        end
endgenerate
generate    
genvar i;
    for (i=0; i<`NTT_NUMBER; i=i+1) begin
    NTTN normal_ct_ntt    (clk,reset,
                              load_w_ntt[i],
                              load_data_ntt[i],
                              start,
                              decompose_out[i],
                              done_ntt[i],
                              bramOut_ntt[i]);
    end
endgenerate


bitReverse reverser_from_ntt (
    clk, reset,
    cycle,
    bramOut_ntt[0],
    reverse_out_from_ntt
);



endmodule
