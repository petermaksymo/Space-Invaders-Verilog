module user_fsm(
	input enable;
	
	
	output [8:0] x, y;
	
	
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
