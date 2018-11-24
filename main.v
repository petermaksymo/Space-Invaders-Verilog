// Part 2 skeleton

module main
	(
		CLOCK_50,						//	On Board 50 MHz
		// Your inputs and outputs here
		SW,
		KEY,								// On Board Keys
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
	assign shoot = ~KEY[2];

	// Create the colour, x, y and writeEn wires that are inputs to the controller.

	wire [2:0] colour;
	wire [8:0] x;
	wire [7:0] y;

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


    // lots of wires to connect our datapath and control
	 wire done_user;
	 wire done_enemies;
	 wire done_bullet;
	 
	 wire blackout_u, move_u, draw_u;
	 wire blackout_e_prep, blackout_e, move_e, draw_e; 
	 wire blackout_b, move_b, draw_b;
	 wire reach_bullet;

		main_control C0(.clk(CLOCK_50),
			 .resetn(resetn),
			 .done_user(done_user),
			 .done_enemies(done_enemies),
			 .done_bullet(done_bullet),
			 .shoot(~KEY[2]),
			 .reach_bullet(reach_bullet),

			 .blackout_u(blackout_u),
			 .blackout_b(blackout_b),
			 .move_u(move_u),
			 .move_e(move_e),
			 .move_b(move_b),
			 .draw_u(draw_u),
			 .draw_e(draw_e),
			 .draw_b(draw_b),
			 .blackout_e_prep(blackout_e_prep),
			 .blackout_e(blackout_e)
			 );

		main_datapath D0(.clk(CLOCK_50),
			.resetn(resetn),
			.move_e(move_e),
			.blackout_u(blackout_u),
			.blackout_b(blackout_b),
			.move_u(move_u),
			.move_b(move_b),
			.draw_u(draw_u),
			.draw_e(draw_e),
			.draw_b(draw_b),
			.blackout_e_prep(blackout_e_prep),
			.blackout_e(blackout_e),
			.user_move( {~KEY[3] , ~ KEY[1]} ),
			.shoot(~KEY[2]),

			.done_user(done_user),
			.done_enemies(done_enemies),
			.done_bullet(done_bullet),
			.reach_bullet(reach_bullet),
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
	input done_bullet,
	input shoot,
	input reach_bullet,

   output reg blackout_u, move_u, draw_u,
	output reg blackout_e_prep, blackout_e, move_e, draw_e,
	output reg blackout_b, move_b, draw_b
   );

	wire replot;
	frames_p_pulse_counter u_counter_0(.clk(clk), .frames_pulse(6'd1), .pulse(replot));

   reg [4:0] current_state, next_state;

   localparam
			 S_BLACKOUT_USER    = 5'd0,
			 S_MOVE_USER        = 5'd1,
			 S_PLOT_USER        = 5'd2,
			 
			 S_PREP_SHOOTING    = 5'd3,
			 S_SLOW_DOWN_BULLET = 5'd4,
			 S_BLACKOUT_BULLET  = 5'd5,
			 S_MOVE_BULLET      = 5'd6,
			 S_PLOT_BULLET      = 5'd7,
			 
			 S_BLACKOUT_E_PREP  = 5'd8,
			 S_BLACKOUT_ENEMIES = 5'd9,
			 S_MOVE_ENEMIES     = 5'd10,
			 S_PLOT_ENEMIES     = 5'd11,
			 S_DONE_PLOTS		  = 5'd12;

	localparam enemy_speed = 4'd2; //inverse of enemy speed (higher = slower) 15 was good for final
	reg [3:0] speed_divider = 4'b0;

   // Next state logic aka our state table
   always@(*)
   begin: state_table
		case (current_state)
			S_BLACKOUT_USER: next_state = done_user ? S_MOVE_USER : S_BLACKOUT_USER;
			S_MOVE_USER: next_state = S_PLOT_USER;
			S_PLOT_USER: next_state = done_user ? S_PREP_SHOOTING : S_PLOT_USER; // Repeat ploting user until all 400 pixels are exhausted
			
			S_PREP_SHOOTING: next_state = (shoot || !reach_bullet) ? S_BLACKOUT_BULLET : S_BLACKOUT_E_PREP;
			S_BLACKOUT_BULLET: next_state = done_bullet ? S_MOVE_BULLET : S_BLACKOUT_BULLET;
			S_MOVE_BULLET: next_state = S_PLOT_BULLET;
			S_PLOT_BULLET: next_state = done_bullet ? S_BLACKOUT_E_PREP : S_PLOT_BULLET;

			S_BLACKOUT_E_PREP: next_state = speed_divider == enemy_speed ? S_BLACKOUT_ENEMIES : S_DONE_PLOTS;
			S_BLACKOUT_ENEMIES: next_state = done_enemies == 1'b1 ? S_MOVE_ENEMIES : S_BLACKOUT_ENEMIES;
			S_MOVE_ENEMIES: next_state =  S_PLOT_ENEMIES;
			S_PLOT_ENEMIES: next_state = done_enemies == 1'b1 ? S_DONE_PLOTS : S_PLOT_ENEMIES;
			S_DONE_PLOTS: next_state = replot == 1'b1 ? S_BLACKOUT_USER : S_DONE_PLOTS;

			default: next_state = S_BLACKOUT_USER;
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
		move_b = 1'b0;
		draw_u = 1'b0;
		draw_e = 1'b0;
		draw_b = 1'b0;
		blackout_e_prep = 1'b0;
		blackout_e = 1'b0;
		blackout_u = 1'b0;
		blackout_b = 1'b0;

	   case (current_state)
		  S_BLACKOUT_USER: begin
				blackout_u = 1'b1;
				draw_u = 1'b1;
			end
			
		  S_MOVE_USER: move_u = 1'b1;
		  
		  S_PLOT_USER: begin
			 draw_u = 1'b1;
		  end
		  
		  S_BLACKOUT_BULLET: begin
				blackout_b = 1'b1;
				draw_b = 1'b1;
		  end
		  
		  S_MOVE_BULLET: move_b = 1; //(done_bullet == 1) ? 1 : 0;
		  
		  S_PLOT_BULLET: draw_b = 1'b1;
		  
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

        // default:// don't need default since we already made sure all of our outputs were assigned a value at the start of the always block
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
	 input blackout_u, move_u, draw_u,
	 input blackout_e_prep, blackout_e, move_e, draw_e,
	 input blackout_b, move_b, draw_b,
	 input [1:0] user_move,
	 input shoot,

	 output reg done_user,
	 output done_enemies,
	 output reg done_bullet,
	 output reach_bullet,
	 output reg [8:0] X,
	 output reg [7:0] Y,
	 output reg [2:0] colour
    );

	 localparam 
				e_in_row  = 9,   
				e_in_col  = 2,
				u_x_min   = 0,   //min/max for user to contain in fov   
				u_x_max   = 292,
				e_x_min   = 8,   //min/max for enemy's anchor for movement
				e_x_max   = 60,
				e_y_jump  = 20,  //when jumpin a row
				e_y_max   = 200; //max y enemies can be drawn
	 
	 
	 wire done_e, done_u, done_b;
	 
	 wire [8:0] X_pos_u, X_pos_e, X_pos_b; //final positions/colours
	 wire [7:0] Y_pos_u, Y_pos_e, Y_pos_b;
	 wire [2:0] colour_u, colour_e;

	 reg [8:0] X_pos_init; // Initial x Position of object
	 reg [7:0] Y_pos_init; // Initial y Position of object
	 reg [8:0] user_x_coord = 9'd146; //offset from start position
	 reg [8:0] X_pos_bullet;
	 reg [7:0] Y_pos_bullet;

	 reg [8:0]anchor_x = 8; //anchor point where enemies are based off of
	 reg [7:0]anchor_y = 10;

	 reg direction_e = 1'b1; //1 for right, 0 for left
	 
	 reg done_looking;
	 reg enemies[0:e_in_row-1][0:e_in_col-1];

	 reg enable_draw_e;
	 
				

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
			for(i = 0; i < e_in_row; i = i + 1) begin
				for(j = 0; j < e_in_col ; j = j + 1) begin
					if (!done_looking && enemies[i][j] == 0) begin
						X_pos_init = anchor_x + (i * 28);
						Y_pos_init = anchor_y + (j * 25);
						e_i = i;
						e_j = j;
						done_looking = 1;
						enable_draw_e = (Y_pos_init < e_y_max) ? 1 : 0;
					end
				end
			end
		end

	 end

	 //Initialize user
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
	
	  bulletFSM B1(.clk(clk),
		.resetn(resetn),
		.enable(draw_b),
		.x_pos_init(X_pos_bullet), // Using magic number for now
		.y_pos_init(Y_pos_bullet), // Using magic number for now
		.done_b(done_b),
		.x_pos_final(X_pos_b),
		.y_pos_final(Y_pos_b)
	);
	  
	always@(posedge clk) begin
	  if(!resetn) begin
			X <= 9'b0;
			Y <= 8'b0;
			colour <= 3'b0;
			done_user <= 1'b0;
			direction_e <= 1'b1;
			for(i = 0; i < e_in_row; i = i + 1) begin
				for(j = 0; j < e_in_col; j = j + 1) begin
					enemies[i][j] <= 0;
				end
			end
	  end

	  else begin
			if (move_u) begin //no reset for user_x_coord because we want a latch
				case(user_move)
					2'b01: user_x_coord <= user_x_coord == u_x_max ? u_x_min : user_x_coord + 1;
					2'b10: user_x_coord <= user_x_coord == u_x_min ? u_x_max : user_x_coord - 1;
					default: user_x_coord <= user_x_coord;
				endcase
			end
			
			if (move_b) begin
				Y_pos_bullet <= Y_pos_bullet - 1;
			end
			
			if (shoot) begin
				X_pos_bullet <= (reach_bullet == 1) ? user_x_coord : X_pos_bullet;
			end
			
			
			if (move_e) begin
				if(anchor_x == e_x_max - 1) direction_e <= 0;
				if(anchor_x == e_x_min + 1) direction_e <= 1;

				anchor_x <= direction_e ? anchor_x + 1 : anchor_x - 1;
				anchor_y <= (anchor_x == e_x_min || anchor_x == e_x_max) ? anchor_y + e_y_jump : anchor_y;
				
				for(i = 0; i < e_in_row; i = i + 1) begin
					for(j = 0; j < e_in_col; j = j + 1) begin
						enemies[i][j] <= 0;
					end
				end
			end
			
			if (draw_u) begin
				X <= X_pos_u;
				Y <= Y_pos_u;
				colour <= blackout_u == 1'b1 ? 3'b0 : colour_u;
				done_user <= done_u;
			end
			
			if (draw_b) begin
				X <= X_pos_b;
				Y <= Y_pos_b;
				colour <= blackout_b == 1'b1 ? 3'b000 : 3'b101;
				done_bullet <= done_b;
			end
			
			if (draw_e) begin
				X <= X_pos_e;
				Y <= Y_pos_e;
				colour <= blackout_e == 1'b1 ? 3'b0 : colour_e;
				enemies[e_i][e_j] <= done_e == 1? 1 : 0;
			end
			
			if(blackout_e_prep) begin
				for(i = 0; i < e_in_row; i = i + 1) begin
					for(j = 0; j < e_in_col; j = j + 1) begin
						enemies[i][j] <= 0;
					end
				end
			end

	  end
    end

	 assign done_enemies = enemies[e_in_row - 1][e_in_col - 1] == 1 ? 1 : 0;
	 assign reach_bullet = Y_pos_bullet == 0 ? 1 : 0;

endmodule
