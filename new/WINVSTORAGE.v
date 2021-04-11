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

`timescale 1ns / 1ps

module WINVSTORAGE #(parameter DLEN = 32, HLEN = 9, PE_NO=0)
           (input                 clk,
            input      [HLEN-1:0] raddr,
            output reg [DLEN-1:0] dout);
// bram
// if you want storage for the secret key, write "distributed" see the BRAM help files.
// try synthesizing the entire secret key storage.


(* rom_style="distributed" *) reg [DLEN-1:0] blockram [(((1<<(`RING_DEPTH-`PE_DEPTH))-1)+`PE_DEPTH)-1:0];//this is the default
initial begin
//NOT SO FAST, NEEDS TO BE DONE SEPERATELY BECAUSE SEPERATE BRAMS
// SO YOURE GOING TO HAVE TO MAKE THE W FILES INDIVIDUALLY IF YOU WANT TO DO THIS

 $readmemh("D:/Jonas/Documents/Huiswerk/KULeuven5/VerilogThesis/edt_zcu102/edt_zcu102.srcs/sources_1/imports/VerilogThesis/test/WINV.txt"   
        ,  blockram,  (((1<<(`RING_DEPTH-`PE_DEPTH))-1)+`PE_DEPTH)*PE_NO, (((1<<(`RING_DEPTH-`PE_DEPTH))-1)+`PE_DEPTH)*(PE_NO + 1) - 1);
        //(1<<HLEN)-1
        //((((1<<(`RING_DEPTH-`PE_DEPTH))-1)+`PE_DEPTH)<<`PE_DEPTH)-1
end


// read operation
always @(posedge clk) begin
    dout <= blockram[raddr];
end

endmodule
