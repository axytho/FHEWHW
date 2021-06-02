/*
Copyright 2020, Ahmet Can Mert <ahmetcanmert@sabanciuniv.edu>
edited for use in FHEW by Jonas Bertels <jonas.bertels@kuleuven.be>

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

   http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
*/

`include "defines.v"

// start: HIGH for 1 cc (after 1 cc, data starts going in)
// done : HIGH for 1 cc (after 1 cc, data starts going out)

// Input: standard order
// output: scrambled order

// --- Baseline Version
// * address bit-lengts are set according to worst-case
// * supports up-to 2^15-pt NTT/INTT
// * integer multiplier is not optimized
// * modular reduction is not optimized
// * wait state is not optimized

module NTTN   (input                           clk,reset,
               input                           load_bram,
               input                           start,
               input  [(2*`DATA_SIZE_ARB * `PE_NUMBER)-1:0] bramIn,
               input  [(`PE_NUMBER*`DATA_SIZE_ARB)-1:0] secret_key,
               //input                           notTheFirstTime, // we'll output wrongly, but we don't care so this is commented
               output  [`PE_DEPTH-1+1:0]                        secret_addr_ntt,
               output reg                      done,
               output reg [(2*`DATA_SIZE_ARB * `PE_NUMBER)-1:0] bramOut//###
              
               //output reg [`DATA_SIZE_ARB-1:0]                      dout//for single output at the end
               // ###output reg [`DATA_SIZE_ARB-1:0] dout
               );
// ---------------------------------------------------------------- connections

//HARDCODE
wire start_intt;
assign start_intt = 0;

// parameters & control
reg [2:0] state;
// 0: IDLE
// 1: load twiddle factors + q + n_inv
// 2: load data
// 3: performs ntt
// 4: output data
// 5: last stage of intt

reg [`RING_DEPTH+3:0] sys_cntr;
reg jState;

reg [`DATA_SIZE_ARB-1:0]q;
reg [`DATA_SIZE_ARB-1:0]n_inv;

// data tw brams (datain,dataout,waddr,raddr,wen)
reg [`DATA_SIZE_ARB-1:0]        pi [(2*`PE_NUMBER)-1:0];
wire[`DATA_SIZE_ARB-1:0]        po [(2*`PE_NUMBER)-1:0];
reg [`RING_DEPTH-`PE_DEPTH+1:0] pw [(2*`PE_NUMBER)-1:0];
reg [`RING_DEPTH-`PE_DEPTH+2:0] pr [(2*`PE_NUMBER)-1:0];
reg [0:0]                       pe [(2*`PE_NUMBER)-1:0];

reg [`DATA_SIZE_ARB-1:0]        ti [`PE_NUMBER-1:0];
wire[`DATA_SIZE_ARB-1:0]        to [`PE_NUMBER-1:0];
reg [`RING_DEPTH-`PE_DEPTH+3:0] tw [`PE_NUMBER-1:0];
reg [`RING_DEPTH-`PE_DEPTH+3:0] tr [`PE_NUMBER-1:0];
reg [0:0]                       te [`PE_NUMBER-1:0];

// control signals
wire [`RING_DEPTH-`PE_DEPTH+1:0]      raddr;
wire [`RING_DEPTH-`PE_DEPTH+1:0]      waddr0,waddr1;
wire                                  wen0  ,wen1  ;
wire                                  brsel0,brsel1;
wire                                  brselen0,brselen1;
wire [2*`PE_NUMBER*(`PE_DEPTH+1)-1:0] brscramble;
wire [`RING_DEPTH-`PE_DEPTH+2:0]      raddr_tw;

wire [4:0]                       stage_count;
wire                             ntt_finished;

reg                              ntt_intt; // ntt:0 -- intt:1
wire                              writeToProduct;
assign  writeToProduct = (state==3'd5);


assign secret_addr_ntt = sys_cntr[`PE_DEPTH-1+1:0];

//wire  readFromProduct;
//assign  readFromProduct= (state==3'd4);
// pu
reg [`DATA_SIZE_ARB-1:0] NTTin [(2*`PE_NUMBER)-1:0];
reg [`DATA_SIZE_ARB-1:0] MULin [`PE_NUMBER-1:0];
wire[`DATA_SIZE_ARB-1:0] ASout [(2*`PE_NUMBER)-1:0]; // ADD-SUB out  (no extra delay after odd)
wire[`DATA_SIZE_ARB-1:0] EOout [(2*`PE_NUMBER)-1:0]; // EVEN-ODD out

