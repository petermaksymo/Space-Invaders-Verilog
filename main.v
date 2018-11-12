// Part 2 skeleton

module main
	(
		CLOCK_50,						//	On Board 50 MHz
		// Your inputs and outputs here
		SW,
		KEY,							// On Board Keys
		// The ports below are for the VGA output.  Do not change.
		VGA_CLK,   						//	VGA Clock
		VGA_HS,							//	VGA H_SYNC
		VGA_VS,							//	VGA V_SYNC
		VGA_BLANK_N,					//	VGA BLANK
		VGA_SYNC_N,						//	VGA SYNC
		VGA_R,   						//	VGA Red[9:0]
		VGA_G,	 						//	VGA Green[9:0]
		VGA_B   						   //	VGA Blue[9:0]
	);

	input	CLOCK_50;				//	50 MHz
	input	[3:0]	KEY;
	input [9:0] SW;

	// Do not change the following outputs
	output			VGA_CLK;   				//	VGA Clock
	output			VGA_HS;					//	VGA H_SYNC
	output			VGA_VS;					//	VGA V_SYNC
	output			VGA_BLANK_N;			//	VGA BLANK
	output			VGA_SYNC_N;				//	VGA SYNC
	output	[7:0]	VGA_R;   				//	VGA Red[7:0] Changed from 10 to 8-bit DAC
	output	[7:0]	VGA_G;	 				//	VGA Green[7:0]
	output	[7:0]	VGA_B;   				//	VGA Blue[7:0]

	wire resetn;
	assign resetn = KEY[0];

	// Create the colour, x, y and writeEn wires that are inputs to the controller.

	wire [2:0] colour;
	wire [7:0] x;
	wire [6:0] y;
	wire writeEn;

	// Create an Instance of a VGA controller - there can be only one!
	// Define the number of colours as well as the initial background
	// image file (.MIF) for the controller.
	vga_adapter VGA(
			.resetn(resetn),
			.clock(CLOCK_50),
			.colour(colour),
			.x(x),
			.y(y),
			.plot(writeEn),
			/* Signals for the DAC to drive the monitor. */
			.VGA_R(VGA_R),
			.VGA_G(VGA_G),
			.VGA_B(VGA_B),
			.VGA_HS(VGA_HS),
			.VGA_VS(VGA_VS),
			.VGA_BLANK(VGA_BLANK_N),
			.VGA_SYNC(VGA_SYNC_N),
			.VGA_CLK(VGA_CLK));
		defparam VGA.RESOLUTION = "320x240";
		defparam VGA.MONOCHROME = "FALSE";
		defparam VGA.BITS_PER_COLOUR_CHANNEL = 1;
		defparam VGA.BACKGROUND_IMAGE = "graphics/black.mif";

	// Put your code here. Your code should produce signals x,y,colour and writeEn
	// for the VGA controller, in addition to any other functionality your design may require.




    // lots of wires to connect our datapath and control
		main_control C0(.clk(),
							 .resetn(),
							 .X_pos(),
							 .Y_pos(),
							 .draw0(),
							 .draw1(),
							 .draw2(),
							 .draw3()
							 );
							 
		main_datapath D0(.clk(),
   .resetn, draw0, draw1, draw2 
	 input [9:0] X_pos_init, // Initial x Position of object
	 input [8:0] Y_pos_init, // Initial y Position of object

	 output reg [9:0] X,
	 output reg [8:0] Y, 
	 output reg [2:0] colour
    ););


endmodule


