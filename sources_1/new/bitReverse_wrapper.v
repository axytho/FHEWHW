`timescale 1ns / 1ps

// TX_SIZE is defined in params.vh
// It is set to 1024 for 1024-bit wide data transfers between Arm and FPGA

module bitReverse_wrapper #(parameter TX_SIZE = 32)(
    // The clock and active low reset
    input                clk,
    input                reset,
    output               done_to_pin

    );

    ////////////// - State Machine 
    
    /// - State Machine Parameters

    
    
    reg random_input;
    

    reg [3:0] cycle;
    reg [`DATA_SIZE_ARB*`PE_NUMBER-1:0] data_in; //data comes in in 32 bit chunks
    wire [`PE_NUMBER*`PE_NUMBER-1:0] data_out;
    reg [`PE_NUMBER*`PE_NUMBER-1:0] data_out_plus_one;
	

     assign done_to_pin = data_out_plus_one[515] & data_out_plus_one[26] & data_out_plus_one[174];


	

     always @(posedge clk)
     begin
         if(reset) begin
                  data_out_plus_one <= 0;
                  data_in <= 0;
                  cycle <= 0;
         end
         else begin
            data_out_plus_one <= data_out + 1;
            data_in <= data_in + 1'b1;//1024'hfdfeafeaffafefafeaefeafeffeffdfecddefefeefefeffeafeafafeaffafefafeaefeafeffeffdfe2cdf6afecfeffefefef3eefefeffeafeafafeaffafefafeaefeafeffeffefefeefefeffeafeafafea3fafefafeaefeafeffeffdfecdf6afecfeffefefefeefefeffeafeafafeaffafefafeaefeaffafefafeaefeafeffef;
            cycle <= cycle+1;
         end


                 

     end
   

    bitReverse reverser    (clk,reset,
                               cycle,
                               data_in,
                               data_out);



endmodule
