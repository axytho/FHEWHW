/*
Copyright 2020, Ahmet Can Mert <ahmetcanmert@sabanciuniv.edu>

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

module AddressGenerator (input                                       clk,reset,
                         input                                       start,
                         output reg [`RING_DEPTH-`PE_DEPTH+1:0]      raddr0,//7 bits of adressing
                         output reg [`RING_DEPTH-`PE_DEPTH+1:0]      waddr0,waddr1,//7 bits of adressing
                         output reg                                  wen0  ,wen1  ,
                         output reg                                  brsel0,brsel1,
                         output reg                                  brselen0,brselen1,
                         output reg [2*`PE_NUMBER*(`PE_DEPTH+1)-1:0] brscramble0,//2*32*6 bits of adressing
                         output reg [`RING_DEPTH-`PE_DEPTH+2:0]      raddr_tw,
                         output reg [4:0]                            stage_count,
                         output reg                                  ntt_finished);
// ---------------------------------------------------------------------------
// Control signals
reg [4:0] c_stage_limit;
reg [`RING_DEPTH-`PE_DEPTH:0]   c_loop_limit;
reg [`RING_DEPTH-`PE_DEPTH+2:0] c_tw_limit;

reg [4:0] c_stage;
reg [`RING_DEPTH-`PE_DEPTH:0]   c_loop;
reg [`RING_DEPTH-`PE_DEPTH+2:0] c_tw;

reg [8:0] c_wait_limit;
reg [8:0] c_wait;

reg [`RING_DEPTH-`PE_DEPTH-1:0]     raddr;
reg [1:0]                           raddr_m;

reg [`RING_DEPTH-`PE_DEPTH-1:0]      waddre,waddro;
reg [1:0]                            waddr_m;

reg                                  wen;
reg                                  brsel;
reg                                  brselen;
reg                                  finished;
reg [2*`PE_NUMBER*(`PE_DEPTH+1)-1:0] brscramble;

// ---------------------------------------------------------------------------
// FSM
reg [1:0] state;
// 0 --> IDLE
// 1 --> NTT
// 2 --> NTT (WAIT between stages)

always @(posedge clk  ) begin
    if(reset)
        state <= 0;
    else begin
        case(state)
        2'd0: begin
            state <= (start) ? 1 : 0;
        end
        2'd1: begin
            state <= (c_loop == c_loop_limit) ? 2 : 1;
        end
        2'd2: begin
            if((c_stage == c_stage_limit) && (c_wait == c_wait_limit)) // operation is finished
                state <= 0;
            else if(c_wait == c_wait_limit)                            // to next NTT stage
                state <= 1;
            else                                                       // wait
                state <= 2;
        end
        default: state <= 0;
        endcase
    end
end

// --------------------------------------------------------------------------- WAIT OPERATION (15 CYCLES)

always @(posedge clk  ) begin
    if(reset) begin
        c_wait_limit <= 0;
        c_wait       <= 0;
    end
    else begin
        c_wait_limit <= (start) ? 8'd15 : c_wait_limit;

        if(state == 2'd2)
            c_wait <= (c_wait < c_wait_limit) ? (c_wait + 1) : 0;
        else
            c_wait <= 0;
    end
end

// --------------------------------------------------------------------------- c_stage & c_loop 
// simply keep the limits equal to 9 for depth and 15 for 32 PE's or 1 for N=8 (i.e. 2 loops)
// with 2 PE's or 3 (i.e. 4 loops) for N=8 with 1 PE.

always @(posedge clk  ) begin
    if(reset) begin
        c_stage_limit <= 0;
        c_loop_limit  <= 0;
    end
    else begin
        if(start) begin
            c_stage_limit <= (`RING_DEPTH-1);
            c_loop_limit  <= ((`RING_SIZE >> (`PE_DEPTH+1))-1);
        end
        else begin
            c_stage_limit <= c_stage_limit;
            c_loop_limit  <= c_loop_limit;
        end
    end
end

always @(posedge clk  ) begin
    if(reset) begin
        c_stage       <= 0;
        c_loop        <= 0;
    end
    else begin
        if(start) begin
            c_stage <= 0;
            c_loop  <= 0;
        end
        else begin
            // ---------------------------- c_stage
            if((state == 2'd2) && (c_wait == c_wait_limit) && (c_stage == c_stage_limit)) // reset stage (total reset of everything because NTT is done)
                c_stage <= 0;
            else if((state == 2'd2) && (c_wait == c_wait_limit)) //once we're done waiting, advance to the next stage
                c_stage <= c_stage + 1;
            else
                c_stage <= c_stage;

            // ---------------------------- c_loop
            if((state == 2'd2) && (c_wait == c_wait_limit)) //reset once we're done waiting for the next stage
                c_loop <= 0;
            else if((state == 2'd1) && (c_loop < c_loop_limit)) // run next part in the loop
                c_loop <= c_loop + 1;
            else
                c_loop <= c_loop;
        end
    end
end

// --------------------------------------------------------------------------- twiddle factors
// These are to be bitreversed and generated in a completely different way
// but first we check how they generate them right now with the algorithm given
wire [`RING_DEPTH-`PE_DEPTH+2:0] c_tw_temp;//5/6 bits on PE=2/1
// loop_limit is 15,
assign c_tw_temp = (c_loop_limit>>c_stage);//value = 1/3 >> by the stage (I don't quite understand why you'd take that large a size for this)
//15, 7, 3, 1, 0, 0, 0, 0, 
always @(posedge clk  ) begin
    if(reset) begin
        c_tw <= 0; //outside reset or start
    end
    else begin
        if(start) begin
            c_tw <= 0;
        end
        else begin
            if((state == 2'd1) && (c_loop != c_loop_limit)) begin//if we're currently going through the loop
                if(c_stage == 0) begin//if this is the first loop: 0, 8, 1, 9, 2, 10, 3, 11, 4, 12, 5, 13, 6, 14, 7, 15
                    if(c_loop[0] == 0)// and we're in an even cycle
                    // If 10-5-2 = 3 then we have +8 for the twiddle read adress output and -7 for odd ones
                    // The final result is mod 16, which makes senses as this is the max value of the loop (see k in python)
                        c_tw <= (((c_tw + ((1 << (`RING_DEPTH-`PE_DEPTH-2))>>c_stage))) & c_loop_limit); //c_tw += 01/10 & 01/11  i.e. c_tw += 1/2 mod loop_limit 
                    else 
                        c_tw <= (((c_tw + 1 - ((1 << (`RING_DEPTH-`PE_DEPTH-2))>>c_stage))) & c_loop_limit); // for odd values, it is c_tw += 0 or -1 mod looplim
                end
                else if(c_stage >= (`RING_DEPTH-`PE_DEPTH-1)) begin //stage_limit is RING_DEPTH-1
                    c_tw <= c_tw;// if we get to the point where 1 >= (N//2*PE) >> j or in other words 2**j >= N/(2*PE) or cstage >= (`RING_DEPTH-`PE_DEPTH-1)
                end // we do our +1 at the end of our loop anyway, so it's fine.
                else begin
                    //stage 2:
                    // 16, 20, 17, 21, 18, 22, 19,23, 16, 20, 17, 21, (repeat)
                
                    if(c_loop[0] == 0) begin//if even then:
                    //C_tw += (8 >> stage) - (2**(x-1) if the last x digits are all one with x starting at 4 and going to 0)
                    // this only happens once and it only happens at the last stage. It shouldn't actually happen when c_loop[0] ==0
                        c_tw <= c_tw + ((1 << (`RING_DEPTH-`PE_DEPTH-2))>>c_stage) // 2**(i-1)*k, the i comes from the stage
                              - (((c_loop & c_tw_temp) == c_tw_temp) ? (((c_loop & c_tw_temp)>>1)+1) : 0);
                              // so the second part of this statement is to repeat the same adresses
                    end
                    else begin//c_tw -= 7 >>stage - idem
                        c_tw <= (c_tw + 1) - ((1 << (`RING_DEPTH-`PE_DEPTH-2))>>c_stage)
                              - (((c_loop & c_tw_temp) == c_tw_temp) ? (((c_loop & c_tw_temp)>>1)+1) : 0);
                              // The reason for the second part is to ensure that the entire adressing run-over repeats itself
                              // as many times as necessary.
                    end
                end
            end
            else if((state == 2'd2) && (c_wait == c_wait_limit) && (c_stage == c_stage_limit)) // Full Reset
                c_tw <= 0;
            else if((state == 2'd2) && (c_wait == c_wait_limit)) begin // next stage
                c_tw <= c_tw+1;
            end
            else begin
                c_tw <= c_tw;
            end
        end
    end
end

// --------------------------------------------------------------------------- raddr (1 cc delayed) (DO NOT BITREVERSE)

wire [`RING_DEPTH-`PE_DEPTH-1:0] raddr_temp;
assign raddr_temp = ((`RING_DEPTH-`PE_DEPTH-1) - (c_stage+1));

always @ (posedge clk  ) begin
    if(reset) begin
        raddr   <= 0;
        raddr_m <= 0;
    end
    else begin
        if(start) begin
            raddr   <= 0;
            raddr_m <= 0;
        end
        else begin
            // ---------------------------- raddr
            if((state == 2'd2) && (c_wait == c_wait_limit))
                raddr <= 0;
            else if((state == 2'd1) && (c_loop <= c_loop_limit)) begin
                if(c_stage < (`RING_DEPTH-`PE_DEPTH-1)) begin
                    if(~c_loop[0])
                    // +1 because c_loop, + 0 most of the time until and then 4+curreent index as soon as we hit 8 and then +2,4,6,8
                    //so fist raddr =0,8,1,9,2,10,3,11
                    // then 0, 4, 1,5, 2,6,3,7, 8,12,9,13,10,14,11,15
                    // then 0,2,1,3, 4,6,5,7,...
                        raddr <= (c_loop >> 1) + ((c_loop >> (raddr_temp+1)) << raddr_temp);
                    else
                        raddr <= (1 << raddr_temp) + (c_loop >> 1) + ((c_loop >> (raddr_temp+1)) << raddr_temp);
                end
                else
                    raddr <= c_loop;
            end
            else
                raddr <= raddr;

            // ---------------------------- raddr_m
            if((state == 2'd2) && (c_wait == c_wait_limit))
                raddr_m <= {raddr_m[1],~raddr_m[0]};
            else
                raddr_m <= raddr_m;
        end
    end
end

// --------------------------------------------------------------------------- waddr (1 cc delayed) (SIMPLY BITINVERSE AND YOU'RE DONE)

wire [`RING_DEPTH-`PE_DEPTH-1:0] waddr_temp;
assign waddr_temp = ((`RING_DEPTH-`PE_DEPTH-1) - (c_stage+1));

always @ (posedge clk  ) begin
    if(reset) begin
        waddre  <= 0;
        waddro  <= 0;
        waddr_m <= 0;
    end
    else begin
        if(start) begin
            waddre  <= 0;
            waddro  <= (1 << (`RING_DEPTH-`PE_DEPTH-1));
            waddr_m <= 1;
        end
        else begin
            // ---------------------------- raddr
            if((state == 2'd2) && (c_wait == c_wait_limit)) begin
                waddre <= 0;
                waddro <= 0;
            end
            else if((state == 2'd1) && (c_loop <= c_loop_limit)) begin
                if(c_stage < (`RING_DEPTH-`PE_DEPTH-1)) begin
                 // +1 because c_loop, + 0 most of the time until and then 4+curreent index as soon as we hit 8 and then +2,4,6,8
                //so fist raddr =0,8,1,9,2,10,3,11
                // then 0, 4, 1,5, 2,6,3,7, 8,12,9,13,10,14,11,15
                // then 0,2,1,3, 4,6,5,7,...
                    waddre <= (c_loop >> 1) + ((c_loop >> (waddr_temp+1)) << waddr_temp);
                    waddro <= (c_loop >> 1) + ((c_loop >> (waddr_temp+1)) << waddr_temp) + (1 << waddr_temp);
                end
                else begin
                    waddre <= c_loop; //data selection is taken over by the scramble, and we just read stuff straight in.
                    waddro <= c_loop; // we just shift the entire BRAM from one to another, and which BRAM is taken is determined by 
                    // BRAM scramble
                end
            end
            else begin
                waddre <= waddre;
                waddro <= waddro;
            end

            // ---------------------------- raddr_m
            if((state == 2'd2) && (c_wait == c_wait_limit) && (c_stage == (c_stage_limit-1)))
                waddr_m <= 2'b10;
            else if((state == 2'd2) && (c_wait == c_wait_limit))
                waddr_m <= {waddr_m[1],~waddr_m[0]};
            else
                waddr_m <= waddr_m;
        end
    end
end

// --------------------------------------------------------------------------- wen,brsel,brselen (1 cc delayed)

always @(posedge clk  ) begin
    if(reset) begin
        wen     <= 0;
        brsel   <= 0;
        brselen <= 0;
    end
    else begin
        if(state == 2'd1) begin
            wen     <= 1;
            brsel   <= c_loop[0]; //select even or odd bram alternatingly
            brselen <= 1;// will get split into 2 signals, one which is delayed after the other
        end
        else begin
            wen     <= 0;
            brsel   <= 0;
            brselen <= 0;
        end
    end
end

// --------------------------------------------------------------------------- brscrambled

wire [`PE_DEPTH:0] brscrambled_temp;
wire [`PE_DEPTH:0] brscrambled_temp2;
wire [`PE_DEPTH:0] brscrambled_temp3;
assign brscrambled_temp  = (`PE_NUMBER >> (c_stage-(`RING_DEPTH-`PE_DEPTH-1)));// 2**5 >> (stage  - 4)
assign brscrambled_temp2 = (`PE_DEPTH - (c_stage-(`RING_DEPTH-`PE_DEPTH-1))); // 5- (stage - 4) = 9 - stage
assign brscrambled_temp3 = ((`PE_DEPTH+1) - (c_stage-(`RING_DEPTH-`PE_DEPTH-1))); // 10-stage

always @(posedge clk  ) begin: B_BLOCK
    integer n;
    for(n=0; n < (2*`PE_NUMBER); n=n+1) begin: LOOP_1 //64 BRAMS
        if(reset) begin
            brscramble[(`PE_DEPTH+1)*n+:(`PE_DEPTH+1)] <= 0;//Set the brams from 6*N:6*n+6 to zero (and since we do this for all n)
            //this is effectively a total reset, but it's nice to do because it gives us 
        end
        else begin
            if(c_stage >= (`RING_DEPTH-`PE_DEPTH-1)) begin // for all brRAM bits from 6*n to 6n+6
            // set the 6 bits of the scramble equal to
            // 0-5 : 0 + 0 + 0 + 0 = 0
            // 1-6 : 2**5 >> (stage - 4) + 0 +0+0 = 32
            // 
                brscramble[(`PE_DEPTH+1)*n+:(`PE_DEPTH+1)] <= (brscrambled_temp*n[0]) +
                                                              (((n>>1)<<1) & (brscrambled_temp-1)) +
                                                              ((n>>(brscrambled_temp2+1))<<(brscrambled_temp3)) +
                                                              ((n>>brscrambled_temp2) & 1);
            end
            else begin
                brscramble[(`PE_DEPTH+1)*n+:(`PE_DEPTH+1)] <= 0;
            end
        end
    end
end

// --------------------------------------------------------------------------- ntt_finished

always @(posedge clk  ) begin
    if(reset) begin
        finished <= 0;
    end
    else begin
        if((state == 2'd2) && (c_wait == c_wait_limit) && (c_stage == c_stage_limit))
            finished <= 1;
        else
            finished <= 0;
    end
end

// --------------------------------------------------------------------------- delays

// -------------------- read signals
wire [`RING_DEPTH-`PE_DEPTH+2:0] c_tw_w;
//ShifrtReg mainly generates a delay equal to the .SHIFT variable
ShiftReg #(.SHIFT(1),.DATA(`RING_DEPTH-`PE_DEPTH+3)) sr00(clk,reset,c_tw,c_tw_w);

always @(posedge clk  ) begin
    if(reset) begin
        raddr0   <= 0;
        raddr_tw <= 0;
    end
    else begin
        raddr0   <= {raddr_m,raddr};
        raddr_tw <= c_tw_w;
    end
end

// -------------------- write signals (waddr0/1, wen0/1, brsel0/1, brselen0/1)
// waddr0/1
wire [`RING_DEPTH-`PE_DEPTH+1:0] waddre_w,waddro_w;

ShiftReg #(.SHIFT(`INTMUL_DELAY+`MODRED_DELAY+`STAGE_DELAY  ),.DATA(`RING_DEPTH-`PE_DEPTH+2)) sr01(clk,reset,{waddr_m,waddre},waddre_w);
ShiftReg #(.SHIFT(`INTMUL_DELAY+`MODRED_DELAY+`STAGE_DELAY+1),.DATA(`RING_DEPTH-`PE_DEPTH+2)) sr02(clk,reset,{waddr_m,waddro},waddro_w);

always @(*) begin
    waddr0 = waddre_w;
    waddr1 = waddro_w;
end

// wen0/1
wire [0:0] wen0_w,wen1_w;

ShiftReg #(.SHIFT(`INTMUL_DELAY+`MODRED_DELAY+`STAGE_DELAY  ),.DATA(1)) sr03(clk,reset,wen,wen0_w);
ShiftReg #(.SHIFT(`INTMUL_DELAY+`MODRED_DELAY+`STAGE_DELAY+1),.DATA(1)) sr04(clk,reset,wen,wen1_w);

always @(*) begin
    wen0 = wen0_w;
    wen1 = wen1_w;
end

// brsel
wire [0:0] brsel0_w,brsel1_w;

ShiftReg #(.SHIFT(`INTMUL_DELAY+`MODRED_DELAY+`STAGE_DELAY  ),.DATA(1)) sr05(clk,reset,brsel,brsel0_w);
ShiftReg #(.SHIFT(`INTMUL_DELAY+`MODRED_DELAY+`STAGE_DELAY+1),.DATA(1)) sr06(clk,reset,brsel,brsel1_w);

always @(*) begin
    brsel0 = brsel0_w;
    brsel1 = brsel1_w;
end

// brselen
wire [0:0] brselen0_w,brselen1_w;

ShiftReg #(.SHIFT(`INTMUL_DELAY+`MODRED_DELAY+`STAGE_DELAY  ),.DATA(1)) sr07(clk,reset,brselen,brselen0_w);
ShiftReg #(.SHIFT(`INTMUL_DELAY+`MODRED_DELAY+`STAGE_DELAY+1),.DATA(1)) sr08(clk,reset,brselen,brselen1_w);

always @(*) begin
    brselen0 = brselen0_w;
    brselen1 = brselen1_w;
end

// stage count
wire [4:0] c_stage_w;

ShiftReg #(.SHIFT(`INTMUL_DELAY+`MODRED_DELAY+`STAGE_DELAY+1),.DATA(5)) sr09(clk,reset,c_stage,c_stage_w);

always @(*) begin
    stage_count = c_stage_w;
end

// brascambled
wire [2*`PE_NUMBER*(`PE_DEPTH+1)-1:0] brscramble_w;

ShiftReg #(.SHIFT(`INTMUL_DELAY+`MODRED_DELAY+`STAGE_DELAY),.DATA(2*`PE_NUMBER*(`PE_DEPTH+1))) sr10(clk,reset,brscramble,brscramble_w);

always @(*) begin
    brscramble0 = brscramble_w;
end

// ntt finished
wire finished_w;

ShiftReg #(.SHIFT(4),.DATA(1)) sr11(clk,reset,finished,finished_w);

always @(*) begin
    ntt_finished = finished_w;
end

endmodule