// ---------------------------------------------------------------- BRAMs
// 2*PE BRAMs for input-output polynomial
// PE BRAMs for storing twiddle factors

generate
	genvar k;

    for(k=0; k<`PE_NUMBER ;k=k+1) begin: BRAM_GEN_BLOCK
        BRAM #(.DLEN(`DATA_SIZE_ARB),.HLEN(`RING_DEPTH-`PE_DEPTH+2+1)) bd00(clk,pe[2*k+0],{writeToProduct,pw[2*k+0]},pi[2*k+0],pr[2*k+0],po[2*k+0]);
        BRAM #(.DLEN(`DATA_SIZE_ARB),.HLEN(`RING_DEPTH-`PE_DEPTH+2+1)) bd01(clk,pe[2*k+1],{writeToProduct,pw[2*k+1]},pi[2*k+1],pr[2*k+1],po[2*k+1]);
        WSTORAGE #(.DLEN(`DATA_SIZE_ARB),.HLEN(`RING_DEPTH-`PE_DEPTH+4), .PE_NO(k)) bt00(clk,tr[k],to[k]);//160 values
    end
endgenerate

// ---------------------------------------------------------------- NTT2 units

generate
	genvar m;

    for(m=0; m<`PE_NUMBER ;m=m+1) begin: NTT2_GEN_BLOCK
        NTTCT2 nttu(clk,reset,
                  q,
			      NTTin[2*m+0],NTTin[2*m+1],
				  MULin[m],
				  ASout[2*m+0],ASout[2*m+1],
				  EOout[2*m+0],EOout[2*m+1]);
    end
endgenerate

// ---------------------------------------------------------------- control unit

AddressGeneratorNTTN ag(clk,reset,
                    (start | start_intt),
                    raddr,
                    waddr0,waddr1,
                    wen0  ,wen1  ,
                    brsel0,brsel1,
                    brselen0,brselen1,
                    brscramble,
                    raddr_tw,
                    stage_count,
                    ntt_finished
                    );

// ---------------------------------------------------------------- ntt/intt
reg [`DATA_SIZE_ARB-1:0] params    [0:6];
initial begin
	// params
	$readmemh("D:/Jonas/Documents/Huiswerk/KULeuven5/VerilogThesis/edt_zcu102/edt_zcu102.srcs/sources_1/imports/VerilogThesis/test/PARAM.txt"    , params);
end

always @(posedge clk  ) begin
    if(reset) begin
        ntt_intt <= 0;
    end
    else begin
        if(start)
            ntt_intt <= 0;
        else if(start_intt)
            ntt_intt <= 1;
        else
            ntt_intt <= ntt_intt;
    end
end

// ---------------------------------------------------------------- state machine & sys_cntr

