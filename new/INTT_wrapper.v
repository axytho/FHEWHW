`timescale 1ns / 1ps

// TX_SIZE is defined in params.vh
// It is set to 1024 for 1024-bit wide data transfers between Arm and FPGA

module INTT_wrapper #(parameter TX_SIZE = 32)(
    // The clock and active low reset
    input                clk,
    input                reset,
    output               done_to_pin

    );

    ////////////// - State Machine 
    
    /// - State Machine Parameters

    
    
    reg random_input;
    
    reg                       load_w_intt;
    reg                       load_data_intt;
    reg                       start_intt;
    reg  [`DATA_SIZE_ARB-1:0] din_intt;
    wire [(`DATA_SIZE_ARB * 2*`PE_NUMBER)-1:0] bramIn;
    wire                      done_intt;
    wire [(`DATA_SIZE_ARB * 2*`PE_NUMBER)-1:0] bramOut_intt;
    reg [(`DATA_SIZE_ARB * 2*`PE_NUMBER)-1:0] outputForSynth;
	
     assign done_to_pin = done_intt & outputForSynth[24*3];


	

     always @(posedge clk)
     begin
         if(reset) begin
                  din_intt <= 0;
                  load_w_intt <= 1'b0;
                  start_intt <= 1'b0;
                  outputForSynth <= 0;
         end
         else begin
            din_intt <= 27'hf2fffff;
             load_w_intt <= 1'b0;
            start_intt <= 1'b1;
            outputForSynth <= bramOut_intt;
         end


                 

     end
   

    INTT uut2    (clk,reset,
                               load_w_intt,
                               load_data_intt,
                               start_intt,
                               din_intt,
                               bramIn,
                               done_intt,
                               bramOut_intt);



endmodule
