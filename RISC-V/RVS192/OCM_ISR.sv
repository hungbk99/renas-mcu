module OCM_ISR 
#(parameter	SRAM_LENGTH = 32, parameter SRAM_DEPTH =16)
(
	output 	logic 	[SRAM_LENGTH-1:0]	data_out,
	input	[SRAM_LENGTH-1:0]	data_in,
	input	[$clog2(SRAM_DEPTH)-1:0]	w_addr,
	input	[$clog2(SRAM_DEPTH)-1:0]	r_addr,
	input	wen,
	input	clk
);

	logic	[SRAM_LENGTH-1:0]	SRAM	[SRAM_DEPTH-1:0];
	
	
	always_ff	@(posedge clk)
	begin
		if(wen)
    begin
			SRAM[w_addr[$clog2(SRAM_DEPTH)-1:2]] = data_in;
		  data_out = data_in;
    end
    else
      data_out = SRAM[r_addr[$clog2(SRAM_DEPTH)-1:2]];
	end

  `ifdef OCM_SIM
    parameter INST = "D:/Project/renas-mcu/MMEM/spi_isr.txt";
    initial begin
      $display("OCM DB");
      $readmemh(INST, SRAM);
    end
  `endif
endmodule

