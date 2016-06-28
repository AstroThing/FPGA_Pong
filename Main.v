`timescale 1ns / 1ps

`define BUTTONS Pause, Reset, P1_Left, P1_Right, P2_Left, P2_Right, P1_Press, P2_Press

`define SCREEN_WIDTH 640
`define SCREEN_HEIGHT 480

`define BLACK 3'b000
`define BLUE 3'b001
`define GREEN 3'b010
`define CYAN 3'b011
`define RED 3'b100
`define MAGENTA 3'b101
`define YELLOW 3'b110
`define WHITE 3'b111

`define BORDER_WIDTH 5'd10
`define SIDE_BORDER_HEIGHT `SCREEN_HEIGHT-(`BORDER_WIDTH*2)
`define BORDER_COLOR `GREEN
`define BORDER_PADDING 10

`define CENTER_BAR_Y (`SCREEN_HEIGHT - `BORDER_WIDTH)/2

`define GAME_WIDTH `SCREEN_WIDTH-(`BORDER_WIDTH*2)

`define PADDLE1_COLOR `RED
`define PADDLE2_COLOR `BLUE
`define PADDLE_WIDTH 100
`define PADDLE_HEIGHT 10

`define BALL_DIM 10
`define BALL_PADDING 5
`define BALL_COLOR `WHITE

`define LEFT_LIMIT `BORDER_WIDTH
`define RIGHT_LIMIT `SCREEN_WIDTH - `BORDER_WIDTH - `PADDLE_WIDTH

module Main(
	input clk,
	input `BUTTONS,
	output hsync, vsync,
	output [2:0] pixel
    );
	 
	 wire ignore;
	
	//PADDLE CONTROL
	//--------------------------------------------------------------------------------------//
	wire [9:0] paddle1_x;
	wire [9:0] paddle2_x;
	 
   wire [8:0] paddle1_y;
	wire [8:0] paddle2_y;
	
	wire input_clk;
	CLK_DIV #(.divider(500)) input_clk_div(clk, input_clk);
	
	Paddle paddles(input_clk, ignore, `BUTTONS, paddle1_x, paddle2_x, paddle1_y, paddle2_y);
	//--------------------------------------------------------------------------------------//

	//BALL CONTROL
	//--------------------------------------------------------------------------------------//
	wire [9:0] ball_x;
	wire [8:0] ball_y;
	wire [1:0] goal;
	
	Ball ball(input_clk, ignore, `BUTTONS, goal, paddle1_x, paddle2_x, paddle1_y, paddle2_y, ball_x, ball_y);
	//--------------------------------------------------------------------------------------//

	//SCORE CONTROL
	//--------------------------------------------------------------------------------------//
	wire [3:0] P1_Score;
	wire [3:0] P2_Score;
	wire [1:0] winner;
	wire score_clk;
	CLK_DIV #(.divider(250)) score_clk_div(clk, score_clk);
	
	assign ignore = winner != 2'd0;
	
	Scores scores(score_clk, Reset, ball_y, goal, winner, P1_Score, P2_Score); 
	//--------------------------------------------------------------------------------------//

	//VGA CONTROL
	//--------------------------------------------------------------------------------------//
	wire vga_clk;
	// synthesis attribute CLKFX_DIVIDE of vga_clock_dcm is 4
	// synthesis attribute CLKFX_MULTIPLY of vga_clock_dcm is 2
	DCM vga_clock_dcm (.CLKIN(clk), .CLKFX(vga_clk));
	
	VGA vga (vga_clk, winner, P1_Score, P2_Score, ball_x, ball_y, paddle1_x, paddle2_x, paddle1_y, paddle2_y, hsync, vsync, pixel);
	//--------------------------------------------------------------------------------------//
endmodule