always @(posedge clk  ) begin
    if(reset) begin
        state <= 3'd0;
        sys_cntr <= 0;
    end
    else begin
        case(state)
        3'd0: begin
            if(load_bram)
                state <= 3'd1;
            else if(start | start_intt)
                state <= 3'd3;
            else
                state <= 3'd0;
            sys_cntr <= 0;
        end
        3'd1: begin //BRAM x64 readin
            if(sys_cntr == ((`RING_SIZE >>(`PE_DEPTH+1)) - 1)  ) begin //the -1 goes there to ensure that there we don't write too long
                state <= 3'd0;
                sys_cntr <= 0;
            end
            else begin
                state <= 3'd1;
                sys_cntr <= sys_cntr + 1;
            end
        end

        3'd3: begin
            if(ntt_finished )
                state <= 3'd5;//run secret_key
            else
                state <= 3'd3;
            sys_cntr <= 0;
        end
        3'd4: begin
            if(sys_cntr == ((`RING_SIZE >> (`PE_DEPTH)) + 1)) begin
                state <= 3'd0;
                sys_cntr <= 0;
            end
            else begin
                state <= 3'd4;
                sys_cntr <= sys_cntr + 1;
            end
        end
        3'd5: begin // repurposing this for secret key operations
            if(sys_cntr == (((`RING_SIZE >> (`PE_DEPTH-1))) + `INTMUL_DELAY+`MODRED_DELAY+`STAGE_DELAY)) begin
                /*if (jState ==0) begin
                    state <= 3'd0;// I mean, you could go to state 4, but no one would care, because intt wouldn't listen.
                    sys_cntr <= 0;
                end else begin*/
                    state <= 3'd4; //READ IT OUT ANYWAY, not necessary if we're going to state j=1, but jState is hard to regulate, 
                                   // and if intt doesn't load it doesn't care what's happening.
                    sys_cntr <= 0;
                //end
            end
            else begin
                state <= 3'd5;
                sys_cntr <= sys_cntr + 1;
            end
        end

        
        
        
        /*
        3'd6: begin
            if(sys_cntr == (`RING_SIZE+1)) begin
                state <= 3'd0;
                sys_cntr <= 0;
            end
            else begin
                state <= 3'd6;
                sys_cntr <= sys_cntr + 1;
            end
        end*/
        /*
        3'd7: begin //SUM ALL (read in BRAM x64, and read out at the same time
                    if(sys_cntr == ((`PE_NUMBER>>1)-1+1)) begin
                        if(output_data_single == 0)
                            state <= 3'd4;
                        else
                            state <= 3'd6;
                    end
                    else begin
                        state <= 3'd7;
                        sys_cntr <= sys_cntr + 1;
                    end
                end*/
        default: begin
            state <= 3'd0;
            sys_cntr <= 0;
        end
        endcase
    end
end

// ---------------------------------------------------------------- load twiddle factor + q + n_inv & other operations

always @(posedge clk  ) begin: TW_BLOCK
    integer n;
    for(n=0; n < (`PE_NUMBER); n=n+1) begin: TWIDDLE_LOOP
        if(reset) begin
            te[n] <= 0;
            tw[n] <= 0;
            ti[n] <= 0;
            tr[n] <= 0;
        end
        else begin
            if(state == 3'd3) begin // NTT operations
                te[n] <= 0;
                tw[n] <= 0;
                ti[n] <= 0;
                tr[n] <= raddr_tw;// send it to EVERY PE (so how we write it in is simportant obviously)
            end
            else begin
                te[n] <= 0;
                tw[n] <= 0;
                ti[n] <= 0;
                tr[n] <= 0;
            end
        end
    end
end

always @(posedge clk  ) begin
    if(reset) begin
        q     <= 0;
        n_inv <= 0;
    end
    else begin
        q     <= params[1];
        n_inv <= params[6];
    end
end

// ---------------------------------------------------------------- load data & other data operations
// ### is the symbol for code that I write, and commented code will have a hashtag in from of it
wire [`RING_DEPTH-`PE_DEPTH-1:0] addrout;
assign addrout = (sys_cntr >> (`PE_DEPTH+1));

wire [`RING_DEPTH-`PE_DEPTH-1:0] inttlast;
assign inttlast = (sys_cntr & ((`RING_SIZE >> (`PE_DEPTH+1))-1)); //counter mod 16
//###


