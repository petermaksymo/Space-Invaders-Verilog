module frames_p_pulse_counter (clk, frames_pulse, pulse); // this will let you choose the number of framse/pulse
	input clk;
   input [5:0] frames_pulse;
	output pulse;

  wire frame;
  reg [5:0] current_frame;
  reg start = 0;

  frame_counter f0(.clk(clk), .pulse(frame));

  always @(posedge clk)
  begin
		if(start == 0) begin 
			current_frame <= 6'd0;
			start <= 1;
		end
		else if (current_frame == frames_pulse) 
			current_frame <= 6'd0;
		else if(frame)
			current_frame <= current_frame + 1;
end
  
  assign pulse = current_frame == frames_pulse ? 1'b1 : 1'b0;

endmodule


module frame_counter(clk, pulse); //this will pulse 120 times/sec for 120fps
  input clk;
  output pulse;

  wire [25:0] rate = 26'd416666; //to get 120 fps for easier speed adjustments
  
	reg [25:0]Q;
	reg start = 0;

  always @(posedge clk)
  begin
    if(start == 0)
    begin
      Q <= rate;
      start <= 1;
    end
    else if(Q == 0)
      Q <= rate;
    else
      Q <= Q-1;
  end

  assign pulse = Q == 0 ? 1 : 0;
endmodule