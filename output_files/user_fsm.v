//fsm for controlling the user, will show where to plot the user sprite
module user_fsm (
  input clk,
  input resetn,
  input enable,

  output [8:0] x_pos, y_pos,
  output [2:0] colour
  );

wire plot;
wire [9:0] counter;

user_control c0_u(
    .clk(clk),
    .resetn(resetn),
    .should_plot(enable),
    .counter(counter),
    .plot(plot)
  );

user_datapath d0_u(
    .clk(clk),
    .resetn(resetn),
    .plot(plot),

    .counter(counter),
    .x(x_pos),
    .y(y.pos),
    .colour(colour)
  );

endmodule


module user_control(
  input clk,
  input resetn,
  input should_plot,
  input [9:0] counter,

  output reg plot
  );

  reg [4:0] current_state, next_state;

  localparam
    S_WAIT_PLOT    = 4'd0,
		S_PLOT         = 4'd1,
    S_FINISH_PLOT  = 4'd2;

  // Next state logic aka our state table
  always@(*)
  begin: state_table
    case (current_state)
      S_WAIT_PLOT: next_state = should_plot ? S_PLOT : S_WAIT_PLOT;
      S_PLOT: next_state = counter == 9'd399 ? S_FINISH_PLOT : S_PLOT;
      S_FINISH_PLOT: next_state = S_WAIT_PLOT;

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
      plot = 1'b0;

      case (current_state)
      S_WAIT_PLOT: plot = 1'b0;
      S_PLOT: begin
        plot = 1'b1;
      end
      S_FINISH_PLOT: plot = 1'b1;
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
  input resetn, plot,

  output reg [9:0] counter,
  output reg [4:0] x, y,
  output reg [2:0] colour
  );

wire [2:0] colour_ram;

ram400x4 user_sprite(
  .address(counter),
  .clock(clk),
  .data(9'b0),
  .wren(1'b0),
  .q(colour_ram)
  );

  always@(posedge clk) begin
    if(!resetn) begin
       x <= 5'b0;
    	 y <= 5'b0;
    	 counter <= 10'b0;
    	 colour <= 3'b0;
    end
    else begin
      if(plot) begin
         colour <= colour_ram;
         counter <= counter + 1;
         x <= x == 5'd19 ? 5'b0 : x +1;
         y <= x == 5'd19 ? y + 1: y;
  		end

    end
  end

endmodule
