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

module testACAP_HW();

parameter HP = 5;
parameter FP = (2*HP); //10

reg                       clk,resetn;

/*reg                       write_enable_bram;
reg                       start_addToACAP;
reg   [`RING_DEPTH+1-1:0]    write_addr_input;
reg  [`DATA_SIZE_ARB-1:0] data_in;
wire                      done;*/
//reg [`RING_DEPTH+1-1:0] read_out;
//reg [`DATA_SIZE_ARB-1:0] data_a;
//reg                      load_a;
//reg   [`RING_DEPTH-1:0]    write_addr_a;
//reg [`DATA_SIZE_ARB*`PE_NUMBER*`NTT_NUMBER-1:0] secret_key;
//wire [`SECRET_ADDR_WIDTH-1:0] secret_addr;
//wire [`SECRET_ADDR_WIDTH-1:0] secret_addr_d;

// ---------------------------------------------------------------- CLK

always #HP clk = ~clk;

// ---------------------------------------------------------------- TXT data
 wire   [4-1:0]         write_enable_bram;
 wire   [32-1:0]          write_addr_interfacebram; 
 wire                      port_enable;  
  wire [32-1:0] data_in;        
 wire [32-1:0] data_out;  
AddToACAP accumulator    (clk,resetn,
             data_in,
             write_enable_bram,
             port_enable,
             write_addr_interfacebram,
             data_out);
