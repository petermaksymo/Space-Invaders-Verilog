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
    wire x_offset, y_offset, ld_x, black;
	 wire [7:0] black_x;
	 wire [6:0] black_y;

    main_control C0(
        .clk(CLOCK_50),
        .resetn(resetn),
        
        .should_plot(~KEY[1]),
		  .should_black(~KEY[2]),
		  .should_ld_x(~KEY[3]),
		  
		  .black_x(black_x),
		  .black_y(black_y),
        
        .ld_x(ld_x),
		  .plot(writeEn),
		  .x_offset(x_offset),
		  .y_offset(y_offset),
	     .black(black)	  
        
    );

    main_datapath D0(
        .clk(CLOCK_50),
        .resetn(resetn),

        .ld_X(ld_x),
		  .black(black),
		  .plot(writeEn),
		  .data_in(SW[6:0]),
		  .x_offset(x_offset),
		  .y_offset(y_offset),	  
		  
        .colour_in(SW[9:7]),
		  .X(x),
		  .Y(y),
		  .black_x(black_x),
		  .black_y(black_y),
		  .colour(colour)
    );
                
endmodule        
                

module main_control(
    input clk,
    input resetn,
	 
    input should_plot,
	 input should_black,
	 input should_ld_x,
	 
	 input [7:0] black_x,
	 input [6:0] black_y,
	 

    output reg ld_x, plot, x_offset, y_offset, black
    
    );

    reg [4:0] current_state, next_state; 
    
    localparam  S_PLOT_SHIP    = 4'd0,
				    S_PLOT_ENEMY   = 4'd1,
                
					 S_FINISH_PLOT  = 4'd6, //not exatly sure why this is needed but FPGA wouldnt draw this one the first time around
					 S_BLACK 	 	 = 4'd7;
					 
    // Next state logic aka our state table
    always@(*)
    begin: state_table 
            case (current_state)
                S_LOAD_X: next_state = should_ld_x ? S_WAIT_PLOT : S_LOAD_X;
					 S_WAIT_PLOT: next_state = should_plot ? S_PLOT_0 : S_WAIT_PLOT;
                S_PLOT_0: next_state = S_PLOT_1;
                S_PLOT_1: next_state = S_PLOT_2;
					 S_PLOT_2: next_state = S_PLOT_3;
					 S_PLOT_3: next_state = S_FINISH_PLOT;
					 S_FINISH_PLOT: next_state = S_LOAD_X;
					 
					 S_BLACK: next_state = black_x == 8'd159 && black_y == 7'd119 ? S_LOAD_X : S_BLACK;
					 
            default:     next_state = S_LOAD_X;
        endcase
    end // state_table
   

    // Output logic aka all of our datapath control signals
    always @(*)
    begin: enable_signals
        // By default make all our signals 0 to avoid latches.
        // This is a different style from using a default statement.
        // It makes the code easier to read.  If you add other out
        // signals be sure to assign a default value for them here.
        ld_x = 1'b0;
		  plot = 1'b0;
		  x_offset = 1'b0;
		  y_offset = 1'b0;
		  black = 1'b0;

        case (current_state)
            S_LOAD_X: ld_x = 1'b1;
            S_PLOT_0: plot = 1'b1;
				S_PLOT_1: begin
					plot = 1'b1;
					x_offset = 1'b1;
				end
				S_PLOT_2: begin
					plot = 1'b1;
					y_offset = 1'b1;
				end
				S_PLOT_3: begin
					plot = 1'b1;
					x_offset = 1'b1;
					y_offset = 1'b1;
				end
				S_FINISH_PLOT: begin
					plot = 1'b1;
					x_offset = 1'b1;
					y_offset = 1'b1;
				end
				
				S_BLACK: begin
					black = 1'b1;
					plot = 1'b1;
				end
        // default:    // don't need default since we already made sure all of our outputs were assigned a value at the start of the always block
        endcase
    end // enable_signals
   
    // current_state registers
    always@(posedge clk)
    begin: state_FFs
        if(!resetn)
            current_state <= S_LOAD_X;
		  if(should_black)
				current_state <= S_BLACK;
        else
            current_state <= next_state;
    end // state_FFS
endmodule

module main_datapath(
    input clk,
    input resetn, ld_X, black, x_offset, y_offset, plot,
	 input [6:0] data_in,
	 input [2:0] colour_in,
    
	 
	 output reg [7:0] X, black_x,
	 output reg [6:0] Y, black_y,
	 output reg [2:0] colour
    );
	 
	 reg [6:0]X_pos;
    

    always@(posedge clk) begin
        if(!resetn) begin
          X <= 8'b0;
			 Y <= 7'b0;
			 X_pos <= 7'b0;
			 colour <= 3'b0; 
			 black_x <= 8'b0;
			 black_y <= 7'b0; 
        end
        else begin
            if(ld_X) begin
                X_pos <= data_in;
				end
				if(plot && !black) begin
					X <= X_pos + x_offset;
					Y <= data_in + y_offset;
					colour <= colour_in;
				end
				if(black && plot) begin
					X <= black_x;
					Y <= black_y;
					colour <= 3'b0;
					black_x <= black_y == 119 ? black_x + 1 : black_x;
					black_y <= black_y == 119 ? 0 : black_y + 1;
				end
				
        end
    end
    
endmodule
