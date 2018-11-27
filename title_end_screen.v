module screen_display(input display_title,
							 input display_end,
							 input display_win,
							 input plot, clk, resetn,
							 
							 output reg [8:0] X_pos,
							 output reg [7:0] Y_pos,
							 output reg [2:0] colour,
							 output done
							 );

wire [2:0] colour_title, colour_end;
reg [16:0] counter;
							 
rom76800x3_title title_screen(
	  .address(counter),
	  .clock(clk),
	  .q(colour_title)
	  );
	  
rom76800x3_end end_screen(
	  .address(counter),
	  .clock(clk),
	  .q(colour_end)
	  );
	  
rom76800x3_win win_screen(
		.address(counter),
		.clock(clk),
		.q(colour_win)
		);

assign done = (counter == 17'd76799);
	  
	 always@(posedge clk) begin
		 if(!resetn || done) begin
			 X_pos <= 9'b111111101;
			 Y_pos <= 8'b0;
			 counter <= 17'b0;
			 colour <= 3'b0;
		 end
		 else begin
			if(plot) begin
				counter <= counter + 1;
				X_pos <= X_pos == 9'd319 ? 9'b0 : X_pos + 1;
				Y_pos <= X_pos == 8'd239 ? Y_pos + 1: Y_pos;
				if (display_title) begin
					colour <= colour_title;
				end
				if (display_end && !display_win) begin
					colour <= colour_end;
				end
				if (display_win && display_end) begin
					colour <= colour_win;
				end
			end
		end
	end
endmodule