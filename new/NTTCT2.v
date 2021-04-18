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

module NTTCT2(input 					        clk,reset,
			input      [`DATA_SIZE_ARB-1:0] q,
            input      [`DATA_SIZE_ARB-1:0] NTTin0,NTTin1,
			input      [`DATA_SIZE_ARB-1:0] MULin,
			output reg [`DATA_SIZE_ARB-1:0] ADDout,SUBout,
			output reg [`DATA_SIZE_ARB-1:0] NTToutEVEN,NTToutODD);


// first level registers
wire [`DATA_SIZE_ARB-1:0] MULin0,MULin1;
//wire [`DATA_SIZE_ARB-1:0] ADDreg;


assign MULin0 = MULin;
assign MULin1 = NTTin1;


// modular mul
wire [`DATA_SIZE_ARB-1:0] MODout;
ModMult mm(clk,reset,MULin0,MULin1,q,MODout);

wire [`DATA_SIZE_ARB-1:0] NTTin0_next;
ShiftReg #(.SHIFT(`INTMUL_DELAY + `MODRED_DELAY),.DATA(`DATA_SIZE_ARB)) unit00(clk,reset,NTTin0,NTTin0_next);

// modular add
wire        [`DATA_SIZE_ARB  :0] madd;
wire signed [`DATA_SIZE_ARB+1:0] madd_q;
wire        [`DATA_SIZE_ARB-1:0] madd_res;

assign madd     = NTTin0_next + MODout;
assign madd_q   = madd - q;
assign madd_res = (madd_q[`DATA_SIZE_ARB+1] == 1'b0) ? madd_q[`DATA_SIZE_ARB-1:0] : madd[`DATA_SIZE_ARB-1:0];

// modular sub
wire        [`DATA_SIZE_ARB  :0] msub;
wire signed [`DATA_SIZE_ARB+1:0] msub_q;
wire        [`DATA_SIZE_ARB-1:0] msub_res;

assign msub     = NTTin0_next - MODout;
assign msub_q   = msub + q;
assign msub_res = (msub[`DATA_SIZE_ARB] == 1'b0) ? msub[`DATA_SIZE_ARB-1:0] : msub_q[`DATA_SIZE_ARB-1:0];






always @(*) begin
    ADDout = madd_res;
    SUBout = msub_res;

    NTToutEVEN = madd_res;
end

// second level registers (output)
always @(posedge clk) begin
	if(reset) begin
		NTToutODD <= 0;
	end
	else begin
		NTToutODD <= SUBout;
	end
end

endmodule
