//instead of softmax function we use this module - easier to implement in hardware
//instead of computing exponentials and normalizing. simply finds the index of maximum value among numInput
//takes 10 clock cycles to find out the largest number among the outputs

module maxFinder #(parameter numInput=10,parameter inputWidth=16)( //10 is the number of neurons in the output layer
input           i_clk, //clock signal
input [(numInput*inputWidth)-1:0]   i_data, //concatenated input vector from x4_out
input           i_valid,  //signal to start comparison
output reg [31:0]o_data, // index of max value
output  reg     o_data_valid //high when result if ready
);

reg [inputWidth-1:0] maxValue; //holds the current maximum value
reg [(numInput*inputWidth)-1:0] inDataBuffer; //copy of input for iteration
integer counter; //keeps track of the current index

always @(posedge i_clk)
begin
    o_data_valid <= 1'b0;
    if(i_valid)
    begin
        maxValue <= i_data[inputWidth-1:0];
        counter <= 1;
        inDataBuffer <= i_data;
        o_data <= 0;
    end
    else if(counter == numInput)
    begin
        counter <= 0;
        o_data_valid <= 1'b1;
    end
    else if(counter != 0)
    begin
        counter <= counter + 1;
        if(inDataBuffer[counter*inputWidth+:inputWidth] > maxValue)
        begin
            maxValue <= inDataBuffer[counter*inputWidth+:inputWidth];
            o_data <= counter;
        end
    end
end

endmodule