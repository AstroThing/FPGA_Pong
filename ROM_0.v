`timescale 1ns / 1ps

module Digits(
	 input [3:0] digit,
    input [11:0] address,
    output reg [2:0] data
    );

	 reg [2:0] digit_0 [0:4095];
	 reg [2:0] digit_1 [0:4095];
	 reg [2:0] digit_2 [0:4095];
	 reg [2:0] digit_3 [0:4095];
	 reg [2:0] digit_4 [0:4095];
	 reg [2:0] digit_5 [0:4095];
	 reg [2:0] digit_6 [0:4095];
	 reg [2:0] digit_7 [0:4095];
	 reg [2:0] digit_8 [0:4095];
	 reg [2:0] digit_9 [0:4095];
	 
	 always @ (address)
	 begin
		case(digit)
			4'd0: data = digit_0[address];
			4'd1: data = digit_1[address];
			4'd2: data = digit_2[address];
			4'd3: data = digit_3[address];
			4'd4: data = digit_4[address];
			4'd5: data = digit_5[address];
			4'd6: data = digit_6[address];
			4'd7: data = digit_7[address];
			4'd8: data = digit_8[address];
			4'd9: data = digit_9[address];
			default data = 3'dX;
		endcase
	 end
	 
	 initial
	 begin
		$readmemh("MIFs/0.mif", digit_0, 0, 4095);
		$readmemh("MIFs/1.mif", digit_1, 0, 4095);
		$readmemh("MIFs/2.mif", digit_2, 0, 4095);
		$readmemh("MIFs/3.mif", digit_3, 0, 4095);
		$readmemh("MIFs/4.mif", digit_4, 0, 4095);
		$readmemh("MIFs/5.mif", digit_5, 0, 4095);
		$readmemh("MIFs/6.mif", digit_6, 0, 4095);
		$readmemh("MIFs/7.mif", digit_7, 0, 4095);
		$readmemh("MIFs/8.mif", digit_8, 0, 4095);
		$readmemh("MIFs/9.mif", digit_9, 0, 4095);
	 end
	 
endmodule
