`timescale 1ns / 1ps

module Messages_ROM(
	 input [1:0] player,
    input [12:0] address,
    output reg [2:0] data
    );

	 reg [2:0] p1 [0:8191];
	 reg [2:0] p2 [0:8191];
	 
	 always @ (address)
	 begin
		case(player)
			2'd1: data = p1[address];
			2'd2: data = p2[address];
			default: data = 3'd0;
		endcase
	 end
	 
	 initial
	 begin
		$readmemh("MIFs/P1_Wins.mif", p1, 0, 8191);
		$readmemh("MIFs/P2_Wins.mif", p2, 0, 8191);
	 end
	 
endmodule
