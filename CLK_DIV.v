`timescale 1ns / 1ps
`define FPGA_CLK_FEQ 50000000

module CLK_DIV(
    input clk_in,
    output clk_out
    );
	 
	parameter divider = 1;

	reg [31:0] counter;
	reg clk_div_buff;
	
	assign clk_out = clk_div_buff;
	
	always @ (posedge clk_in)
	begin
		if (counter == (`FPGA_CLK_FEQ / divider) / 2)
		begin
			clk_div_buff = !clk_div_buff;
			counter = 32'h0;
		end
		else
			counter = counter + 1;
		begin
		end
	end
		
	initial
	begin
		clk_div_buff = 0;
		counter = 0;
	end

endmodule
