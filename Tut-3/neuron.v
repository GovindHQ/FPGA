`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 13.11.2018 17:11:05
// Design Name: 
// Module Name: neuron
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
//`define DEBUG
`include "include.v"

module neuron #(parameter layerNo=0,
neuronNo=0, //unique id for this neuron within a multi layer network
numWeight=784,//number of inputs(weights) per neuron (28 x 28 = 784 for MNIST)
dataWidth=16,//bit-width for each data work
sigmoidSize=5,//address bits into a small ROM if using a sigmoid //sigcontent should have 2^5 entries which is 32
weightIntWidth=1, //integer width for ReLu scaling
actType="sigmoid", //chosse at generate time 
biasFile="b_1_15.mif",//file names for $readmemb if using pretrained
weightFile="w_1_15.mif"
)

( //ports
    
	input           clk,
    input           rst, 
    input [dataWidth-1:0]    myinput,input           myinputValid,  // sreaming input data sample and its valid strobe
	
	//handshake and 32 bits value to load weights and bias to on chip memory
	input           weightValid, 
    input           biasValid,
    input [31:0]    weightValue,
    input [31:0]    biasValue,
	
    input [31:0]    config_layer_num, input [31:0]    config_neuron_num, //used during weight/bias loading to route values to the correct neuron
    output[dataWidth-1:0]    out, output reg      outvalid   //final activation value outpt and its valid strobe
    );
    
    parameter addressWidth = $clog2(numWeight); //is the minimum of the number of bits needed to index numWeight addresses 
    
    reg         wen; //write enable for weight memory
    wire        ren; //read enable for wright memory tied to myinputValid
    reg [addressWidth-1:0] w_addr; //write address to store incoming weights
    reg [addressWidth:0]   r_addr;//read address has to reach until numWeight hence width is 1 bit more
    reg [dataWidth-1:0]  w_in;//data bus to write new weights into mem
    wire [dataWidth-1:0] w_out;// output from weight memory after a read
    reg [2*dataWidth-1:0]  mul; 
    reg [2*dataWidth-1:0]  sum;
    reg [2*dataWidth-1:0]  bias; //extended bias value, left shifted by datawidth bits
    reg [31:0]    biasReg[0:0]; //temporary storage arrya when using the pretrained option
    reg         weight_valid;
    reg         mult_valid;
    wire        mux_valid;
    reg         sigValid; 
    wire [2*dataWidth:0] comboAdd;
    wire [2*dataWidth:0] BiasAdd;
    reg  [dataWidth-1:0] myinputd;
    reg muxValid_d;
    reg muxValid_f;
    reg addr=0;
	
	
   //Loading weight values into the memory
    always @(posedge clk)
    begin
        if(rst)
        begin
            w_addr <= {addressWidth{1'b1}}; //sets all the weight value bits 1, so that plus 1 will make it zero for the first value to be stored
            wen <=0;
        end
        else if(weightValid & (config_layer_num==layerNo) & (config_neuron_num==neuronNo)) //each neuron has an unique identification
        begin
            w_in <= weightValue;
            w_addr <= w_addr + 1;  
            wen <= 1;
        end
        else
            wen <= 0;
    end

    assign mux_valid = mult_valid;
    assign comboAdd = mul + sum;
    assign BiasAdd = bias + sum;
    assign ren = myinputValid;
    
    `ifdef pretrained // if already pretrained it will be loaded from a file. pretrained work is from include.v 
        initial
        begin
            $readmemb(biasFile,biasReg); //bias is loaded from data file once and constantly driven
        end
        always @(posedge clk) 
        begin
            bias <= {biasReg[addr][dataWidth-1:0],{dataWidth{1'b0}}};
        end
    `else
        always @(posedge clk)//otherwise bias is loaded on the fly when biasValid matches the neuron
        begin
            if(biasValid & (config_layer_num==layerNo) & (config_neuron_num==neuronNo))
            begin
                bias <= {biasValue[dataWidth-1:0],{dataWidth{1'b0}}};
            end
        end
    `endif
    
    
    always @(posedge clk)
    begin
        if(rst|outvalid)
            r_addr <= 0;
        else if(myinputValid)
            r_addr <= r_addr + 1;
    end
    
    always @(posedge clk) //input multiplied by the weight read
    begin
        mul  <= $signed(myinputd) * $signed(w_out); //twos complement representation so we use $signed
    end
    
    
    always @(posedge clk)
    begin
        if(rst|outvalid)
            sum <= 0;
        else if((r_addr == numWeight) & muxValid_f)
        begin
            if(!bias[2*dataWidth-1] &!sum[2*dataWidth-1] & BiasAdd[2*dataWidth-1]) //If bias and sum are positive and after adding bias to sum, if sign bit becomes 1, saturate
            begin
                sum[2*dataWidth-1] <= 1'b0;
                sum[2*dataWidth-2:0] <= {2*dataWidth-1{1'b1}};
            end
            else if(bias[2*dataWidth-1] & sum[2*dataWidth-1] &  !BiasAdd[2*dataWidth-1]) //If bias and sum are negative and after addition if sign bit is 0, saturate
            begin
                sum[2*dataWidth-1] <= 1'b1;
                sum[2*dataWidth-2:0] <= {2*dataWidth-1{1'b0}};
            end
            else
                sum <= BiasAdd; 
        end
        else if(mux_valid)
        begin
            if(!mul[2*dataWidth-1] & !sum[2*dataWidth-1] & comboAdd[2*dataWidth-1])
            begin
                sum[2*dataWidth-1] <= 1'b0;
                sum[2*dataWidth-2:0] <= {2*dataWidth-1{1'b1}};
            end
            else if(mul[2*dataWidth-1] & sum[2*dataWidth-1] & !comboAdd[2*dataWidth-1])
            begin
                sum[2*dataWidth-1] <= 1'b1;
                sum[2*dataWidth-2:0] <= {2*dataWidth-1{1'b0}};
            end
            else
                sum <= comboAdd; 
        end
    end
    
    always @(posedge clk)
    begin
        myinputd <= myinput; //incoming input is delayed by one clock here so as to match weight reading delay
        weight_valid <= myinputValid;
        mult_valid <= weight_valid;
        sigValid <= ((r_addr == numWeight) & muxValid_f) ? 1'b1 : 1'b0;
        outvalid <= sigValid;
        muxValid_d <= mux_valid;
        muxValid_f <= !mux_valid & muxValid_d;
    end
    
    
    //Instantiation of Memory for Weights
    Weight_Memory #(.numWeight(numWeight),.neuronNo(neuronNo),.layerNo(layerNo),.addressWidth(addressWidth),.dataWidth(dataWidth),.weightFile(weightFile)) WM(
        .clk(clk),
        .wen(wen),
        .ren(ren),
        .wadd(w_addr),
        .radd(r_addr),
        .win(w_in),
        .wout(w_out)
    );
    
    generate
        if(actType == "sigmoid")
        begin:siginst
        //Instantiation of ROM for sigmoid
            Sig_ROM #(.inWidth(sigmoidSize),.dataWidth(dataWidth)) s1(
            .clk(clk),
            .x(sum[2*dataWidth-1-:sigmoidSize]),
            .out(out)
        );
        end
        else
        begin:ReLUinst
            ReLU #(.dataWidth(dataWidth),.weightIntWidth(weightIntWidth)) s1 (
            .clk(clk),
            .x(sum),
            .out(out)
        );
        end
    endgenerate

    `ifdef DEBUG
    always @(posedge clk)
    begin
        if(outvalid)
            $display(neuronNo,,,,"%b",out);
    end
    `endif
endmodule