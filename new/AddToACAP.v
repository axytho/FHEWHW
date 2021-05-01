
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
               input                           write_enable_bram,  //keep it
               input [`RING_DEPTH-1:0]         write_addr_input,
               input [`DATA_SIZE_ARB-1:0]      data_in,
               input                           load_a, //
               input [`DATA_SIZE_ARB-1:0]      data_a,
               input [`RING_DEPTH-1:0]         write_addr_a,
               input                           start_addToACAP,//does the whole homomorphic encryption
               input [`DATA_SIZE_ARB*`PE_NUMBER*`NTT_NUMBER-1:0] secret_key,  
               //input [(`DATA_SIZE_ARB * 4 * 2 *`PE_NUMBER)-1:0] key_in,
               input [`RING_DEPTH-1:0]         read_out,
               output reg                      done,
               output [`DATA_SIZE_ARB-1:0] data_out//### WE SAVE SPACE AND ONLY OUTPUT 1 thing at a time? I think this makes sense
               // ###output reg [`DATA_SIZE_ARB-1:0] dout
               );
               
 reg [`RING_DEPTH+3:0] sys_cntr;
 reg [2:0] state;
 
 wire [`RING_DEPTH-1:0]         write_addr_output;
 assign write_addr_output = (sys_cntr & (`RING_SIZE -1));
 wire load_output;
 assign load_output = (state == 3'd5) & (sys_cntr < `RING_SIZE);
 reg [`RING_DEPTH-1:0] read_addr_in;
reg                        start_full;
 reg                       load_data_ntt;
 reg                       load_data_intt;
 reg                       start_ntt;
 reg                       start_intt;
 reg                       done_acc;
  wire  [`DATA_SIZE_ARB-1:0] din_intt;
 wire  [`DATA_SIZE_ARB-1:0] dout_ntt[`NTT_NUMBER-1:0];
 reg                       outputSingle;
 wire                      done_ntt [`NTT_NUMBER-1:0];
 wire                      done_intt;
 wire [(2* `DATA_SIZE_ARB *`PE_NUMBER)-1:0] decompose_in;
 wire [(2* `DATA_SIZE_ARB *`PE_NUMBER)-1:0] decompose_out [`NTT_NUMBER-1:0];
 reg [(2* `DATA_SIZE_ARB *`PE_NUMBER)-1:0] decompose_out_reg [`NTT_NUMBER-1:0];
 wire [(2* `DATA_SIZE_ARB *`PE_NUMBER)-1:0] bramOut_ntt [`NTT_NUMBER-1:0];






 always @(posedge clk or posedge reset) begin
                   if(reset) begin
                       state <= 3'd0;
                       sys_cntr <= 0;
                   end
                   else begin
                       case(state)
                       3'd0: begin //in state 0, the data can be read into the BRAM's, but we're not doing other stuff.
                          if(start_addToACAP) begin
                               state <= 3'd1;//load data into intt (either from the input or from the ntt brams
                           end
                           else begin
                               state <= 3'd0;     
                           end
                           sys_cntr <= 0;
                       end

                       3'd1: begin 
                           if(sys_cntr == (`RING_SIZE+1)) begin //because it takes 1024 cycles, so we really don't want to do this every time
                               state <= 3'd2;
                               sys_cntr <= 0;
                           end
                           else begin
                               state <= 3'd1;
                               sys_cntr <= sys_cntr + 1;
                           end
                       end
                       
                       3'd2: begin //run the inntt //TODO: done_intt doesn't work
                            if(done_intt) begin //because it takes 1024 cycles, so we really don't want to do this every 
                              state <= 3'd3;
                              sys_cntr <= 0;
                          end
                          else begin
                              state <= 3'd2;
                              sys_cntr <= sys_cntr + 1;
                          end
                       end
                       3'd3: begin// wait for innt to finish going through the signed bit decompose and writing to ntt
                           if(sys_cntr == ((`RING_SIZE >> (`PE_DEPTH+1)) + `STAGE_DELAY)) begin
                               state <= 3'd4;
                               sys_cntr <= 0;
                           end
                           else begin
                               state <= 3'd3;
                               sys_cntr <= sys_cntr + 1;
                           end
                       end
                       3'd4: begin//run the ntt and check whether we're going for another run or whether we're outputting
                           if(done_ntt[0] && done_acc) begin //because it takes 1024 cycles, so we really don't want to do this every 
                                 state <= 3'd5;
                                 sys_cntr <= 0;
                             end
                           else if (done_ntt[0] && ~done_acc) begin
                                 state <= 3'd6; 
                                 sys_cntr <= 0;
                           end
                             else begin
                                 state <= 3'd4;
                                 sys_cntr <= sys_cntr + 1;
                             end
                       end
                       
                       3'd5: begin//means we're done and we're outputing data
                           if (sys_cntr == (`RING_SIZE+1)) begin
                              state <= 3'd0;
                              sys_cntr <= 0;// finished one loop
                          end 
                          else begin
                             state <= 3'd5;
                             sys_cntr <= sys_cntr + 1;
                         end                     
                       end
                       
                       3'd6: begin//output data to intt agaiin
                          if (sys_cntr == ((`RING_SIZE >> (`PE_DEPTH+1)) + `STAGE_DELAY)) begin
                             state <= 3'd2;//we keep going until some bigger timer , output done too to help bigger counter understand we've
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
wire [`RING_DEPTH-`PE_DEPTH-1:0] inttlast;
assign inttlast = (sys_cntr & ((`RING_SIZE >> (`PE_DEPTH+1))-1));

always @(posedge clk or posedge reset) begin: INPUT_SINGLE
        if(reset) begin
            read_addr_in <= 0;
            load_data_intt <= 0;
        end
        else begin            
            if (state == 3'd1) begin // input data from BRAM
                read_addr_in <= sys_cntr-2+2;//-2 because we start late, +2 because delay of BRAM
                load_data_intt <= (sys_cntr == 1);
            end
            else  begin
                read_addr_in <= 0;
                load_data_intt <= 0;
            end         
       end
 
end

always @(posedge clk or posedge reset) begin: START_INTT
        if(reset) begin
            start_intt <= 0;
            start_full<= 0;
        end
        else begin
         start_full<= 0;            
            if (state == 3'd2) begin // input data from BRAM
                start_intt <= (sys_cntr == 1);// one extra cycle doesn't hurt anything, and it gives us extra time
            end
            else  begin
                start_intt <= 0;
            end         
       end
 
end

always @(posedge clk or posedge reset) begin: LOAD_NTT
        if(reset) begin
            load_data_ntt <= 0;
        end
        else begin            

                load_data_ntt <= done_intt;
        end
end     

always @(posedge clk or posedge reset) begin: START_NTT
        if(reset) begin
            start_ntt <= 0;
        end
        else begin            
            if (state == 3'd4) begin // input data from BRAM
                start_ntt <= (sys_cntr == 1);// one extra cycle doesn't hurt anything, and it gives us extra time
            end
            else  begin
                start_ntt <= 0;
            end         
       end
 
end

always @(posedge clk or posedge reset) begin: DONE_ACC //check whether we're done (usuall
        if(reset) begin
            done_acc <= 0;
            outputSingle  <=0;
        end
        else begin            
            if (state == 3'd4) begin // input data from BRAM
                done_acc <= 1;// we force done for now to test whether it works
                outputSingle <= (1'b1);
            end
            else  begin
                done_acc <= 0;
                outputSingle  <=0;
            end         
       end
 
end
always @(posedge clk or posedge reset) begin: OUTPUT_DATA //check whether we're done (usuall
        if(reset) begin
            done <= 0;
        end
        else begin            
            if (state == 3'd5) begin // input data from BRAM
                done <= (sys_cntr==`RING_SIZE); // we force done for now to test whether it works
            end
            else  begin
                done <= 0;
            end         
       end
 
end

// ### important: we can (and should) initialize or weights from an external file https://studfile.net/preview/4643996/page:29/ instead of loading it in
// ### actually no, that's a terrible idea
// ### actually yes, it's a great idea, verilog is just terrible at the implementation of it.


// ---------------------------------------------------------------- UUT
BRAM #(.DLEN(`DATA_SIZE_ARB),.HLEN(`RING_DEPTH)) ACCInput(clk,write_enable_bram,write_addr_input,data_in,read_addr_in,din_intt);

BRAM #(.DLEN(`DATA_SIZE_ARB),.HLEN(`RING_DEPTH)) ACCOutput(clk,load_output,write_addr_output,dout_ntt[0],read_out,data_out);


INTT inverse_ntt    (clk,reset,
             load_intt_from_bram,
             start_full,
             load_data_intt,
             start_intt,
             din_intt,
             bramOut_ntt[0],
             done_intt,
             decompose_in);
    
             
generate
genvar k;
       for (k=0; k<(`PE_NUMBER*2); k=k+1) begin     
            signedDigitDecompose decompose ( //TODO: parametrize signedDec
            decompose_in[`DATA_SIZE_ARB*k+:`DATA_SIZE_ARB],
            decompose_out[0][`DATA_SIZE_ARB*k+:`DATA_SIZE_ARB],
            decompose_out[1][`DATA_SIZE_ARB*k+:`DATA_SIZE_ARB],
            decompose_out[2][`DATA_SIZE_ARB*k+:`DATA_SIZE_ARB],
            decompose_out[3][`DATA_SIZE_ARB*k+:`DATA_SIZE_ARB]);                                              
        end
endgenerate

always @(posedge clk or posedge reset) begin: REG_BLOCK
    integer n;
    for (n=0; n<(`PE_NUMBER*2); n=n+1) begin  
           if (reset) begin
               decompose_out_reg[n] <=0;
           end
           else begin
               decompose_out_reg[n] <= decompose_out[n];
           end
    end
end





generate    
genvar i;
    for (i=0; i<`NTT_NUMBER; i=i+1) begin
    NTTN normal_ct_ntt    (clk,reset,
                              load_data_ntt,
                              start_ntt,
                              decompose_out_reg[i],
                              outputSingle,
                              done_ntt[i],
                              bramOut_ntt[i],
                              dout_ntt[i]);
    end
endgenerate





endmodule
