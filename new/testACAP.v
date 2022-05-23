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

module testACAP();

parameter HP = 5;
parameter FP = (2*HP); //10

reg                       clk,resetn;

reg                       write_enable_bram;
reg                       start_addToACAP;
reg   [`RING_DEPTH+1-1:0]    write_addr_input;
reg  [`DATA_SIZE_ARB-1:0] data_in;
wire                      done;
reg [`RING_DEPTH+1-1:0] read_out;
wire [`DATA_SIZE_ARB-1:0] data_out;
reg [`DATA_SIZE_ARB-1:0] data_a;
reg                      load_a;
reg   [`RING_DEPTH-1:0]    write_addr_a;
reg [`DATA_SIZE_ARB*`PE_NUMBER*`NTT_NUMBER-1:0] secret_key;
wire [`SECRET_ADDR_WIDTH-1:0] secret_addr;
wire [`SECRET_ADDR_WIDTH-1:0] secret_addr_d;

// ---------------------------------------------------------------- CLK

always #HP clk = ~clk;

// ---------------------------------------------------------------- TXT data
             
AddToACAP_sim accumulator    (clk,resetn,
             write_enable_bram,
             write_addr_input,
             data_in,
             load_a,
             data_a,
             write_addr_a,
             start_addToACAP,
             secret_key,
             read_out,
             done,
             data_out,
             secret_addr);
reg [`DATA_SIZE_ARB-1:0] params    [0:7];
//reg [`DATA_SIZE_ARB-1:0] ntt_pin   [0:`RING_SIZE-1];
//reg [`DATA_SIZE_ARB-1:0] ntt_pout  [0:`RING_SIZE-1];
reg [`DATA_SIZE_ARB-1:0] acc_in  [0:(`RING_SIZE<<1)-1];
reg [`A_WIDTH-1:0] avector  [0:(`LWE_SIZE*`D_R)-1];
//reg [`DATA_SIZE_ARB-1:0] result_out [0:(`RING_SIZE<<1)+1];
reg [`DATA_SIZE_ARB-1:0] result [0:(`RING_SIZE<<1)-1];
reg [`DATA_SIZE_ARB*`PE_NUMBER*`NTT_NUMBER-1:0] secret [0:`SECRET_KEY_SIZE-1];
initial begin
	// ntt

	//$readmemh("D:/Jonas/Documents/Huiswerk/KULeuven5/VerilogThesis/edt_zcu102/edt_zcu102.srcs/sources_1/imports/VerilogThesis/test/PYTHON_NTT_IN.txt"  , ntt_pin);
	//$readmemh("D:/Jonas/Documents/Huiswerk/KULeuven5/VerilogThesis/edt_zcu102/edt_zcu102.srcs/sources_1/imports/VerilogThesis/test/PYTHON_NTT_OUT.txt" , ntt_pout);
	$readmemh("D:/Jonas/Documents/Huiswerk/KULeuven5/VerilogThesis/edt_zcu102/edt_zcu102.srcs/sources_1/imports/VerilogThesis/test/STARTACCUMULATOR.txt" , acc_in);
	//$readmemh("D:/Jonas/Documents/Huiswerk/KULeuven5/VerilogThesis/edt_zcu102/edt_zcu102.srcs/sources_1/imports/VerilogThesis/test/RESULTINTT.txt", result_out);
	$readmemh("D:/Jonas/Documents/Huiswerk/KULeuven5/VerilogThesis/edt_zcu102/edt_zcu102.srcs/sources_1/imports/VerilogThesis/test/RESULTACC.txt", result);
	$readmemb("D:/Jonas/Documents/Huiswerk/KULeuven5/VerilogThesis/edt_zcu102/edt_zcu102.srcs/sources_1/imports/VerilogThesis/test/FULLSECRET.txt", secret);
	$readmemh("D:/Jonas/Documents/Huiswerk/KULeuven5/VerilogThesis/edt_zcu102/edt_zcu102.srcs/sources_1/imports/VerilogThesis/test/AVECTOR.txt", avector);
end

// ---------------------------------------------------------------- TEST case

integer k;
integer d;
always @(posedge clk) begin
    if (~resetn) begin
        secret_key <=0;
    end
    else begin
        secret_key <= secret[secret_addr_d]; //actually, we are allowed to delay secret_key by 2 clock cycles.
    end
end
ShiftReg #(.SHIFT(1),.DATA(`SECRET_ADDR_WIDTH)) address_shift(clk, ~resetn, secret_addr, secret_addr_d);


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
    write_enable_bram = 0;
    start_addToACAP     = 0;
    write_addr_input = 0;

    #1500;

    // load w
    write_enable_bram = 1;
    #FP;
            // ((((1<<(`RING_DEPTH-`PE_DEPTH))-1)+`PE_DEPTH)<<`PE_DEPTH)))
	for(k=0; k<(`RING_SIZE<<1); k=k+1) begin

		data_in = acc_in[k];
		write_addr_input = k;
		//and write the a_vector
		#FP;
	end
    write_addr_input = 0;
write_enable_bram = 0;
	#(5*FP);
    load_a = 1;
    for(k=0; k<(`LWE_SIZE*`D_R); k=k+1) begin
    
            data_a = avector[k];
            write_addr_a = k;
            //and write the a_vector
            #FP;
        end

    load_a = 0;
	#(5*FP);

	// start (ntt)
	start_addToACAP = 1;
	#FP;
	start_addToACAP = 0;
	#FP;

	while(done == 0)
		#FP;
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
	read_out = 0;
    #1500;



	// wait result (intt)
	while(done == 0)
		#FP;
	
	#FP;

	// Store output (intt)
	for(m=0; m<(`RING_SIZE<<1); m=m+1) begin
        read_out = read_out + 1;
        intt_nout[m] = data_out;

        #FP;
    end


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
		if(intt_nout[m] == result[m]) begin //compare with ntt_pout
			ei = ei+1;
		end
		else begin
		    $display("INTT: Index-%d -- Calculated:%d, Expected:%d",m,intt_nout[m],result[m]);
		end
	end

	#FP;
/*
	if(en == (`RING_SIZE))
		$display("NTT:  Correct");
	else
		$display("NTT:  Incorrect");*/

	if(ei == (`RING_SIZE))
		$display("INTT: Correct");
	else
		$display("INTT: Incorrect");

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