module Paddle(
	 input clk,
	 input ignore,
	 input `BUTTONS,
	 output wire [9:0] paddle1_x, paddle2_x,
    output wire [8:0] paddle1_y, paddle2_y
	 );
	 
	parameter
		INCREMENT = 2;
	 
	reg [9:0] current_paddle1_x = (`SCREEN_WIDTH - `PADDLE_WIDTH)/2; 
   reg [9:0] current_paddle2_x = (`SCREEN_WIDTH - `PADDLE_WIDTH)/2;
	 
   reg [8:0] current_paddle1_y = `BORDER_WIDTH+`BORDER_PADDING;
	reg [8:0] current_paddle2_y = `SCREEN_HEIGHT-`BORDER_WIDTH-`BORDER_PADDING-`PADDLE_HEIGHT;
	
	assign paddle1_x = current_paddle1_x;
	assign paddle2_x = current_paddle2_x;		
	assign paddle1_y = current_paddle1_y;
	assign paddle2_y = current_paddle2_y;
	
	always  @ (posedge clk)
	begin
		if (Reset) begin
			current_paddle1_x = (`SCREEN_WIDTH - `PADDLE_WIDTH)/2;
			current_paddle2_x = (`SCREEN_WIDTH - `PADDLE_WIDTH)/2;
			current_paddle1_y = `BORDER_WIDTH+`BORDER_PADDING;
			current_paddle2_y = `SCREEN_HEIGHT-`BORDER_WIDTH-`BORDER_PADDING-`PADDLE_HEIGHT;
		end
		else if (!ignore) begin
			//Paddle 1
			if(P1_Left)
				current_paddle1_x = (current_paddle1_x <= `LEFT_LIMIT) ? `LEFT_LIMIT : current_paddle1_x - 1;
			else if(P1_Right)
				current_paddle1_x = (current_paddle1_x >= `RIGHT_LIMIT) ? `RIGHT_LIMIT : current_paddle1_x + 1;
			else
				current_paddle1_x = current_paddle1_x;
			
			//Paddle 2
			if(P2_Left)
				current_paddle2_x = (current_paddle2_x <= `LEFT_LIMIT) ? `LEFT_LIMIT : current_paddle2_x - 1;
			else if(P2_Right)
				current_paddle2_x = (current_paddle2_x >= `RIGHT_LIMIT) ? `RIGHT_LIMIT : current_paddle2_x + 1;
			else
				current_paddle2_x = current_paddle2_x;
		end
	end

endmodule

`define LEFT 2'd0
`define CENTER 2'd1
`define RIGHT 2'd2
`define UP 1
`define DOWN 0
`define BALL_LEFT_LIMIT `BORDER_WIDTH
`define BALL_RIGHT_LIMIT `SCREEN_WIDTH - `BORDER_WIDTH - `BALL_DIM

module Ball(
	input clk,
	input ignore,
	input `BUTTONS,
	input [1:0] goal,
	input [9:0] paddle1_x, paddle2_x,
	input [8:0] paddle1_y, paddle2_y,
	output reg [9:0] ball_x,
	output reg [8:0] ball_y
	);
	
	parameter
		SLOPE = 1;
	
	reg resting = 1;
	reg [1:0] x_direction = `CENTER;
	reg y_direction = `DOWN;
	reg [9:0] last_x = 0;
	reg [8:0] last_y = 0;
	
	reg player = 0;

	always @ (posedge clk)
	begin
		if(Reset | resting)
		begin
			if(Reset | player == 0)
			begin
				ball_x = paddle1_x + (`PADDLE_WIDTH - `BALL_DIM)/2;
				ball_y = paddle1_y + (`BALL_PADDING + `PADDLE_HEIGHT);
				last_x = ball_x;
				last_y = ball_y;
						
				resting = !P1_Press;
				
				if(P1_Left)
					x_direction = `LEFT;
				else if(P1_Right)
					x_direction = `RIGHT;
				else
					x_direction = `CENTER;
			end
			else
			begin
				ball_x = paddle2_x + (`PADDLE_WIDTH - `BALL_DIM)/2;
				ball_y = paddle2_y - `BALL_PADDING - `BALL_DIM;
				last_x = ball_x;
				last_y = ball_y;
						
				resting = !P2_Press;
				
				if(P2_Left)
					x_direction = `LEFT;
				else if(P2_Right)
					x_direction = `RIGHT;
				else
					x_direction = `CENTER;
			end
		end
		else
		begin
			if(goal != 0)
			begin
				resting = 1;
				if(goal == 1)
					player = 1;
				else if(goal == 2)
					player = 0;
			end

			if(ball_y + `BALL_DIM >= paddle2_y && ball_y <= paddle2_y + `PADDLE_HEIGHT && ball_x + `BALL_DIM >= paddle2_x && ball_x <= paddle2_x + `PADDLE_WIDTH ||
				ball_y <= paddle1_y + `PADDLE_HEIGHT && ball_y >= paddle1_y && ball_x + `BALL_DIM >= paddle1_x && ball_x <= paddle1_x + `PADDLE_WIDTH)
			begin
				last_x = ball_x;
				last_y = ball_y;
				case(x_direction)
					`LEFT: x_direction = `RIGHT;
					`RIGHT: x_direction = `LEFT;
					default: x_direction = `CENTER;
				endcase
				
				if(y_direction == `DOWN)
				begin
					if(P2_Left)
						x_direction = `LEFT;
					else if(P2_Right)
						x_direction = `RIGHT;
					else
						begin
							if(x_direction == `LEFT)
								x_direction = `RIGHT;
							else if(x_direction == `RIGHT)
								x_direction = `LEFT;
							else
								x_direction = `CENTER;
						end
					y_direction = `UP;
				end
				else
				begin
					if(P1_Left)
						x_direction = `LEFT;
					else if(P1_Right)
						x_direction = `RIGHT;
					else
						begin
							if(x_direction == `LEFT)
								x_direction = `RIGHT;
							else if(x_direction == `RIGHT)
								x_direction = `LEFT;
							else
								x_direction = `CENTER;
						end
					y_direction = `DOWN;
				end
			end
			else
			begin
				x_direction = x_direction;
				y_direction = y_direction;
			end	
		
			case(x_direction)
				`LEFT:
					begin
						if(ball_x <= `BALL_LEFT_LIMIT)
						begin
							x_direction = `RIGHT;
							last_y = ball_y;
							last_x = ball_x;
						end
						else
						begin
							ball_x = ball_x - 1 ;
							ball_y = last_y - (SLOPE * ball_x) + (last_x / SLOPE);
							if(y_direction == `DOWN)
								ball_y = last_y - (SLOPE * ball_x) + (last_x / SLOPE);
							else
								ball_y = last_y + (SLOPE * ball_x) - (last_x / SLOPE);
						end
					end
				`CENTER: 
					begin
						ball_y = ball_y + (y_direction == `DOWN ? 1 : -1);
					end
				`RIGHT:
					begin
						if(ball_x >= `BALL_RIGHT_LIMIT)
						begin
							x_direction = `LEFT;
							last_y = ball_y;
							last_x = ball_x;
						end
						else
						begin
							ball_x = ball_x + 1;
							if(y_direction == `DOWN)
								ball_y = last_y + (SLOPE * ball_x) - (last_x / SLOPE);
							else
								ball_y = last_y - (SLOPE * ball_x) + (last_x / SLOPE);
						end
					end
				default: begin ball_x = ball_x; ball_y = ball_y; end
			endcase
		end
	end
