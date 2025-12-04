module Dice_Manager(
    input clk,
    input reset_n,
    input roll_en,            // roll trigger from FSM
    input [4:0] hold_sw,      // DIP switches for Hold
    input [1:0] roll_cnt_in,  // current roll count from FSM (0~3)
    input dice_clear,         // pulse to clear dice when turn changes
    output reg [2:0] dice1, dice2, dice3, dice4, dice5 // dice outputs (1~6)
);

    // 32-bit LFSR
    reg [31:0] lfsr_reg;

    // simple seed mix that keeps changing during reset
    reg [31:0] seed_mix;

    // LFSR feedback (taps: 32, 22, 2, 1)
    wire feedback = lfsr_reg[31] ^ lfsr_reg[21] ^ lfsr_reg[1] ^ lfsr_reg[0];

    // Seed mixer: increment while reset is asserted
    always @(posedge clk or negedge reset_n) begin
        if (!reset_n)
            seed_mix <= seed_mix + 32'h1;
        else
            seed_mix <= seed_mix;
    end

    // LFSR and dice update
    always @(posedge clk or negedge reset_n) begin
        if (!reset_n) begin
            // re-seed LFSR and clear dice
            lfsr_reg <= (32'hACE1 ^ seed_mix);
            dice1 <= 0;
            dice2 <= 0;
            dice3 <= 0;
            dice4 <= 0;
            dice5 <= 0;
        end else if (dice_clear) begin
            // clear dice values at the start of each player's turn
            dice1 <= 0;
            dice2 <= 0;
            dice3 <= 0;
            dice4 <= 0;
            dice5 <= 0;
        end else begin
            // advance LFSR every clock
            lfsr_reg <= {lfsr_reg[30:0], feedback};

            // block first roll if any hold switch is ON
            if (roll_en && !(roll_cnt_in == 2'd0 && |hold_sw)) begin
                if (!hold_sw[0]) dice1 <= (lfsr_reg[ 2: 0] % 6) + 1;
                if (!hold_sw[1]) dice2 <= (lfsr_reg[ 5: 3] % 6) + 1;
                if (!hold_sw[2]) dice3 <= (lfsr_reg[ 8: 6] % 6) + 1;
                if (!hold_sw[3]) dice4 <= (lfsr_reg[11: 9] % 6) + 1;
                if (!hold_sw[4]) dice5 <= (lfsr_reg[14:12] % 6) + 1;
            end
        end
    end

endmodule