module main_control(
    input clk,
    input resetn,
	 input [9:0] X_pos,
	 input [8:0] Y_pos,
    output reg draw0, draw1, draw2, draw3;
    );

    reg [4:0] current_state, next_state;
	 reg [8:0] counter = 9'd0;
	 
    localparam  S_PLOT_USER    = 4'd0,
				    S_PLOT_ENEMY0  = 4'd1,
                S_PLOT_ENEMY1  = 4'd2,
					 S_PLOT_ENEMY2  = 4'd3,
					 S_PLOT_ENEMY3  = 4'd4;
					 //S_FINISH_PLO  = 4'd6, //not exatly sure why this is needed but FPGA wouldnt draw this one the first time around
					 //S_BLACK 	 	 = 4'd7;

    // Next state logic aka our state table
    always@(*)
    begin: state_table
            case (current_state)
								S_PLOT_USER: next_state = counter == 9'd399 ? S_PLOT_ENEMY0 : S_PLOT_USER; // Repeat ploting user until all 400 pixels are exhausted
								S_PLOT_ENEMY0: next_state = counter == 9'd399 ? S_PLOT_ENEMY1 : S_ENEMY0;
								S_PLOT_ENEMY1: next_state = counter == 9'd399 ? S_PLOT_ENEMY2 : S_ENEMY1;
								S_PLOT_ENEMY2: next_state = counter == 9'd399 ? S_PLOT_ENEMY3 : S_ENEMY2;
								S_PLOT_ENEMY3: next_state = counter == 9'd399 ? S_PLOT_USER : S_ENEMY3;
								
            default:     next_state = S_PLOT_USER;
        endcase
    end // state_table


    // Output logic aka all of our datapath control signals
    always @(*)
    begin: enable_signals
        // By default make all our signals 0 to avoid latches.
        // This is a different style from using a default statement.
        // It makes the code easier to read.  If you add other out
        // signals be sure to assign a default value for them here.
        draw0 = 1'b0;
		  draw1 = 1'b0;
		  draw2 = 1'b0;
		  draw3 = 1'b0;
		  
        case (current_state) begin
            S_PLOT_USER: draw0 = 1'b1;
				S_PLOT_ENEMY0: draw1 = 1'b1;
				S_PLOT_ENEMY1: draw2 = 1'b1;
				S_PLOT_ENEMY2: draw3 = 1'b1;
			  end
        // default:    // don't need default since we already made sure all of our outputs were assigned a value at the start of the always block
        endcase
    end // enable_signals

    // current_state registers
    always@(posedge clk)
    begin: state_FFs
        if(!resetn)
            current_state <= S_PLOT_USER;
//		  if(should_black)
//				current_state <= S_BLACK;
        else
				if (current_state == next_state) begin
					counter <= counter + 1;
				end
				else begin 
					counter <= 9'b0;
				end
            current_state <= next_state;
    end // state_FFS
endmodule

// Initial Position is the left-top corner of the sprite box
// So we copy the entire ram over starting from initial position to the VGA adapter
module main_datapath(
    input clk,
    input resetn, draw0, draw1, draw2 
	 input [9:0] X_pos_init, // Initial x Position of object
	 input [8:0] Y_pos_init, // Initial y Position of object

	 output reg [9:0] X,
	 output reg [8:0] Y, 
	 output reg [2:0] colour
    );

	 wire [9:0] X_pos0, X_pos1, X_pos2, X_pos3;
	 wire [8:0] Y_pos0, Y_pos1, Y_pos2, Y_pos3;
	 wire [2:0] colour0, colour1, colour2, colour3;

	 // initialize user
	  userFSM U0(.clk(clk),
							.resetn(resetn),
							.enable(enable),
							.x_pos_init(9'd150), // Using magic number for now
							.y_pos_init(8'b220), // Using magic number for now
							.x_pos_final(X_pos0),
							.y_pos_final(y_pos0),
							.colour(colour0)
		 );
	 
	 // Initialize first enemy
	 enemyFSM E0(.clk(clk),
							.resetn(resetn),
							.enable(enable),
							.x_pos_init(9'd20), // Using magic number for now
							.y_pos_init(8'b40), // Using magic number for now
							.x_pos_final(X_pos1),
							.y_pos_final(y_pos1),
							.colour(colour1)
		 );

		// Initialize second enemy
	  enemyFSM E1(.clk(clk),
							 .resetn(resetn),
							 .enable(enable),
							 .x_pos_init(9'60), // Using magic number for now
							 .y_pos_init(8'b40), // Using magic number for now
							 .x_pos_final(X_pos2),
 							 .y_pos_final(y_pos2),
							 .colour(colour2)
		 );

		 // Initialize third enemy
		 enemyFSM E2(.clk(clk),
 							 .resetn(resetn),
 							 .enable(enable),
 							 .x_pos_init(9'80), // Using magic number for now
 							 .y_pos_init(8'b40), // Using magic number for now
 							 .x_pos_final(X_pos3),
							 .y_pos_final(y_pos3),
 							 .colour(colour3)
 		 );
		 
    always@(posedge clk) begin
        if(!resetn) begin
			 		X <= 9'b0;
					Y <= 8'b0;
			 		colour <= 3'b0;
        end
        else begin
				 		if (draw0) begin
								X <= X_pos0;
								Y <= Y_pos0;
								colour <= colour0;
						end
						else if (draw1) begin
								X <= X_pos1;
								Y <= Y_pos1;
								colour <= colour1;
						end
						else if (draw2) begin
								X <= X_pos2;
								Y <= Y_pos2;
								colour <= colour2;
						end
						else if (draw3) begin
								X <= X_pos3;
								Y <= Y_pos3;
								colour <= colour3;
						end

        end
    end

endmodule
