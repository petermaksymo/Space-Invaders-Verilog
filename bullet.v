module bulletFSM(input [8:0] x_pos_init,
					  input [7:0] y_pos_init,
				     input clk,
				     input enable, resetn,
				  
				     output done_b,
				     output [8:0] x_pos_final,
				     output [7:0] y_pos_final
					);
					
	wire [1:0] counter;
	wire plot, done_plot;
					
	assign done_b = !enable ? 1 : done_plot;
					
	bullet_control c1(.clk(clk),
						.resetn(resetn),
						.should_plot(enable),
						.counter(counter),
	
						.plot(plot),
						.done(done_plot)
						);
						
	bullet_datapath d1(.clk(clk),
						 .resetn(resetn),
						 .plot(plot),
						 .x_pos_init(x_pos_init),
						 .y_pos_init(y_pos_init),
						 
						 .counter(counter),
						 .x_pos_final(x_pos_final),
						 .y_pos_final(y_pos_final)
						);						

endmodule

module bullet_control(
  input clk,
  input resetn,
  input should_plot,
  input [1:0] counter,

  output reg plot,
  output reg done
  );
	
  reg [3:0] current_state, next_state;

  localparam
    S_WAIT_PLOT    = 4'd0,
	 S_PLOT         = 4'd1,
    S_FINISH_PLOT  = 4'd2;

  // Next state logic aka our state table
  always@(*)
  begin: state_table
    case (current_state)
      S_WAIT_PLOT: next_state = should_plot ? S_PLOT : S_WAIT_PLOT;
      S_PLOT: next_state = counter == 2'd3 ? S_FINISH_PLOT : S_PLOT;
      S_FINISH_PLOT: next_state = S_WAIT_PLOT;

      default: next_state = S_WAIT_PLOT;
    endcase
  end // state_table

  // Output logic aka all of our datapath control signals
  always @(*)
  begin: enable_signals
      plot = 1'b0;
		done = 1'b0;

      case (current_state)
      S_WAIT_PLOT: plot = 1'b0;
      S_PLOT: plot = 1'b1;
      S_FINISH_PLOT: begin
			plot = 1'b1;
			done = 1'b1;
		end
      // default:    // don't need default since we already made sure all of our outputs were 	ed a value at the start of the always block
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

module bullet_datapath(
  input clk,
  input resetn, plot,

  input [8:0] x_pos_init,
  input [7:0] y_pos_init,

  output [1:0] counter,
  output [8:0] x_pos_final,
  output [7:0] y_pos_final
  );
	
	reg [1:0] y_offset;
	assign counter = y_offset;
	assign x_pos_final = x_pos_init;			
	assign y_pos_final = y_pos_init - y_offset;

			wire done;
			assign done = (y_offset == 2'd3);

	  always@(posedge clk) begin
		 if(!resetn || done) begin
			 y_offset <= 2'b0;
		 end
		 else begin
			if(plot) begin
				y_offset <= (y_offset == 2'd3) ? 2'd0 : y_offset + 1;
			end
		 end
	  end

endmodule