wire [`RING_DEPTH+3:0]           sys_cntr_d;
wire [`RING_DEPTH-`PE_DEPTH-1:0] inttlast_d;

always @(posedge clk  ) begin: DT_BLOCK
    integer n;
    for(n=0; n < (2*`PE_NUMBER); n=n+1) begin: LOOP_1
        if(reset) begin
            pe[n] <= 0;
            pw[n] <= 0;
            pi[n] <= 0;
            pr[n] <= 0;
        end
        else begin
        if((state == 3'd1)) begin // input data from BRAM
                // ###
            pe[n] <= 1'b1; //read everything fast
            pw[n] <= inttlast;
            pi[n] <= bramIn[n*`DATA_SIZE_ARB+:`DATA_SIZE_ARB];
            pr[n] <= 0;

        end
        /*
            if((state == 3'd2)) begin // input data
            // ###
                if(sys_cntr < (`RING_SIZE >> 1)) begin
                    pe[n] <= (n == ((sys_cntr & ((1 << `PE_DEPTH)-1)) << 1)); //only even n's
                    pw[n] <= (sys_cntr >> `PE_DEPTH); //write the first 512 values to these even n's (note that these are the BRAM0's.)
                    pi[n] <= din;
                    pr[n] <= 0;
                end
                else begin
                    pe[n] <= (n == (((sys_cntr & ((1 << `PE_DEPTH)-1)) << 1)+1));// only odd n's
                    pw[n] <= ((sys_cntr-(`RING_SIZE >> 1)) >> `PE_DEPTH);// write them to the BRAM1
                    pi[n] <= din;
                    pr[n] <= 0;
                end // ### 
            end */
            else if(state == 3'd3) begin // NTT operations
            //writeback is split into 2 stages: in the first stage we write 
                if(stage_count < (`RING_DEPTH - `PE_DEPTH - 1)) begin
                    if(brselen0) begin
                        if(brsel0 == 0) begin
                            if(n[0] == 0) begin
                                pe[n] <= wen0;
                                pw[n] <= waddr0;
                                pi[n] <= EOout[n];
                            end
                        end
                        else begin // brsel0 == 1
                            if(n[0] == 0) begin
                                pe[n] <= wen1;
                                pw[n] <= waddr1;
                                pi[n] <= EOout[n+1];
                            end
                        end
                    end
                    else begin
                        if(n[0] == 0) begin
                            pe[n] <= 0;
                            pw[n] <= pw[n];
                            pi[n] <= pi[n];
                        end
                    end

                    if(brselen1) begin
                        if(brsel1 == 0) begin
                            if(n[0] == 1) begin
                                pe[n] <= wen0;
                                pw[n] <= waddr0;
                                pi[n] <= EOout[n-1];
                            end
                        end
                        else begin // brsel1 == 1
                            if(n[0] == 1) begin
                                pe[n] <= wen1;
                                pw[n] <= waddr1;
                                pi[n] <= EOout[n];
                            end
                        end
                    end
                    else begin
                        if(n[0] == 1) begin
                            pe[n] <= 0;
                            pw[n] <= pw[n];
                            pi[n] <= pi[n];
                        end
                    end
                end
                else if(stage_count < (`RING_DEPTH - 1)) begin
                    pe[n] <= wen0;
                    pw[n] <= waddr0;
                    pi[n] <= ASout[brscramble[(`PE_DEPTH+1)*n+:(`PE_DEPTH+1)]];
                end
                else begin// this is what you're going to want: when stage_cout == RING_DEPTH -1
                    pe[n] <= wen0;
                    pw[n] <= waddr0;
                    pi[n] <= ASout[n];
                end
                pr[n] <= {1'b0, raddr};
            end
            else if(state == 3'd4) begin // output data
               // if (jState ==0) begin
                    pe[n] <= 0;
                    pw[n] <= 0;
                    pi[n] <= 0;
                    //###pr[n] <= {2'b10,addrout};
                    pr[n] <= {3'b101,sys_cntr[4:0]};//5 bits for 32 cycles of readout
               /* end
                else begin
                    pe[n] <= 0;
                    pw[n] <= 0;
                    pi[n] <= 0;
                    //###pr[n] <= {2'b10,addrout};
                    pr[n] <= {4'b1011,inttlast[3:0]};//### correct in this case                
                
                end*/
            end
            else if(state == 3'd5) begin // last stage of intt
                if (jState ==0) begin
                    if(sys_cntr_d < (`RING_SIZE >> (`PE_DEPTH+1))) begin
                        if(n[0] == 0) begin
                            pe[n+1] <= 1;
                            pw[n+1] <= {3'b000,inttlast_d[3:0]};
                            pi[n+1] <= ASout[n];//read the even result wich gives w*Odd
                        end
                        else begin
                            pe[n-1] <= 0;
                            pw[n-1] <= 0;
                            pi[n-1] <= 0;
                        end
                    end
                    else if(sys_cntr_d < (`RING_SIZE >> (`PE_DEPTH))) begin
                        if(n[0] == 1) begin
                            pe[n-1] <= 1;
                            pw[n-1] <= {3'b000,inttlast_d[3:0]};
                            pi[n-1] <= ASout[n-1];
                        end
                        else begin
                            pe[n+1] <= 0;
                            pw[n+1] <= 0;
                            pi[n+1] <= 0;
                        end
                    end
                    else if(sys_cntr_d < (2'd3*(`RING_SIZE >> (`PE_DEPTH+1)))) begin
                        if(n[0] == 0) begin
                            pe[n+1] <= 1;
                            pw[n+1] <= {3'b001,inttlast_d[3:0]};
                            pi[n+1] <= ASout[n];
                        end
                        else begin
                            pe[n-1] <= 0;
                            pw[n-1] <= 0;
                            pi[n-1] <= 0;
                        end
                    end
                    else if(sys_cntr_d < (`RING_SIZE >> (`PE_DEPTH)-1)) begin
                        if(n[0] == 1) begin
                            pe[n-1] <= 1;
                            pw[n-1] <= {3'b001,inttlast_d[3:0]};
                            pi[n-1] <= ASout[n-1];
                        end
                        else begin
                            pe[n+1] <= 0;
                            pw[n+1] <= 0;
                            pi[n+1] <= 0;
                        end
                    end
                    else begin
                        pe[n] <= 0;
                        pw[n] <= 0;
                        pi[n] <= 0;
                    end
                    pr[n] <= {4'b0100,inttlast[3:0]};//in the first one, it's indeed this simple, but not the second one
                    // I add [3:0] to make it obvious what's happening
                end
                else begin //if jstate ==1
                    if(sys_cntr_d < (`RING_SIZE >> (`PE_DEPTH+1))) begin
                        if(n[0] == 0) begin
                            //pr[n] <= {4'b0010,inttlast[3:0]};//Bram 0 still has to be multiplied, so read that from lower half of BRAM
                            pe[n] <= 1;
                            pw[n] <= {3'b010,inttlast_d[3:0]};
                            pi[n] <= ASout[n];//read the even result wich gives w*Odd
                        end
                        else begin
                            //pr[n] <= {4'b1000,inttlast[3:0]};// BRAM1 is aded, but that's been stored
                            pe[n] <= 0;
                            pw[n] <= 0;
                            pi[n] <= 0;
                        end
                    end
                    else if(sys_cntr_d < (`RING_SIZE >> (`PE_DEPTH))) begin
                        if(n[0] == 1) begin
                            //pr[n] <= {4'b0010,inttlast[3:0]};//now BRAM 1 still has to be multiplied, which we find in the lower half
                            pe[n] <= 1;
                            pw[n] <= {3'b010,inttlast_d[3:0]};
                            pi[n] <= ASout[n-1];
                        end
                        else begin
                            //pr[n] <= {4'b1000,inttlast[3:0]}; //BRAM0 is added
                            pe[n] <= 0;
                            pw[n] <= 0;
                            pi[n] <= 0;
                        end
                    end
                    else if(sys_cntr_d < (2'd3*(`RING_SIZE >> (`PE_DEPTH+1)))) begin
                        if(n[0] == 0) begin //IF BRAM0
                            //pr[n] <= {4'b0011,inttlast[3:0]};
                            pe[n] <= 1;
                            pw[n] <= {3'b011,inttlast_d[3:0]};
                            pi[n] <= ASout[n];
                        end
                        else begin
                            //pr[n] <= {4'b1001,inttlast[3:0]};//BRAM1 got stored here to be added
                            pe[n] <= 0;
                            pw[n] <= 0;
                            pi[n] <= 0;
                        end
                    end
                    else if(sys_cntr_d < (`RING_SIZE >> (`PE_DEPTH)-1)) begin
                        if(n[0] == 1) begin
                            //pr[n] <= {4'b0011,inttlast[3:0]};
                            pe[n] <= 1;
                            pw[n] <= {3'b011,inttlast_d[3:0]};
                            pi[n] <= ASout[n-1];
                        end
                        else begin
                            //pr[n] <= {4'b1001,inttlast[3:0]}; //if BRAM0, read from where you stored your values for BRAM1 multiplication
                            pe[n] <= 0;
                            pw[n] <= 0;
                            pi[n] <= 0;
                        end
                    end
                    else begin
                        //pr[n] <= 0;
                        pe[n] <= 0;
                        pw[n] <= 0;
                        pi[n] <= 0;
                    end
                                    
                //pr gets programmed seperately because it needs to run on sys_cntr
                    if(sys_cntr < (`RING_SIZE >> (`PE_DEPTH+1))) begin
                        if(n[0] == 0) begin
                            pr[n] <= {4'b0100,inttlast[3:0]};//Bram 0 still has to be multiplied, so read that from lower half of BRAM
                        end
                        else begin
                            pr[n] <= {4'b1000,inttlast[3:0]};// BRAM1 is aded, but that's been stored
                        end
                    end
                    else if(sys_cntr < (`RING_SIZE >> (`PE_DEPTH))) begin
                        if(n[0] == 1) begin
                            pr[n] <= {4'b0100,inttlast[3:0]};//now BRAM 1 still has to be multiplied, which we find in the lower half
                        end
                        else begin
                            pr[n] <= {4'b1000,inttlast[3:0]}; //BRAM0 is added
                        end
                    end
                    else if(sys_cntr < (2'd3*(`RING_SIZE >> (`PE_DEPTH+1)))) begin
                        if(n[0] == 0) begin //IF BRAM0
                            pr[n] <= {4'b0100,inttlast[3:0]};
                        end
                        else begin
                            pr[n] <= {4'b1001,inttlast[3:0]};//BRAM1 got stored here to be added
                        end
                    end
                    else if(sys_cntr < (`RING_SIZE >> (`PE_DEPTH)-1)) begin
                        if(n[0] == 1) begin
                            pr[n] <= {4'b0100,inttlast[3:0]};
                        end
                        else begin
                            pr[n] <= {4'b1001,inttlast[3:0]}; //if BRAM0, read from where you stored your values for BRAM1 multiplication
                        end
                    end
                    else begin
                        pr[n] <= 0;
                    end
                                    
                end
            end
            /*
            else if(state == 3'd6) begin // output data
                pe[n] <= 0;
                pw[n] <= 0;
                pi[n] <= 0;
                pr[n] <= {2'b10,addrout};
            end*/
            else begin
                pe[n] <= 0;
                pw[n] <= 0;
                pi[n] <= 0;
                pr[n] <= 0;
            end
        end
    end
end



// done signal & output data
wire [`PE_DEPTH:0] coefout;
assign coefout = (sys_cntr-2);

always @(posedge clk  ) begin: OUT_BLOCK
integer n;
    for(n=0; n < (2*`PE_NUMBER); n=n+1) begin: LOOP_1
        if(reset) begin
            done <= 0;
            bramOut <= 0;
        end
        else begin
            if(state == 3'd4) begin
                done <= (sys_cntr == 1);
                bramOut[(`DATA_SIZE_ARB)*n+:(`DATA_SIZE_ARB)] <= po[n];
            end
            else begin
                done <= 0;
                bramOut <= 0;
            end
        end
    end
end
always @(posedge clk  ) begin: FIRST_TIME_REG
        if(reset) begin
            jState <= 0;
        end
        else begin            
            if (state == 3'd5 && (sys_cntr_d ==(`RING_SIZE >> ((`PE_DEPTH)-1)))) begin // input data from BRAM
                jState <= ~jState;
            end
            else  begin
                jState <= jState;
            end         
       end
 
end




// ---------------------------------------------------------------- PU control

always @(posedge clk  ) begin: NT_BLOCK
    integer n;
    for(n=0; n < (`PE_NUMBER); n=n+1) begin: LOOP_1
        if(reset) begin
            NTTin[2*n+0] <= 0;
            NTTin[2*n+1] <= 0;
            MULin[n] <= 0;
        end
        else begin
        /*
            if(state == 3'd5) begin //If we're doing the multiplication with 1/N
                if(sys_cntr < (2+(`RING_SIZE >> (`PE_DEPTH+1)))) begin // should take 2 + 16 cycles to read everything and write it back with
                // 1 delay.
                    NTTin[2*n+0] <= po[2*n+0];
                    NTTin[2*n+1] <= 0;
                end
                else if(sys_cntr < (2+(`RING_SIZE >> (`PE_DEPTH)))) begin
                    NTTin[2*n+0] <= po[2*n+1];
                    NTTin[2*n+1] <= 0;
                end
                else begin //again, this is the standard operation
                    NTTin[2*n+0] <= po[2*n+0];
                    NTTin[2*n+1] <= po[2*n+1];
                end
                MULin[n] <= n_inv;
            end
            */
            if(state == 3'd5) begin //multiplication with secret key
                if (jState ==0) begin
                    if(sys_cntr < (2+(`RING_SIZE >> (`PE_DEPTH+1)))) begin // should take 2 + 16 cycles to read everything and write it back with
                    // 1 delay.
                        NTTin[2*n+0] <= 0;
                        NTTin[2*n+1] <= po[2*n+0];//0...31, 64...95, etc...
                    end
                    else if(sys_cntr < (2+(`RING_SIZE >> (`PE_DEPTH)))) begin //if less than 32+2
                        NTTin[2*n+0] <= 0;
                        NTTin[2*n+1] <= po[2*n+1];
                    end
                    else if(sys_cntr < (2+(2'd3*(`RING_SIZE >> (`PE_DEPTH+1))))) begin // should take 2 + 16 cycles to read everything and write it back with
                        // 1 delay.
                        NTTin[2*n+0] <= 0;
                        NTTin[2*n+1] <= po[2*n+0];//0...31, 64...95, etc...
                    end
                    else if(sys_cntr < (2+(`RING_SIZE >> (`PE_DEPTH-1)))) begin //if less than 32+2
                        NTTin[2*n+0] <= 0;
                        NTTin[2*n+1] <= po[2*n+1];
                    end
                    else begin //again, this is the standard operation, probably for the last 2 cycles of state 3 or something
                        NTTin[2*n+0] <= po[2*n+0];
                        NTTin[2*n+1] <= po[2*n+1];
                    end
                    MULin[n] <= secret_key[`DATA_SIZE_ARB*n+:`DATA_SIZE_ARB];
                end
                else begin
                    if(sys_cntr < (2+(`RING_SIZE >> (`PE_DEPTH+1)))) begin // should take 2 + 16 cycles to read everything and write it back with
            // 1 delay.
                        NTTin[2*n+0] <= po[2*n+1]; //BRAM1 is added, so it must be added to the plays where it won't be multiplied.
                        NTTin[2*n+1] <= po[2*n+0];//0...31, 64...95, etc...
                    end
                    else if(sys_cntr < (2+(`RING_SIZE >> (`PE_DEPTH)))) begin //if less than 32+2
                        NTTin[2*n+0] <= po[2*n+0]; //BRAM 0 is added so must go to even
                        NTTin[2*n+1] <= po[2*n+1];
                    end

                    else if(sys_cntr < (2+(2'd3*(`RING_SIZE >> (`PE_DEPTH+1))))) begin // should take 2 + 16 cycles to read everything and write it back with
                                // 1 delay.
                        NTTin[2*n+0] <= po[2*n+1]; //BRAM1 is added, so it must be added to the plays where it won't be multiplied.
                        NTTin[2*n+1] <= po[2*n+0];//0...31, 64...95, etc...
                    end
                    else if(sys_cntr < (2+(`RING_SIZE >> (`PE_DEPTH-1)))) begin //if less than 32+2
                        NTTin[2*n+0] <= po[2*n+0]; //BRAM 0 is added so must go to even
                        NTTin[2*n+1] <= po[2*n+1];
                    end
                    else begin //again, this is the standard operation 
                        NTTin[2*n+0] <= po[2*n+0];
                        NTTin[2*n+1] <= po[2*n+1];
                    end

                MULin[n] <= secret_key[`DATA_SIZE_ARB*n+:`DATA_SIZE_ARB];                                   
                end //of jState
            end// of state 5
            else begin //standard operation, mainly in state 3.
                NTTin[2*n+0] <= po[2*n+0];
                NTTin[2*n+1] <= po[2*n+1];
                MULin[n] <= to[n];
            end
        end
    end
end

// --------------------------------------------------------------------------- delays

ShiftReg #(.SHIFT(`INTMUL_DELAY+`MODRED_DELAY+`STAGE_DELAY-1),.DATA(`RING_DEPTH+4        )) sr00(clk,reset,sys_cntr,sys_cntr_d);
ShiftReg #(.SHIFT(`INTMUL_DELAY+`MODRED_DELAY+`STAGE_DELAY-1),.DATA(`RING_DEPTH-`PE_DEPTH)) sr01(clk,reset,inttlast,inttlast_d);

// ---------------------------------------------------------------------------

endmodule
