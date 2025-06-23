initial run: for direct mapped cache
FF : 2443
LUT : 1354
MUXFX : 453
IO : 312
CLK : 12
Sim simulation ran for 1000ns
launch_simulation: Time (s): cpu = 00:00:10 ; elapsed = 00:00:06 . Memory (MB): peak = 10097.316 ; gain = 6.008 ; free physical = 1583 ; free virtual = 9636

	using brams using directive instead of luts for larger memory than 1kb


pipelining: three stages:
1. s1 address decode and tag read - latch cpu_addr, extract Tag/Index/Offset
2. s2 tag compare and data RAM read - compare incoming tag vs the returned tag RAM data , issue read to data RAM if its a hit or issue memory read if its a miss
3. s3 return or fill - on a hit: grab the byte from the data RAM read result and drive cpu_read_data , on a miss wait for the external memory to return, then write into data ram then drive cpu_read_data
testbench 1:  a fixed small sequence of five hand coded operations(miss read, hit read, hit write, read after write, new line miss) , hardwired "one cycle" latency for memories
result :CPU time reduced by 5 secs, same elapsed time, but slightly more memory usage mostly from all the extra registers used in between the stages.

testbench 2: parametrizable latency - sweep and study with various memory latencies. parameter MEM_LATENCY = 3. randomized read/write accesses(via do_random_access), sequential burst reads across an entire cache line, multiple phases.

results: launch_simulation: Time (s): cpu = 00:00:05 ; elapsed = 00:00:07 . Memory (MB): peak = 10627.027 ; gain = 21.809 ; free physical = 3106 ; free virtual = 11314