reg [`DATA_SIZE_ARB-1:0] params    [0:7];
reg   [32-1:0]          data_in_reg;

assign data_in = data_in_reg;
//reg [`DATA_SIZE_ARB-1:0] ntt_pin   [0:`RING_SIZE-1];
//reg [`DATA_SIZE_ARB-1:0] ntt_pout  [0:`RING_SIZE-1];
//reg [`DATA_SIZE_ARB-1:0] acc_in  [0:(`RING_SIZE<<1)-1];
//reg [`A_WIDTH-1:0] avector  [0:(`LWE_SIZE*`D_R)-1];
//reg [`DATA_SIZE_ARB-1:0] result_out [0:(`RING_SIZE<<1)+1];
reg [`DATA_SIZE_ARB-1:0] result [0:(`RING_SIZE<<1)-1];
reg [32-1:0] DUALPORTBRAM [0:(`RING_SIZE<<3)-1];

//reg [`DATA_SIZE_ARB*`PE_NUMBER*`NTT_NUMBER-1:0] secret [0:`SECRET_KEY_SIZE-1];
initial begin
	// ntt

	//$readmemh("D:/Jonas/Documents/Huiswerk/KULeuven5/VerilogThesis/edt_zcu102/edt_zcu102.srcs/sources_1/imports/VerilogThesis/test/PYTHON_NTT_IN.txt"  , ntt_pin);
	//$readmemh("D:/Jonas/Documents/Huiswerk/KULeuven5/VerilogThesis/edt_zcu102/edt_zcu102.srcs/sources_1/imports/VerilogThesis/test/PYTHON_NTT_OUT.txt" , ntt_pout);
	//$readmemh("D:/Jonas/Documents/Huiswerk/KULeuven5/VerilogThesis/edt_zcu102/edt_zcu102.srcs/sources_1/imports/VerilogThesis/test/STARTACCUMULATOR.txt" , acc_in);
	//$readmemh("D:/Jonas/Documents/Huiswerk/KULeuven5/VerilogThesis/edt_zcu102/edt_zcu102.srcs/sources_1/imports/VerilogThesis/test/RESULTINTT.txt", result_out);
	$readmemh("D:/Jonas/Documents/Huiswerk/KULeuven5/VerilogThesis/edt_zcu102/edt_zcu102.srcs/sources_1/imports/VerilogThesis/test/SECRET_PRODUCT.txt", result);
	//$readmemb("D:/Jonas/Documents/Huiswerk/KULeuven5/VerilogThesis/edt_zcu102/edt_zcu102.srcs/sources_1/imports/VerilogThesis/test/FULLSECRET.txt", secret);
	//$readmemh("D:/Jonas/Documents/Huiswerk/KULeuven5/VerilogThesis/edt_zcu102/edt_zcu102.srcs/sources_1/imports/VerilogThesis/test/AVECTOR.txt", avector);
	$readmemh("D:/Jonas/Documents/Huiswerk/KULeuven5/VerilogThesis/edt_zcu102/edt_zcu102.srcs/sources_1/imports/VerilogThesis/test/DUALPORTBRAM.txt", DUALPORTBRAM);
end

// ---------------------------------------------------------------- TEST case

integer k;
integer d;
/*
always @(posedge clk) begin
    if (~resetn) begin
        secret_key <=0;
    end
    else begin
        secret_key <= secret[secret_addr_d]; //actually, we are allowed to delay secret_key by 2 clock cycles.
    end
end
ShiftReg #(.SHIFT(1),.DATA(`SECRET_ADDR_WIDTH)) address_shift(clk, ~resetn, secret_addr, secret_addr_d);*/
/*
wire [32-1:0] address;
reg outputChoice;*/
//assign address = outputChoice ? 
reg portAB;
reg [32-1:0] A_in;
reg [32-1:0] A_address;
wire [32-1:0] address;
reg enable;
assign address = portAB ? A_address : write_addr_interfacebram;
always @(posedge clk) begin
    if(write_enable_bram == 4'b1111 || enable)
        DUALPORTBRAM[address] <= portAB ? A_in : data_out ;
end

// read operation
always @(posedge clk) begin
    data_in_reg <= DUALPORTBRAM[address];
end
initial begin: CLK_RESET_INIT
	// clk & reset (150 cc)
	clk       = 0;
	resetn     = 1;

	#200;
	resetn    = 0;
	#200;
	resetn    = 1;
	#100;

	#1000;
end




initial begin: LOAD_DATA_ACC
portAB = 0;
    #1500;
    portAB = 1;
    A_in <= 32'hdeadbeef; //this is the start signal
    enable <= 1'b1;
    A_address <= 13'h1004;
    #FP;
    portAB = 0;
    A_in <= 32'hdeadbe3f; //this is not the start signal TODO: overwrite this in ACAP
    enable <= 4'b0;
    #FP;
end



// ---------------------------------------------------------------- TEST control

reg [`DATA_SIZE_ARB-1:0] ntt_nout  [0:`RING_SIZE-1];
reg [`DATA_SIZE_ARB-1:0] intt_nout [0:`RING_SIZE-1];

integer m;
integer n;
integer en,ei;

initial begin: CHECK_RESULT
	en = 0;
	ei = 0;
	
    #1500;

    

	// wait result (intt)
	#1200000; //900*6 4
	portAB = 1;
	A_address <= 13'h1789;
	#FP;

	// Store output (intt)
    while(~(data_in_reg == 32'hd01ecafe))
        #FP;
     #FP;

    
/*
    	// wait result (ntt)
    while(done_ntt == 0)
        #FP;
    #FP;

    // Store output (ntt)
    for(m=0; m<(`RING_SIZE >> (`PE_DEPTH+1)); m=m+1) begin
       for(n=0; n<(`PE_NUMBER << 1); n=n+1) begin
          ntt_nout[(`PE_NUMBER)*m+n] = bramOut_ntt[(`DATA_SIZE_ARB)*n+:(`DATA_SIZE_ARB)];
        end
        #FP;
    end

    #FP;
	// Compare output with expected result (ntt)
	for(m=0; m<(`RING_SIZE); m=m+1) begin
		if(ntt_nout[m] == ntt_pout[m]) begin
			en = en+1;
		end
		else begin
		    $display("NTT:  Index-%d -- Calculated:%d, Expected:%d",m,ntt_nout[m],ntt_pout[m]);
		end
	end */

	// Compare output with expected result (intt)
	for(m=0; m<(`RING_SIZE<<1); m=m+1) begin
	   A_address <= m+13'h1800;
	   #FP;
		if(data_in_reg == result[m]) begin //compare with ntt_pout
			ei = ei+1;
		end
		else begin
		    $display("INTT: Index-%d -- Calculated:%d, Expected:%d",m,data_in_reg,result[m]);
		end
	end

	#FP;
/*
	if(en == (`RING_SIZE))
		$display("NTT:  Correct");
	else
		$display("NTT:  Incorrect");*/

	if(ei == (`RING_SIZE<<1))
		$display("AddToACAP: Correct");
	else
		$display("AddToACAP: Incorrect");

	$stop();

end

// ---------------------------------------------------------------- UUT

/*NTTN uut    (clk,reset,
             load_w_ntt,
             load_data_ntt,
             start,
             din_ntt,
             bramIn,
             done_ntt,
             bramOut_ntt);*/


endmodule
