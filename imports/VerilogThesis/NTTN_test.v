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

module NTTN_test();

parameter HP = 5;
parameter FP = (2*HP); //10

reg                       clk,reset;
reg                       load_w_ntt;
reg                       load_w_intt;
reg                       load_data_ntt;
reg                       load_data_intt;
reg                       start;
reg                       start_intt;
reg  [`DATA_SIZE_ARB-1:0] din_ntt;
reg  [`DATA_SIZE_ARB-1:0] din_intt;
wire [(`DATA_SIZE_ARB * 2*`PE_NUMBER)-1:0] bramIn;
wire                      done_ntt;
wire                      done_intt;
wire [(`DATA_SIZE_ARB * `PE_NUMBER)-1:0] bramOut_ntt;
wire [(`DATA_SIZE_ARB *`PE_NUMBER)-1:0] bramOut_intt;

// ---------------------------------------------------------------- CLK

always #HP clk = ~clk;

// ---------------------------------------------------------------- TXT data

reg [`DATA_SIZE_ARB-1:0] params    [0:7];
reg [`DATA_SIZE_ARB-1:0] w	 	   [0:( `RING_DEPTH<<((`RING_DEPTH-`PE_DEPTH-1)+`PE_DEPTH) )-1];
reg [`DATA_SIZE_ARB-1:0] winv	   [0:((((1<<(`RING_DEPTH-`PE_DEPTH))-1)+`PE_DEPTH)<<`PE_DEPTH)-1];
reg [`DATA_SIZE_ARB-1:0] ntt_pin   [0:`RING_SIZE-1];
reg [`DATA_SIZE_ARB-1:0] ntt_pout  [0:`RING_SIZE-1];
reg [`DATA_SIZE_ARB-1:0] intt_pin  [0:`RING_SIZE-1];
reg [`DATA_SIZE_ARB-1:0] intt_pout [0:`RING_SIZE-1];

initial begin
	// ntt
	$readmemh("D:/Jonas/Documents/Huiswerk/KULeuven5/VerilogThesis/edt_zcu102/edt_zcu102.srcs/sources_1/imports/VerilogThesis/test/PARAM.txt"    , params);
	$readmemh("D:/Jonas/Documents/Huiswerk/KULeuven5/VerilogThesis/edt_zcu102/edt_zcu102.srcs/sources_1/imports/VerilogThesis/test/W.txt"        , w);
	$readmemh("D:/Jonas/Documents/Huiswerk/KULeuven5/VerilogThesis/edt_zcu102/edt_zcu102.srcs/sources_1/imports/VerilogThesis/test/WINV.txt"     , winv);
	$readmemh("D:/Jonas/Documents/Huiswerk/KULeuven5/VerilogThesis/edt_zcu102/edt_zcu102.srcs/sources_1/imports/VerilogThesis/test/PYTHON_NTT_IN.txt"  , ntt_pin);
	$readmemh("D:/Jonas/Documents/Huiswerk/KULeuven5/VerilogThesis/edt_zcu102/edt_zcu102.srcs/sources_1/imports/VerilogThesis/test/PYTHON_NTT_OUT.txt" , ntt_pout);
	$readmemh("D:/Jonas/Documents/Huiswerk/KULeuven5/VerilogThesis/edt_zcu102/edt_zcu102.srcs/sources_1/imports/VerilogThesis/test/ACCUMULATOR.txt" , intt_pin);
	$readmemh("D:/Jonas/Documents/Huiswerk/KULeuven5/VerilogThesis/edt_zcu102/edt_zcu102.srcs/sources_1/imports/VerilogThesis/test/MODIFIED.txt", intt_pout);
end

// ---------------------------------------------------------------- TEST case

integer k;
integer d;

initial begin: CLK_RESET_INIT
	// clk & reset (150 cc)
	clk       = 0;
	reset     = 0;

	#200;
	reset    = 1;
	#200;
	reset    = 0;
	#100;

	#1000;
end

initial begin: LOAD_DATA_NTT
    load_w_ntt    = 0;
    load_data_ntt = 0;
    start     = 0;
    din_ntt       = 0;

    #1500;

    // load w
    load_w_ntt = 1;
    #FP;
    load_w_ntt = 0;
            // ((((1<<(`RING_DEPTH-`PE_DEPTH))-1)+`PE_DEPTH)<<`PE_DEPTH)))
	for(k=0; k<(`RING_DEPTH<< ((`RING_DEPTH-`PE_DEPTH-1)+`PE_DEPTH) ); k=k+1) begin

		din_ntt = w[k];
		#FP;
	end
	din_ntt = params[1];
	#FP;
	din_ntt = params[6];
	#FP;

	#(5*FP);



	// ---------- load data (ntt)
	load_data_ntt = 1;
    #FP;
    load_data_ntt = 0;

	for(k=0; k<(`RING_SIZE); k=k+1) begin
		din_ntt = ntt_pin[k];
		#FP;
	end

	#(5*FP);

	// start (ntt)
	start = 1;
	#FP;
	start = 0;
	#FP;

	while(done_ntt == 0)
		#FP;
	#FP;

	#(FP*(`RING_SIZE+10));

