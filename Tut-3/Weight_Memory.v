`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 11.02.2019 17:25:12
// Design Name: 
// Module Name: Weight_Memory
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
`include "include.v"

module Weight_Memory #(parameter numWeight = 3, neuronNo=5,layerNo=1,addressWidth=10,dataWidth=16,weightFile="w_1_15.mif") 
    ( 
    input clk,
    input wen,
    input ren,
    input [addressWidth-1:0] wadd,
    input [addressWidth-1:0] radd,
    input [dataWidth-1:0] win,
    output reg [dataWidth-1:0] wout);
    
    reg [dataWidth-1:0] mem [numWeight-1:0];

    `ifdef pretrained
        initial
		begin
	        $readmemb(weightFile, mem); //if already pretrained it will be loaded from a file. pretrained work is from include.v 
	    end
	`else
		always @(posedge clk) // here its sequential circuit, if i use combinational then vivado wont use blockram. 1 clock read latency is there. in combination it will use distributed ram
		
		begin
			if (wen)
			begin
				mem[wadd] <= win; // or else load from win to memory
			end
		end 
    `endif
    
    always @(posedge clk)//sequential - one clock read latency - therefore it will use block ram. if we use comb then vivado will use distributed ram
    begin
        if (ren)
        begin
            wout <= mem[radd];
        end
    end 
endmodule