endmodule

module Scores(
	input clk, Reset,
	input [8:0] ball_y,
	output [1:0] goal, winner,
	output reg [3:0] p1_score, p2_score
	);
	
	assign goal = ball_y <= `BORDER_WIDTH ? 2'd2 :
	              ball_y + `BALL_DIM >= `SCREEN_HEIGHT - `BORDER_WIDTH ? 2'd1 : 2'd0;
					  
	assign winner = p1_score == 4'd9 ? 2'd1 : p2_score == 4'd9 ? 2'd2 : 2'd0;
					  
	always @ (posedge clk)
	begin
		if(Reset)
		begin
			p1_score <= 4'd0;
			p2_score <= 4'd0;
		end
		else
		begin
			if(goal == 2)
				p1_score <= p1_score + 1;
			else if(goal == 1)
				p2_score <= p2_score + 1;
		end
	end
	
endmodule

module VGA(
    input clk,
	 input [1:0] winner,
	 input [3:0] P1_Score, P2_Score,
	 input [9:0] ball_x,
	 input [8:0] ball_y,
	 input [9:0] paddle1_x, paddle2_x,
    input [8:0] paddle1_y, paddle2_y,
    output reg hsync, vsync,
    output reg [2:0] pixel
    );
	 
reg [9:0] hcount, vcount;

reg [3:0] digit = 4'd0;
reg [11:0] current_digit_address = 0;
wire [2:0] digit_data;
Digits digits_rom(.digit(digit), .address(current_digit_address), .data(digit_data));

reg [12:0] current_message_address = 0;
wire [2:0] message_data;
Messages_ROM messages(.player(winner), .address(current_message_address), .data(message_data));