end

initial begin: LOAD_DATA_INTT
    load_w_intt    = 0;
    load_data_intt = 0;
    start_intt= 0;
    din_intt       = 0;

    #1500;
    //wait before running the other so you have time to read both out
    #(`RING_SIZE >> (`PE_DEPTH))

    // load w
    load_w_intt = 1;
    #FP;
    load_w_intt = 0;
            // ((((1<<(`RING_DEPTH-`PE_DEPTH))-1)+`PE_DEPTH)<<`PE_DEPTH)))
	for(d=0; d<((((1<<(`RING_DEPTH-`PE_DEPTH))-1)+`PE_DEPTH)<<`PE_DEPTH); d=d+1) begin
	
		din_intt = 0;
		#FP;
	end
	for(d=0; d<((((1<<(`RING_DEPTH-`PE_DEPTH))-1)+`PE_DEPTH)<<`PE_DEPTH); d=d+1) begin
		din_intt = winv[d];
		#FP;
	end
	din_intt = params[1];
	#FP;
	din_intt = params[6];
	#FP;

	#(5*FP);



	// ---------- load data (ntt)
	load_data_intt = 1;
    #FP;
    load_data_intt = 0;

	for(d=0; d<(`RING_SIZE); d=d+1) begin
		din_intt = intt_pin[d];
		#FP;
	end

	#(5*FP);

	// start (ntt)
	start_intt = 1;
	#FP;
	start_intt = 0;
	#FP;

	while(done_intt == 0)
		#FP;
	#FP;

	#(FP*(`RING_SIZE+10));

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
	while(done_intt == 0)
		#FP;
	#FP;

	// Store output (intt)
	for(m=0; m<(`RING_SIZE >> (`PE_DEPTH)); m=m+1) begin
       for(n=0; n<(`PE_NUMBER); n=n+1) begin
          intt_nout[(`PE_NUMBER)*m+n] = bramOut_intt[(`DATA_SIZE_ARB)*n+:(`DATA_SIZE_ARB)];
        end
        #FP;
    end



    	// wait result (ntt)
    while(done_ntt == 0)
        #FP;
    #FP;

    // Store output (ntt)
    for(m=0; m<(`RING_SIZE >> (`PE_DEPTH)); m=m+1) begin
       for(n=0; n<(`PE_NUMBER); n=n+1) begin
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
	end

	// Compare output with expected result (intt)
	for(m=0; m<(`RING_SIZE); m=m+1) begin
		if(intt_nout[m] == intt_pout[m]) begin
			ei = ei+1;
		end
		else begin
		    $display("INTT: Index-%d -- Calculated:%d, Expected:%d",m,intt_nout[m],intt_pout[m]);
		end
	end

	#FP;

	if(en == (`RING_SIZE))
		$display("NTT:  Correct");
	else
		$display("NTT:  Incorrect");

	if(ei == (`RING_SIZE))
		$display("INTT: Correct");
	else
		$display("INTT: Incorrect");

	$stop();

end

// ---------------------------------------------------------------- UUT

NTTN uut    (clk,reset,
             load_w_ntt,
             load_data_ntt,
             start,
             din_ntt,
             bramIn,
             done_ntt,
             bramOut_ntt);
             
INTT uut2    (clk,reset,
                          load_bram,
                          load_data_intt,
                          start_intt,
                          din_intt,
                          bramIn,
                          write_addr_intt,
                          done_intt,
                          bramOut_intt);

endmodule
