//Keyboard decoder to values we need

module kb_decoder (
	input clk,
	input ps_clk,
	input ps_data,
	
	output reg [1:0] user_move
	);

	parameter key_a = 8'h1C;			// left movement
	parameter key_d = 8'h23;			// right movement
	parameter release_start = 8'hF0; // start of break sequence
	
	
	reg [7:0] prev_kb_data;
	reg [7:0] kb_data;
	wire [7:0] kb_data_in;
	wire new_key;
	
	keyboard kb1 (
		.clk(clk),
		.ps_clk(ps_clk),
		.ps_data(ps_data),
		.data_out(kb_data_in),
		.valid(new_key)
	);
	
	
	//release mechanics
	always @(*) begin
		kb_data = kb_data_in;
		//load prev data since break keys start with F0
		prev_kb_data = (new_key && (prev_kb_data != kb_data) ) ? kb_data : prev_kb_data;
		
		kb_data = prev_kb_data == release_start ? release_start : kb_data;
		
		case (kb_data)
			key_d: user_move = 2'b01;
			key_a: user_move = 2'b10;
			
			default: user_move = 2'b00;
		endcase
		
	end
		



endmodule


////////////////////////////
/// keyboard interface to DE2
/// Feb 13 2015
/// ps2 interface
/// proto type
///////////////////////////

module keyboard (
 data_out ,    // data out
 clk		, 		// input 50 MHz clk
 ps_clk 	, 		// ps2 clock
 ps_data ,	 		// ps2 data
 valid 
 );			


 input clk;
 input ps_data;
 input ps_clk;
 
 output [7:0] data_out;
 output reg valid;
 
 //internal registers
  
 reg [7:0] counter;
 reg [10:0] data;
 reg cnt;
 reg cnt2;

///////////////////////////////////////
/////// counters enables       ////////
///////////////////////////////////////	

wire cnt1 = (counter >= 8'd11 )? 1'b1 : 1'b0;

/////////////////////////////
/// clock for PS2      //////
/////////////////////////////	

	 always @ (negedge ps_clk or posedge cnt1 )
	 
	 begin 
	 
		if (cnt1)
		begin
			counter <= 0;
			cnt <= 1;
		end
		
			else
			
		begin
			
			counter <= counter + 1;
			cnt <= 0;
			
		end	
	end
	
	
/////////////////////////////////////////////////////////////////////
/// Serial shift register to reteive data from the PS_data line   ///
/////////////////////////////////////////////////////////////////////

	
always @ (negedge ps_clk or  posedge cnt )

 begin
 
 if (cnt) begin  valid <= 1; end
 
 else
 
 case (counter)
 	
		8'd0	: begin valid = 1; data[0] = ps_data; end // start
		8'd1	: begin valid = 0; data[1] = ps_data; end // bit 0
		8'd2	: begin valid = 0; data[2] = ps_data; end // bit 1
		8'd3	: begin valid = 0; data[3] = ps_data; end // bit 2 	
		8'd4	: begin valid = 0; data[4] = ps_data; end // bit 3
		
		8'd5	: begin valid = 0; data[5] = ps_data; end // bit 4
		8'd6	: begin valid = 0; data[6] = ps_data; end // bit 5		
		8'd7	: begin valid = 0; data[7] = ps_data; end // bit 6
		8'd8	: begin valid = 0; data[8] = ps_data; end // bit 7
		
		8'd9	: begin valid = 1; data[9] = ps_data; end // parity
		8'd10 : begin valid = 1; data[10] = ps_data; end // stop
		8'd11	: begin valid = 1; end 
		8'd12	: begin valid = 1; end

	endcase
end
	
	
	assign data_out = data[8:1]; 


endmodule
