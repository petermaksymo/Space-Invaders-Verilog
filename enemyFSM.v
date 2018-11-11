// FSM for enemy
module enemyFSM(input[8:0] x_pos, // Initial X position of the sprite, set by us
                input[7:0] y_pos, // Initial Y position of the sprite, set by us

                output[8:0] reg final_x_pos // Final x position, connect to VGA adapter
                output[7:0] reg final_y_pos // Final y position, connect to VGA adapter
                output[2:0] reg colour // Colour of pixel, connect to VGA adapter
                );

enemy_control C1();
enemy_datapath D1();

// Initialize ram that contains enemy sprite
ramxxx enemy(.address(),
             .clock(),
             .data(9'b0),
             .wren(1'b0),
             .q(colour) // Connect to VGA Colour Input
            );

endmodule

// Control
module enemy_control();

endmodule

// Datapath
module enemy_datapath(input[8:0] x_pos,
                      input[7:0] y_pos,
                      );
if (display) begin
  counter_x <= counter_x + 1;
  if (counter_x >= ) begin
      counter_y <= counter_y + 1;
      counter_x <= 0;
  end

  if ({counter_x, counter_y} >= ) begin
      counter_done <= 1;
  end
end
                  
endmodule
