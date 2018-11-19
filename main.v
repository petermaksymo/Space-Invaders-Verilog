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
	wire move_e, move_u, draw_u, draw_e;

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
	 wire done_enemies, blackout_e, blackout_e_prep;

		main_control C0(.clk(CLOCK_50),
			 .resetn(resetn),
			 .done_user(done_user),
			 .done_enemies(done_enemies),

			 .move_u(move_u),
			 .move_e(move_e),
			 .draw_u(draw_u),
			 .draw_e(draw_e),
			 .blackout_e_prep(blackout_e_prep),
			 .blackout_e(blackout_e)
			 );

		main_datapath D0(.clk(CLOCK_50),
			.resetn(resetn),
			.move_e(move_e),
			.move_u(move_u),
			.draw_u(draw_u),
			.draw_e(draw_e),
			.blackout_e_prep(blackout_e_prep),
			.blackout_e(blackout_e),
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
	  input done_enemies,

    output reg move_e, move_u, draw_u, draw_e, blackout_e_prep, blackout_e
    );

		wire replot;
		frames_p_pulse_counter u_counter_0(.clk(clk), .frames_pulse(6'd1), .pulse(replot));

    reg [4:0] current_state, next_state;

    localparam
					 S_MOVE_USER        = 4'd0,
					 S_PLOT_USER        = 4'd1,
					 S_BLACKOUT_E_PREP  = 4'd2,
					 S_BLACKOUT_ENEMIES = 4'd3,
					 S_MOVE_ENEMIES     = 4'd4,
				   S_PLOT_ENEMIES     = 4'd5,
					 S_DONE_PLOTS			  = 4'd6;

	 	localparam enemy_speed = 4'd10; //inverse of enemy speed (higher = slower)
		reg [3:0] speed_divider;

    // Next state logic aka our state table
    always@(*)
    begin: state_table
            case (current_state)
								S_MOVE_USER: next_state = S_PLOT_USER;
								S_PLOT_USER: next_state = done_user ? S_BLACKOUT_E_PREP : S_PLOT_USER; // Repeat ploting user until all 400 pixels are exhausted
								S_BLACKOUT_E_PREP: next_state = speed_divider == enemy_speed ? S_BLACKOUT_ENEMIES : S_DONE_PLOTS;
								S_BLACKOUT_ENEMIES: next_state = done_enemies == 1'b1 ? S_MOVE_ENEMIES : S_BLACKOUT_ENEMIES;
								S_MOVE_ENEMIES: next_state =  S_PLOT_ENEMIES;
								S_PLOT_ENEMIES: next_state = done_enemies == 1'b1 ? S_DONE_PLOTS : S_PLOT_ENEMIES;
								S_DONE_PLOTS: next_state = replot == 1'b1 ? S_MOVE_USER : S_DONE_PLOTS;


            default:     next_state = S_MOVE_USER;
        endcase
    end // state_table


    // Output logic aka all of our datapath control signals
    always @(*)
    begin: enable_signals
        // By default make all our signals 0 to avoid latches.
        // This is a different style from using a default statement.
        // It makes the code easier to read.  If you add other out
        // signals be sure to assign a default value for them here.
				move_e = 1'b0;
				move_u = 1'b0;
				draw_u = 1'b0;
				draw_e = 1'b0;
				blackout_e_prep = 1'b0;
				blackout_e = 1'b0;

        case (current_state)
				  S_MOVE_USER: move_u = 1'b1;
					S_PLOT_USER: begin
						draw_u = 1'b1;
					end
					S_BLACKOUT_E_PREP:
						blackout_e_prep = 1'b1;
					S_BLACKOUT_ENEMIES: begin
						blackout_e = 1'b1;
						draw_e = 1'b1;
					end
					S_MOVE_ENEMIES: move_e = 1'b1;
					S_PLOT_ENEMIES: begin
					  draw_e = 1'b1;
				  end
					S_DONE_PLOTS:
						speed_divider = speed_divider == enemy_speed ? 0 : speed_divider + 1;

        // default:    // don't need default since we already made sure all of our outputs were assigned a value at the start of the always block
        endcase
    end // enable_signals

    // current_state registers
    always@(posedge clk)
    begin: state_FFs
        if(!resetn)
            current_state <= S_MOVE_USER;
        else
            current_state <= next_state;
    end // state_FFS
endmodule

// Initial Position is the left-top corner of the sprite box
// So we copy the entire ram over starting from initial position to the VGA adapter
module main_datapath(
    input clk,
    input resetn,
		input move_e, move_u, draw_u, draw_e, blackout_e_prep, blackout_e,
		input [1:0] user_move,

	 output reg done_user,
	 output done_enemies,
	 output reg [8:0] X,
	 output reg [7:0] Y,
	 output reg [2:0] colour
    );

	 wire done_e, done_u;
	 reg enable_draw_e;

	 wire [8:0] X_pos_u, X_pos_e;
	 wire [7:0] Y_pos_u, Y_pos_e;
	 wire [2:0] colour_u, colour_e;

	 reg [8:0] X_pos_init; // Initial x Position of object
	 reg [7:0] Y_pos_init; // Initial y Position of object
	 reg [8:0] user_x_coord = 9'd146; //offset from start position

	 reg [8:0]anchor_x = 8;
	 reg [6:0]anchor_y = 10;

	 reg direction_e = 1'b1; //1 for right, 0 for left
	 reg done_looking;
	 reg enemies[0:8][0:2];

	 localparam y_e_cutoff = 175; //max y enemies can be drawn

	 integer i, j;
	 reg[5:0] e_i, e_j;
	 always@(*) begin
	 		X_pos_init = 9'd0;
			Y_pos_init = 8'd0;
			done_looking = 0;
			e_i = 0;
			e_j = 0;
			enable_draw_e = 0;

			if(draw_u) begin
				X_pos_init = user_x_coord;
				Y_pos_init = 8'd220;
			end
			//get the coordinates of the enemy from array by finding first not drawn
			if(draw_e) begin
				for(i = 0; i < 9; i = i + 1) begin
					for(j = 0; j < 2 ; j = j + 1) begin
						if (!done_looking && enemies[i][j] == 0) begin
								X_pos_init = anchor_x + (i * 28);
								Y_pos_init = anchor_y + (j * 25);
								e_i = i;
								e_j = j;
								done_looking = 1;
								enable_draw_e = X_pos_init <= y_e_cutoff ? 1 : 0;
						end
					end
				end
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
		.enable(enable_draw_e),
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
				direction_e <= 1'b1;
				for(i = 0; i < 9; i = i + 1) begin
					for(j = 0; j < 2; j = j + 1) begin
						enemies[i][j] <= 0;
					end
				end
        end

        else begin
			  if(move_u) begin //no reset for user_x_coord because we want a latch
					case(user_move)
						2'b01: user_x_coord <= user_x_coord + 1;
						2'b10: user_x_coord <= user_x_coord - 1;
						default: user_x_coord <= user_x_coord;
					endcase
				end
				if (move_e) begin
						if(direction_e) anchor_x <= anchor_x == 48 ? 8 :  anchor_x + 1;
						else if(!direction_e) anchor_x <= anchor_x == 8 ? 48 : anchor_x - 1;

						anchor_y <= anchor_x == 48 ? anchor_y + 25 : anchor_y;
						for(i = 0; i < 9; i = i + 1) begin
							for(j = 0; j < 2; j = j + 1) begin
								enemies[i][j] <= 0;
							end
						end
				end
				if (draw_u) begin
						X <= X_pos_u;
						Y <= Y_pos_u;
						colour <= colour_u;
						done_user <= done_u;
				end
				if (draw_e) begin
						X <= X_pos_e;
						Y <= Y_pos_e;
						colour <= blackout_e == 1 ? 3'b000 : colour_e;
						enemies[e_i][e_j] <= done_e == 1? 1 : 0;
				end
				if(blackout_e_prep) begin
					for(i = 0; i < 9; i = i + 1) begin
						for(j = 0; j < 2; j = j + 1) begin
							enemies[i][j] <= 0;
						end
					end
				end

        end
    end

	 assign done_enemies = enemies[8][1] == 1 ? 1 : 0;

endmodule
