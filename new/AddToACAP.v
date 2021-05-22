
//////////////////////////////////////////////////////////////////////////////////
// Contact me at Jonas Bertels <jonas.bertels@kuleuven.be> if code is unclear
//  Use as you please (but keep in mind that the NTT was written by Mert and as such
// his licenses apply).
//////////////////////////////////////////////////////////////////////////////////


`include "defines.v"


module AddToACAP(
               input                           clk,
               input                           resetn,
                 //keep it
               //input [32-1:0]         bram_read, //11 bits, because we are working with RGSW b, with 2*1024 bits
               input [31:0]                     data_in,
               /*input                           load_a, //
               input [`A_WIDTH-1:0]      data_a,
               input [`RING_DEPTH-1:0]         write_addr_a,*/
               //input                           start_addToACAP,//does the whole homomorphic encryption
               //input [`DATA_SIZE_ARB*`PE_NUMBER*`NTT_NUMBER-1:0] secret_key,  
               //input [(`DATA_SIZE_ARB * 4 * 2 *`PE_NUMBER)-1:0] key_in,
               //input [`RING_DEPTH+1-1:0]         read_out,
               //output reg                      done, //DONE SIGNAL ALSO GOES INTO BRAM
               output  reg   [3:0]                       write_enable_bram,
               output                          port_enable,
               output reg [32-1:0]     write_addr_interfacebram, //NOT A REAL REG
               output reg [32-1:0]    data_out//### WE SAVE SPACE AND ONLY OUTPUT 1 thing at a time? I think this makes sense
               
               //output [`SECRET_ADDR_WIDTH-1:0] secret_addr
               // ###output reg [`DATA_SIZE_ARB-1:0] dout
               );
               
 reg [`RING_DEPTH+3:0] sys_cntr;
 reg [2:0] state;
 
 wire reset;

assign port_enable = 1'b1; // must always be 1, or we can't check for the start signal.
 
 wire [`RING_DEPTH-1:0]         write_addr_output;
 assign write_addr_output = (sys_cntr & (`RING_SIZE -1));

 reg [`RING_DEPTH-1:0] read_addr_in;
wire                        start_full;
 reg                       load_data_ntt;
 reg                       load_data_intt;
 reg                       start_ntt;
 reg                       start_intt;
  wire  [`DATA_SIZE_ARB-1:0] din_intt;
 wire  [`DATA_SIZE_ARB-1:0] dout_intt;
 reg                       outputSingle;
 wire                      done_ntt [`NTT_NUMBER-1:0];
 wire                      done_intt;
 wire [(2* `DATA_SIZE_ARB *`PE_NUMBER)-1:0] decompose_in;
  wire [(2* `DATA_SIZE_ARB *`PE_NUMBER)-1:0] bramIn_intt;
 wire [(2* `DATA_SIZE_ARB *`PE_NUMBER)-1:0] decompose_out [`NTT_NUMBER-1:0];
 reg [(2* `DATA_SIZE_ARB *`PE_NUMBER)-1:0] decompose_out_reg [`NTT_NUMBER-1:0];
 wire [(2* `DATA_SIZE_ARB *`PE_NUMBER)-1:0] bramOut_ntt [`NTT_NUMBER-1:0];
 wire [(`PE_DEPTH+1)-1:0] secret_addr_ntt [`NTT_NUMBER-1:0];

wire [`NTT_NUMBER*`DATA_SIZE_ARB-1:0] add_input [2*`PE_NUMBER-1:0];
wire [`DATA_SIZE_ARB-1:0] add_result [2*`PE_NUMBER-1:0];
reg [`DATA_SIZE_ARB-1:0] add_result_reg [2*`PE_NUMBER-1:0];

reg start_addToACAP;
assign reset = (~resetn || (state==3'd0 && ~start_addToACAP)); //defining it this way ensures reset




reg [`CNTR-1+1:0] acc_cntr;
reg [`CNTR-1+1:0] a_zero_cntr;
wire [`CNTR-1+1:0] acc_cnt_a_zero_sum;
wire [`A_WIDTH-1:0] data_out_a;
assign data_out_a = data_in[`A_WIDTH-1:0];

reg notTheFirstTime;
 reg jState; //whether we are working with the first part of GSW or the second part;
 
 reg load_intt_from_bram;
 
 // --------------EVERYTHING BETWEEN THESE COMMENTS IS HACKED IN TO MAKE A VERY BASIC INTERFACE WORK. 
 reg [`DATA_SIZE_ARB*`PE_NUMBER*`NTT_NUMBER-1:0] secret [0:64-1];
 initial begin
    	$readmemb("D:/Jonas/Documents/Huiswerk/KULeuven5/VerilogThesis/edt_zcu102/edt_zcu102.srcs/sources_1/imports/VerilogThesis/test/FULLSECRET.txt", secret);
 end
 
 reg [`DATA_SIZE_ARB*`PE_NUMBER*`NTT_NUMBER-1:0] secret_key;
 //wire [6-1:0] secret_addr;
 //wire [6-1:0] secret_addr_d;
 
initial begin
         secret_key <= 3456'b011111100000111111100010100011111100000111111100010100011111100000111111100010100011111100000111111100010100011111100000111111100010100011111100000111111100010100011111100000111111100010100011111100000111111100010100011111100000111111100010100011111100000111111100010100011111100000111111100010100011111100000111111100010100011111100000111111100010100011111100000111111100010100011111100000111111100010100011111100000111111100010100011111100000111111100010100011111100000111111100010100011111100000111111100010100011111100000111111100010100011111100000111111100010100011111100000111111100010100011111100000111111100010100011111100000111111100010100011111100000111111100010100011111100000111111100010100011111100000111111100010100011111100000111111100010100011111100000111111100010100011111100000111111100010100011111100000111111100010100011111100000111111100010100011111100000111111100010100011111100000111111100010100011111100000111111100010100011111100000111111100010100011111100000111111100010100011111100000111111100010100011111100000111111100010100011111100000111111100010100011111100000111111100010100011111100000111111100010100011111100000111111100010100011111100000111111100010100011111100000111111100010100011111100000111111100010100011111100000111111100010100011111100000111111100010100011111100000111111100010100011111100000111111100010100011111100000111111100010100011111100000111111100010100011111100000111111100010100011111100000111111100010100011111100000111111100010100011111100000111111100010100011111100000111111100010100011111100000111111100010100011111100000111111100010100011111100000111111100010100011111100000111111100010100011111100000111111100010100011111100000111111100010100011111100000111111100010100011111100000111111100010100011111100000111111100010100011111100000111111100010100011111100000111111100010100011111100000111111100010100011111100000111111100010100011111100000111111100010100011111100000111111100010100011111100000111111100010100011111100000111111100010100011111100000111111100010100011111100000111111100010100011111100000111111100010100011111100000111111100010100011111100000111111100010100011111100000111111100010100011111100000111111100010100011111100000111111100010100011111100000111111100010100011111100000111111100010100011111100000111111100010100011111100000111111100010100011111100000111111100010100011111100000111111100010100011111100000111111100010100011111100000111111100010100011111100000111111100010100011111100000111111100010100011111100000111111100010100011111100000111111100010100011111100000111111100010100011111100000111111100010100011111100000111111100010100011111100000111111100010100011111100000111111100010100011111100000111111100010100011111100000111111100010100011111100000111111100010100011111100000111111100010100011111100000111111100010100011111100000111111100010100011111100000111111100010100011111100000111111100010100011111100000111111100010100011111100000111111100010100011111100000111111100010100011111100000111111100010100011111100000111111100010100011111100000111111100010100011111100000111111100010100011111100000111111100010100011111100000111111100010100011111100000111111100010100011111100000111111100010100011111100000111111100010100011111100000111111100010100011111100000111111100010100011111100000111111100010100011111100000111111100010100011111100000111111100010100011111100000111111100010100011111100000111111100010100011111100000111111100010100011111100000111111100010100; 
         //TOY SECRET KEY
 end
 //ShiftReg #(.SHIFT(1),.DATA(6)) address_shift(clk, reset, secret_addr, secret_addr_d);
 
  // --------------EVERYTHING BETWEEN THESE COMMENTS IS HACKED IN TO MAKE A VERY BASIC INTERFACE WORK. ORDINARLILY, our secret key comes from the outside
// ---------------
 
 always @(posedge clk or posedge reset) begin
                   if(reset) begin
                       state <= 3'd0;
                       sys_cntr <= 0;
                   end
                   else begin
                       case(state) //TODO: change state0 so it continually reads from the interface BRAML
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
                       
                       3'd2: begin //run the inntt 
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
                               state <= 3'd7; //quickly verify that the next stage is not a a0==0
                               sys_cntr <= 0;
                           end
                           else begin
                               state <= 3'd3;
                               sys_cntr <= sys_cntr + 1;
                           end
                       end
                       3'd4: begin//run the ntt and check whether we're going for another run or whether we're outputting
                           if(done_ntt[0]) begin //because it takes 1024 cycles, so we really don't want to do this every 
                                 if (notTheFirstTime) begin
                                    if (jState) begin//jState changes on done_ntt so will still be 1 if we continue to readout
                                        state <= 3'd6;
                                    end
                                    else begin
                                        state <= 3'd2;
                                    end
                                    
                                 end
                                 else begin
                                    state <= 3'd1; //rerunning state_1 because we need to run it for the second part of the ACC
                                 end
                                 sys_cntr <= 0;
                             end
                             else begin
                                 state <= 3'd4;
                                 sys_cntr <= sys_cntr + 1;
                             end
                       end
                       
                       3'd5: begin//means we're (almost) done and we're outputing data
                           if (sys_cntr >((`RING_SIZE<<1)+9)) begin

                               state <= 3'd0;
                              
                               sys_cntr <= 0;// finished one loop
                          end 
                          else begin
                             state <= 3'd5;
                             sys_cntr <= sys_cntr + 1;
                         end                     
                       end
                       
                       3'd6: begin//output data to intt agaiin (go through addition) We only run it once every time AddToACAP finishes
                          if (sys_cntr == ((`RING_SIZE >> (`PE_DEPTH)) + `STAGE_DELAY)) begin//output 32 cycles
                             if(acc_cnt_a_zero_sum > 11'd63)  begin //go to state 5, for final output
                                  state <= 3'd5;
                                  sys_cntr <= 0;
                             end
                             else begin // rerun intt
                                state <= 3'd2;
                                sys_cntr <= 0;
                             end
                         end 
                         else begin
                            state <= 3'd6;
                            sys_cntr <= sys_cntr + 1;
                         end                     
                       end
                                               
                                               
                       3'd7: begin // a state just for seeing how many a's turn out to be 0
                            sys_cntr <= 0;
                            if (~(data_out_a == 0)) begin
                                state <= 3'd4;
                                sys_cntr <= 0;
                            end
                            else begin
                                state <= 3'd7;
                                sys_cntr <= sys_cntr+1;
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

wire [(`RING_DEPTH+1-1):0] sys_cntr_minus_five;
assign sys_cntr_minus_five = sys_cntr[(`RING_DEPTH+1-1):0]-5;

always @(*) begin: WRITE_ADDR_BLOCK
    if (state==3'd0) begin  
        write_addr_interfacebram <= 13'h1004; //decimal: 4100:adress where deadbeef should be located
        write_enable_bram <= 4'b0000;
        data_out <= 32'hdeadc0de;
    end
    else if (state==3'd1) begin 
        write_addr_interfacebram <= {jState, read_addr_in};
        write_enable_bram <= 4'b0000;
        data_out <= 32'hdeadc0de;
    end
    //write data away
    else if (state==3'd5 && (sys_cntr < ((`RING_SIZE<<1)+5))) begin 
        write_addr_interfacebram <=  {2'b11,sys_cntr_minus_five};
        write_enable_bram <= 4'b1111;
        data_out <= dout_intt;
    end
    //write done
    else if (state==3'd5&& sys_cntr == ((`RING_SIZE<<1)+6)) begin //4 is randomly chosen to make a done statement
        write_addr_interfacebram <=  13'h1789;
        write_enable_bram <= 4'b1111;
        data_out <= 32'hd01ecafe;
    end
    else if (state==3'd5&& sys_cntr == ((`RING_SIZE<<1)+7)) begin //4 is randomly chosen to make a done statement
        write_addr_interfacebram <=  13'h1004;//overwrite the start so we don't start again 
        write_enable_bram <= 4'b1111;
        data_out <= 32'hbabacafe;
    end
    else begin
        write_addr_interfacebram <= {3'b010,acc_cnt_a_zero_sum[9:0]};
        write_enable_bram <= 4'b0000;
        data_out <= 32'hdeadc0de;
    end

end




always @(*) begin: START_AND_RESET     

        if (state == 3'd0 && data_in==32'hdeadbeef) begin // input data from BRAM
            start_addToACAP <= 1;//-2 because we start late, +1 because delay of BRAM
        end
        else  begin
            start_addToACAP <= 0;
        end         
end


always @(posedge clk or posedge reset) begin: INPUT_SINGLE
        if(reset) begin
            read_addr_in <= 0;
            load_data_intt <= 0;
        end
        else begin            
            if (state == 3'd1) begin // input data from BRAM
                read_addr_in <= sys_cntr-2+1;//-2 because we start late, +1 because delay of BRAM
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
        end
        else begin
                     
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
always @(posedge clk or posedge reset) begin: LOAD_INTT
        if(reset) begin
            load_intt_from_bram <= 0;
        end
        else begin            

                load_intt_from_bram <= (done_ntt[0] & notTheFirstTime & jState);//if jState ==1, this means the previous round is just done.
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
// assign start_full
// start_full is made so that if you trigger it, the intt will turn it off during execution
assign start_full = (state ==3'd4 & notTheFirstTime);


always @(posedge clk or posedge reset) begin: DONE_ACC //check whether we're done (usuall
        if(reset) begin
            outputSingle  <=0;
        end
        else begin            
            if (state == 3'd5) begin // input data from BRAM
             // we force done for now to test whether it works
                outputSingle <= (sys_cntr == 0);
            end
            else  begin
                outputSingle  <=0;
            end         
       end
 
end


always @(posedge clk or posedge reset) begin: FIRST_TIME_REG
        if(reset) begin
            notTheFirstTime <= 0;
            jState <= 0;
            acc_cntr <=0;
            a_zero_cntr <= 0;
        end
        else begin            
            if (state == 3'd4 && done_ntt[0]) begin // input data from BRAM
                notTheFirstTime <= 1'b1; // we force done for now to test whether it works
                jState <= ~jState;
                acc_cntr <= acc_cntr + 1;
                a_zero_cntr <= a_zero_cntr;
            end
            else if ((state == 3'd7) && (data_out_a==0) && (sys_cntr[0] == 1'b0)) begin // the first cycle in state we probably don't do anything,
                //only in even cycles, because we need 2 cycles to verify that the next a is actually 0, because BRAM delay
                notTheFirstTime <= notTheFirstTime;
                jState <= jState;
                acc_cntr <=acc_cntr;//TODO:
                a_zero_cntr <= a_zero_cntr+1;//+2 because we need +2 to change a address
            end
            else  begin
                notTheFirstTime <= notTheFirstTime;
                jState <= jState;
                acc_cntr <=acc_cntr;
                a_zero_cntr <= a_zero_cntr;
            end         
       end
 
end


wire [`A_WIDTH-1:0]addr_a_minus_one;
assign addr_a_minus_one = data_in[`A_WIDTH-1:0] - 1;
wire [`CNTR+`A_WIDTH-1:0] i_LWE_Dr_plus_a0;
assign acc_cnt_a_zero_sum = acc_cntr[`CNTR:1] + a_zero_cntr;
assign i_LWE_Dr_plus_a0 = (`B_R-1)*acc_cnt_a_zero_sum+addr_a_minus_one;
//secret_addr_ntt contains both the EVENODD variable, the current j_result we're multiplying for and the PE_cycle_BRAM_EVENODD, it is 6 bits
// j_state tells us which j_dct_result we're multiplying with
// the top is an addition of the address a plus the 10 bits that make up acc_cntr[CNTR:1]
assign secret_addr = {i_LWE_Dr_plus_a0, jState, secret_addr_ntt[0]};//15+1+6=22 bits



// ### important: we can (and should) initialize or weights from an external file https://studfile.net/preview/4643996/page:29/ instead of loading it in
// ### actually no, that's a terrible idea
// ### actually yes, it's a great idea, verilog is just terrible at the implementation of it.


// ---------------------------------------------------------------- UUT
/*
BRAM #(.DLEN(`DATA_SIZE_ARB),.HLEN(`RING_DEPTH+1)) ACCInput(clk,write_enable_bram,write_addr_input,data_in,{jState, read_addr_in},din_intt);

BRAM #(.DLEN(`DATA_SIZE_ARB),.HLEN(`RING_DEPTH+1)) ACCOutput(clk,load_output,{jState, write_addr_output},dout_intt,read_out,data_out);

BRAM #(.DLEN(`A_WIDTH),.HLEN(`CNTR)) ACC_a(clk,load_a,write_addr_a,data_a,acc_cnt_a_zero_sum,data_out_a);
*/
assign din_intt = data_in[`DATA_SIZE_ARB-1:0];

INTT inverse_ntt    (clk,reset,
             load_intt_from_bram,
             start_full,
             load_data_intt,
             start_intt,
             din_intt,
             bramIn_intt,
             outputSingle, //To be set
             jState,
             done_intt,
             decompose_in,
             dout_intt);
    
             
generate
genvar k;
genvar branch;
       for (k=0; k<(`PE_NUMBER*2); k=k+1) begin     
            signedDigitDecompose decompose ( //TODO: parametrize signedDec
            decompose_in[`DATA_SIZE_ARB*k+:`DATA_SIZE_ARB],
            decompose_out[0][`DATA_SIZE_ARB*k+:`DATA_SIZE_ARB],
            decompose_out[1][`DATA_SIZE_ARB*k+:`DATA_SIZE_ARB],
            decompose_out[2][`DATA_SIZE_ARB*k+:`DATA_SIZE_ARB],
            decompose_out[3][`DATA_SIZE_ARB*k+:`DATA_SIZE_ARB]);
            for (branch = 0; branch<`NTT_NUMBER; branch = branch + 1) begin
                assign add_input[k][(branch*`DATA_SIZE_ARB)+:(`DATA_SIZE_ARB)] = bramOut_ntt[branch][(k*`DATA_SIZE_ARB)+:(`DATA_SIZE_ARB)];
            end
            assign bramIn_intt[`DATA_SIZE_ARB*k+:`DATA_SIZE_ARB] = add_result_reg[k];
            resultAdder addition (add_input[k], add_result[k]); //bit length 216 differs from formal bit length 108 for port 'value_in'                                            
        end
endgenerate

always @(posedge clk or posedge reset) begin: REG_BLOCK_DECOMPOSE
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

always @(posedge clk or posedge reset) begin: REG_BLOCK_ADDER
    integer adder_int;
    for (adder_int=0; adder_int<(`PE_NUMBER*2); adder_int=adder_int+1) begin  
           if (reset) begin
               add_result_reg[adder_int] <=0;
           end
           else begin
               add_result_reg[adder_int] <= add_result[adder_int];
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
                              secret_key[(`DATA_SIZE_ARB*`PE_NUMBER)*i+:(`DATA_SIZE_ARB*`PE_NUMBER)],
                              secret_addr_ntt[i],
                              done_ntt[i],
                              bramOut_ntt[i]
                              );
    end
endgenerate





endmodule
