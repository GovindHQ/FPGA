`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 11.02.2019 18:36:19
// Design Name: 
// Module Name: Sig_ROM
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


    module Sig_ROM #(parameter inWidth=10, dataWidth=16) (
    input           clk,
    input   [inWidth-1:0]   x,
    output  [dataWidth-1:0]  out
    );
    
    reg [dataWidth-1:0] mem [2**inWidth-1:0]; //this is where we will store the precalculated value
    reg [inWidth-1:0] y;
	
	initial
	begin
		$readmemb("sigContent.mif",mem); //loading precalculated value to the memory we made (LUT)
	end
    
    always @(posedge clk)
    begin
        if($signed(x) >= 0)
            y <= x+(2**(inWidth-1));//y is used as the index for reading and not x. where the largest number possible with inWidth is added
        else 
            y <= x-(2**(inWidth-1));      
    end
    
    assign out = mem[y]; // here distributed ram is used since the depth of the sigmoid ram is only 32. since the smallest block ram we can use is 18kilo bit. we dont have to use that here so we use combinational assignment.
    
endmodule
