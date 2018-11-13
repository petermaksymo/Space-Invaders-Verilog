//fsm for controlling the user, will show where to plot the user sprite
module user_fsm (
  input clk,
  input resetn,
  input enable,

  input[8:0] x_pos_init, // Initial X position of the sprite, set by us
  input[7:0] y_pos_init, // Initial Y position of the sprite, set by us

  output[8:0] x_pos_final, // Final x position, connect to VGA adapter
  output[7:0] y_pos_final, // Final y position, connect to VGA adapter
  output[2:0]  colour, // Colour of pixel, connect to VGA adapter
  output done
  );

	wire plot;
	wire [9:0] counter;

	user_control c0_u(
		 .clk(clk),
		 .resetn(resetn),
		 .should_plot(enable),
		 .counter(counter),
		 .plot(plot),
		 .done(done)
	  );

	user_datapath d0_u(
		 .clk(clk),
		 .resetn(resetn),
		 .plot(plot),

		 .x_pos_init(x_pos_init),
		 .y_pos_init(y_pos_init),

		 .counter(counter),
		 .x(x_pos_final),
		 .y(y_pos_final),
		 .colour(colour)
	  );

endmodule


module user_control(
  input clk,
  input resetn,
  input should_plot,
  input [9:0] counter,
  input should_move,
  input move_direction, // Direction sprite should move; 0 to move left, 1 to move right

  output reg plot,
  output reg move,
  output reg direction,
  output reg done
  );

  reg [4:0] current_state, next_state;

  localparam
    S_WAIT_MOVE    = 4'd0,
    S_MOVE_LEFT    = 4'd1,
    S_MOVE_RIGHT   = 4'd2,
    S_WAIT_PLOT    = 4'd3,
	  S_PLOT         = 4'd4,
    S_FINISH_PLOT  = 4'd5;


  // Next state logic aka our state table
  always@(*)
  begin: state_table
    case (current_state)
      S_WAIT_MOVE:    if (should_move)
                            next_state = move_direction ? S_MOVE_RIGHT : S_MOVE_LEFT; // 1 to move right, 0 to move left
                      else
                            next_state = S_WAIT_PLOT;
      S_MOVE_LEFT:    next_state = S_WAIT_PLOT;
      S_MOVE_RIGHT:   next_state = S_WAIT_PLOT;
      S_WAIT_PLOT:    next_state = should_plot ? S_PLOT : S_WAIT_PLOT;
      S_PLOT:         next_state = counter == 10'd559 ? S_FINISH_PLOT : S_PLOT;
      S_FINISH_PLOT:  next_state = S_WAIT_MOVE;


      default: next_state = S_WAIT_PLOT;
    endcase
  end // state_table

  // Output logic aka all of our datapath control signals
  always @(*)
  begin: enable_signals
      // By default make all our signals 0 to avoid latches.
      // This is a different style from using a default statement.
      // It makes the code easier to read.  If you add other out
      // signals be sure to assign a default value for them here.
      move = 1'b0;
      direction = 1'b0;
      plot = 1'b0;
		  done = 1'b0;

      case (current_state)
      S_WAIT_MOVE: move = 0;
      S_MOVE_LEFT: begin
            move = 1;
            direction = 0;
            end
      S_MOVE_RIGHT: begin
            move = 1;
            direction = 1;
            end
      S_WAIT_PLOT: plot = 1'b0;
      S_PLOT: plot = 1'b1;
      S_FINISH_PLOT: begin
			      plot = 1'b1;
			      done = 1'b1;
		        end
      // default:    // don't need default since we already made sure all of our outputs were assigned a value at the start of the always block
      endcase
  end // enable_signals

  // current_state registers
  always@(posedge clk)
  begin: state_FFs
      if(!resetn)
          current_state <= S_WAIT_PLOT;
      else
          current_state <= next_state;
  end // state_FFS
endmodule

module user_datapath(
  input clk,
  input resetn, plot, done, move, direction,
  input [8:0] x_pos_init,
  input [7:0] y_pos_init,

  output reg [9:0] counter,
  output [8:0] x,
  output [7:0] y,
  output reg [2:0] colour
  );
	reg [4:0] x_sprite, y_sprite;

	wire [2:0] colour_ram;

	assign x = x_pos_init + x_sprite;
	assign y = y_pos_init + y_sprite;

	rom560x3_user user_sprite(
	  .address(counter),
	  .clock(clk),
	  .q(colour_ram)
  );

	  always@(posedge clk) begin
		 if(!resetn) begin
			 x_sprite <= 5'b0;
			 y_sprite <= 5'b0;
			 counter <= 10'b0;
			 colour <= 3'b0;
		 end
		 else begin
			if(plot) begin
				colour <= colour_ram;
				counter <= counter + 1;
				x_sprite <= x_sprite == 5'd27 ? 5'b0 : x_sprite + 1;
				y_sprite <= x_sprite == 5'd27 ? y_sprite + 1: y_sprite;
			end
      if (move) begin
          if (direction)
              X <= X + 1;
          else
              X <= X - 1;
          end
		   end
	  end

endmodule
