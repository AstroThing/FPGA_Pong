`timescale 1ns / 1ps

////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer:
//
// Create Date:   01:02:43 06/27/2016
// Design Name:   ROM_0
// Module Name:   C:/Users/nimer/Documents/GitHub/Testing/digit_0_Test.v
// Project Name:  Testing
// Target Device:  
// Tool versions:  
// Description: 
//
// Verilog Test Fixture created by ISE for module: ROM_0
//
// Dependencies:
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
////////////////////////////////////////////////////////////////////////////////

module digit_0_Test;

	// Inputs
	reg [11:0] address;

	// Outputs
	wire [2:0] data;

	// Instantiate the Unit Under Test (UUT)
	ROM_0 uut (
		.address(address), 
		.data(data)
	);

	initial begin
		// Initialize Inputs
		address = 0;

		// Wait 100 ns for global reset to finish
		#100;
        
		// Add stimulus here

	end
      
endmodule