always @ (posedge clk)
begin
	if(hcount == 799)
	begin
		hcount <= 0;
		if(vcount == 524)
			vcount <= 0;
		else
			vcount <= vcount + 1;
	end
	else
		hcount <= hcount + 1;
	
	if(vcount >= 490 && vcount < 492)
		vsync <= 0;
	else
		vsync <= 1;
		
	if(hcount >= 656 && hcount < 752)
		hsync <= 0;
	else
		hsync <= 1;
		
	if(hcount < `SCREEN_WIDTH && vcount < `SCREEN_HEIGHT)
	begin
		// BORDER-TOP
		if (vcount >= 0 && vcount < `BORDER_WIDTH && hcount >= 0 && hcount < `SCREEN_WIDTH)
			pixel <= `BORDER_COLOR;
			
		// BORDER-LEFT
		else if (vcount >= `BORDER_WIDTH && vcount < (`BORDER_WIDTH+`SIDE_BORDER_HEIGHT) && 
		         hcount >= 0 && hcount < `BORDER_WIDTH)
			pixel <= `BORDER_COLOR;
		
		// BORDER-BOTTOM
		else if (vcount >= (`BORDER_WIDTH+`SIDE_BORDER_HEIGHT) && vcount < `SCREEN_HEIGHT &&
		         hcount >= 0 && hcount < `SCREEN_WIDTH)
			pixel <= `BORDER_COLOR;
		
		// BORDER-RIGHT
		else if (vcount >= `BORDER_WIDTH && vcount < (`BORDER_WIDTH+`SIDE_BORDER_HEIGHT) &&
		         hcount >= (`BORDER_WIDTH + `GAME_WIDTH) && hcount < `SCREEN_WIDTH)
			pixel <= `BORDER_COLOR;
			
		// CENTER-BAR
		else if (vcount >= `CENTER_BAR_Y && vcount < (`CENTER_BAR_Y + `BORDER_WIDTH) &&
		         hcount >= `BORDER_WIDTH && hcount < (`BORDER_WIDTH + `GAME_WIDTH))
			pixel <= `BORDER_COLOR;
		
		
		// Paddle 1
		else if (vcount >= paddle1_y && vcount < (paddle1_y+`PADDLE_HEIGHT) &&
		         hcount >= paddle1_x && hcount < (paddle1_x+`PADDLE_WIDTH))
			pixel <= `PADDLE1_COLOR;
			
		// Paddle 2
		else if (vcount >= paddle2_y && vcount < (paddle2_y+`PADDLE_HEIGHT) &&
		         hcount >= paddle2_x && hcount < (paddle2_x+`PADDLE_WIDTH))
			pixel <= `PADDLE2_COLOR;
			
		//P1 Score
		else if(vcount >= `SCREEN_HEIGHT/2 - `BORDER_WIDTH/2 - 64 - 10 && vcount < 64 + (`SCREEN_HEIGHT/2 - `BORDER_WIDTH/2 - 64 - 10) &&
				  hcount >= (`SCREEN_WIDTH - 64)/2 && hcount  < 64 + (`SCREEN_WIDTH - 64)/2)
			begin
				if(current_digit_address < 4095)
					current_digit_address <= current_digit_address + 1;
				else
				begin
					digit <= P1_Score;
					current_digit_address <= 0;
				end
				
				if(digit_data)
					pixel <= `RED;
				else
					pixel <= `BLACK;
		end
		
		//P2 Score
		else if(vcount >= `SCREEN_HEIGHT/2 + `BORDER_WIDTH/2 + 10 && vcount < 64 + (`SCREEN_HEIGHT/2 + `BORDER_WIDTH/2 + 10) &&
			hcount >= (`SCREEN_WIDTH - 64)/2 && hcount  < 64 + (`SCREEN_WIDTH - 64)/2)
			begin
				if(current_digit_address < 4095)
					current_digit_address <= current_digit_address + 1;
				else
				begin
					digit <= P2_Score;
					current_digit_address <= 0;
				end
				
				if(digit_data)
					pixel <= `BLUE;
				else
					pixel <= `BLACK;
		end
			
		//P1 Wins
		else if(vcount >= (`SCREEN_HEIGHT/2 - `BORDER_WIDTH/2 - 64 - 10 - 64 - 10) && vcount < 64 + (`SCREEN_HEIGHT/2 - `BORDER_WIDTH/2 - 64 - 10 - 64 - 10) &&
				  hcount >= (`SCREEN_WIDTH - 128)/2 && hcount < 128 + (`SCREEN_WIDTH - 128)/2 && winner == 2'd2)
			begin
				if(current_message_address < 8191)
					current_message_address <= current_message_address + 1;
				else
					current_message_address <= 0;
					
				if(message_data)
					pixel <= `WHITE;
				else
					pixel <= `BLACK;
			end
			
		else if(vcount >= (`SCREEN_HEIGHT/2 + `BORDER_WIDTH/2 + 10 + 64 + 10) && vcount < 64 + (`SCREEN_HEIGHT/2 + `BORDER_WIDTH/2 + 10 + 64 + 10) &&
				  hcount >= (`SCREEN_WIDTH - 128)/2 && hcount < 128 + (`SCREEN_WIDTH - 128)/2 && winner == 2'd1)
				begin
				if(current_message_address < 8191)
					current_message_address <= current_message_address + 1;
				else
					current_message_address <= 0;
					
				if(message_data)
					pixel <= `WHITE;
				else
					pixel <= `BLACK;
			end
			
		//Ball
		else if(vcount >= ball_y && vcount < (ball_y+`BALL_DIM) &&
				  hcount >= ball_x && hcount < (ball_x+`BALL_DIM))
				pixel <= `BALL_COLOR;	
		
		//BACKGROUND
		else
			pixel <= `BLACK;		
	end
	else
		pixel <= `BLACK;
end

initial
begin
	hcount = 0;
	vcount = 0;
end

endmodule