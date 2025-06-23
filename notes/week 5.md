learned about the axi lite interface. its for the processor to read write to the neural network. we assign certain addresses to which the processor can read and write which is mapped to registers in our network. 
designed and commented the axi_lite_wrapper.
//AXI4-Lite protocol
//it contains 8 32bit memory mapped registers accessed via AXI
/*
Registers are addressed based on the AXI address. 
Using axi_awaddr[ADDR_LSB+OPT_MEM_ADDR_BITS:ADDR_LSB] 
(i.e., 3-bit register index):
| Address (Offset) | Register      | Read/Write | Description                             |
| ---------------- | ------------- | ---------- | --------------------------------------- |
| 0x00             | `weightReg`   | W          | Write weight value (32-bit)             |
| 0x04             | `biasReg`     | W          | Write bias value                        |
| 0x08             | `outputReg`   | R          | Final output from the neuron            |
| 0x0C             | `layerReg`    | W          | Specify the layer number of this neuron |
| 0x10             | `neuronReg`   | W          | Specify the neuron ID                   |
| 0x14             | `axi_rd_data` | R          | Data from external source (AXI read)    |
| 0x18             | `statReg`     | R          | Status register (set when output valid) |
| 0x1C             | `controlReg`  | W/R        | Control bits (e.g., soft reset = bit 0) |
*/


also connected the final output of the neural network to a register. 


### Verification of tut4
all the memory intialization files are ready, 4 layers coded, axi wrapped, hardmax finder. the whole hardware designed.

created project name tut4-verification. for zynq-7000 series.

mnist data set 28x28 input pixels. each pixel is greyscale so it ranges from 0 to 255. 

added top_sim.v testbench. reads one particular test image and injects it into the neural network. through our axi stream interface. 

