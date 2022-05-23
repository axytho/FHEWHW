//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 04/11/2021 09:35:52 PM
// Design Name: 
// Module Name: bitReverse_test
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

module bitReverse_test( );
parameter HP = 5;
parameter FP = (2*HP); //10

reg                       clk,reset;
reg [`DATA_SIZE_ARB*`PE_NUMBER-1:0] data_in;
wire [`DATA_SIZE_ARB*`PE_NUMBER-1:0] data_out;
reg [4:0] cycle;
wire [3:0] sum;
integer k;
integer n;
assign sum = k[4:1] + n[3:0];
always #HP clk = ~clk;


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
    
    initial begin: LOAD_DATA
    #2000;
     #FP;
     for (n=0; n<32; n=n+1) begin
        for(k=0; k<32; k=k+1) begin
            cycle = n;                                  // PE[0] {readaddress[3:0]} PE[5:1] 
            data_in[(`DATA_SIZE_ARB*k)+:`DATA_SIZE_ARB] = {n[4], k[4:1] + n[3:0], k[4:0]};//remember k = PE[5:1]
        end// output will give us the first 4 bits and last bit of which PE to take
        #FP; //total PE is then data_out[5:1], cycle//16, data_out[0]
        
        
     end
    #100;
    $stop();
    end
    
bitReverse uut(
     clk, reset,
    cycle[3:0],
    data_in, //data comes in in 32 bit chunks
    data_out
        );  
    
    
    
    
    
    
    
endmodule



