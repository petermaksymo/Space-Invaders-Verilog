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
	wire [8:0] x;
	wire [7:0] y;
	wire blackout_u, move_e, move_u, draw_u, draw_e;

	// Create an Instance of a VGA controller - there can be only one!
	// Define the number of colours as well as the initial background
	// image file (.MIF) for the controller.
	vga_adapter VGA(
			.resetn(resetn),
			.clock(CLOCK_50),
			.colour(colour),
			.x(x),
			.y(y),
			.plot(1'b1),
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
	 wire done_user;
	 wire [6:0] done_enemies;

		main_control C0(.clk(CLOCK_50),
			 .resetn(resetn),
			 .done_user(done_user),
			 .done_enemies(done_enemies),

			 .blackout_u(blackout_u),
			 .move_u(move_u),
			 .move_e(move_e),
			 .draw_u(draw_u),
			 .draw_e(draw_e)
			 );

		main_datapath D0(.clk(CLOCK_50),
			.resetn(resetn),
			.move_e(move_e),
			.blackout_u(blackout_u),
			.move_u(move_u),
			.draw_u(draw_u),
			.draw_e(draw_e),
			.user_move( {~KEY[3] , ~ KEY[1]} ),

			.done_user(done_user),
			.done_enemies(done_enemies),
	 		.X(x),
	 	 	.Y(y),
			.colour(colour)
    );


endmodule


module main_control(
    input clk,
    input resetn,
	  input done_user,
	  input [6:0] done_enemies,

    output reg blackout_u, move_e, move_u, draw_u, draw_e
    );

		frames_p_pulse_counter u_counter_0(.clk(clk), .frames_pulse(6'd1), .pulse(replot));

		wire replot;
    reg [4:0] current_state, next_state;

    localparam
					 S_BLACKOUT_USER= 4'd0,
					 S_MOVE_USER    = 4'd1,
					 S_PLOT_USER    = 4'd2,
					 S_MOVE_ENEMIES = 4'd3,
				   S_PLOT_ENEMIES = 4'd4,
					 S_DONE			    = 4'd5;


    // Next state logic aka our state table
    always@(*)
    begin: state_table
            case (current_state)
								S_BLACKOUT_USER: next_state = done_user ? S_MOVE_USER : S_BLACKOUT_USER;
								S_MOVE_USER: next_state = S_PLOT_USER;
								S_PLOT_USER: next_state = done_user ? S_MOVE_ENEMIES : S_PLOT_USER; // Repeat ploting user until all 400 pixels are exhausted
								S_MOVE_ENEMIES: next_state =  S_PLOT_ENEMIES;
								S_PLOT_ENEMIES: next_state = done_enemies == 7'd60 ? S_DONE : S_PLOT_ENEMIES;
								S_DONE: next_state = replot == 1'b1 ? S_BLACKOUT_USER : S_DONE;

            default:     next_state = S_BLACKOUT_USER;
        endcase
    end // state_table


    // Output logic aka all of our datapath control signals
    always @(*)
    begin: enable_signals
        // By default make all our signals 0 to avoid latches.
        // This is a different style from using a default statement.
        // It makes the code easier to read.  If you add other out
        // signals be sure to assign a default value for them here.
				blackout_u = 1'b0;
				move_e = 1'b0;
				move_u = 1'b0;
				draw_u = 1'b0;
				draw_e = 1'b0;

        case (current_state)
				  S_BLACKOUT_USER: begin
						blackout_u = 1'b1;
						draw_u = 1'b1;
					end
				  S_MOVE_USER: move_u = 1'b1;
					S_PLOT_USER: begin
						draw_u = 1'b1;
					end
					S_MOVE_ENEMIES: move_e = 1'b1;
					S_PLOT_ENEMIES: begin
					  draw_e = 1'b1;
				  end

        // default:    // don't need default since we already made sure all of our outputs were assigned a value at the start of the always block
        endcase
    end // enable_signals

    // current_state registers
    always@(posedge clk)
    begin: state_FFs
        if(!resetn)
            current_state <= S_BLACKOUT_USER;
        else
            current_state <= next_state;
    end // state_FFS
endmodule

// Initial Position is the left-top corner of the sprite box
// So we copy the entire ram over starting from initial position to the VGA adapter
module main_datapath(
    input clk,
    input resetn,
		input blackout_u, move_e, move_u, draw_u, draw_e,
		input [1:0] user_move,

	 output reg done_user,
	 output reg [6:0] done_enemies,
	 output reg [8:0] X,
	 output reg [7:0] Y,
	 output reg [2:0] colour
    );

	 wire done_e, done_u;

	 wire [8:0] X_pos_u, X_pos_e;
	 wire [7:0] Y_pos_u, Y_pos_e;
	 wire [2:0] colour_u, colour_e;

	 reg [8:0] X_pos_init; // Initial x Position of object
	 reg [7:0] Y_pos_init; // Initial y Position of object
	 reg [8:0] user_x_coord = 9'd146; //offset from start position
	 localparam anchor_x = 18;
	 localparam anchor_y = 20;

	 always@(*) begin
	 		X_pos_init = 9'd0;
			Y_pos_init = 8'd0;

			if(draw_u) begin
				X_pos_init = user_x_coord;
				Y_pos_init = 8'd220;
			end
			if(draw_e) begin
				X_pos_init = anchor_x + ((done_enemies % 10) * 28);
				Y_pos_init = anchor_y + ((done_enemies / 10) * 25);
			end

	 end

	 // initialize user
	  user_fsm U0(.clk(clk),
							.resetn(resetn),
							.enable(draw_u),
							.x_pos_init(X_pos_init), //center screen
							.y_pos_init(Y_pos_init), //bottom row
							.done(done_u),
							.x_pos_final(X_pos_u),
							.y_pos_final(Y_pos_u),
							.colour(colour_u)
		 );

	 // Initialize first enemy
	 enemyFSM E0(.clk(clk),
							.resetn(resetn),
							.enable(draw_e),
							.x_pos_init(X_pos_init), // Using magic number for now
							.y_pos_init(Y_pos_init), // Using magic number for now
							.done(done_e),
							.x_pos_final(X_pos_e),
							.y_pos_final(Y_pos_e),
							.colour(colour_e)
		 );

    always@(posedge clk) begin
        if(!resetn) begin
			 		X <= 9'b0;
					Y <= 8'b0;
			 		colour <= 3'b0;
					done_user <= 1'b0;
					done_enemies <= 7'b0;
        end
        else begin
					  if(move_u) begin //no reset for user_x_coord because we want a latch
							case(user_move)
								2'b01: user_x_coord <= user_x_coord == 292 ? 0 : user_x_coord + 1;
								2'b10: user_x_coord <= user_x_coord == 0 ? 292 : user_x_coord - 1;
								default: user_x_coord <= user_x_coord;
							endcase
						end
				 		if (draw_u) begin
								X <= X_pos_u;
								Y <= Y_pos_u;
								colour <= blackout_u == 1'b1 ? 3'b0 : colour_u;
								done_user <= done_u;
						end
						else if (draw_e) begin
								X <= X_pos_e;
								Y <= Y_pos_e;
								colour <= colour_e;
								done_enemies <= done_e == 1'b1 ? done_enemies + 1 : done_enemies;
						end

        end
    end

endmodule
