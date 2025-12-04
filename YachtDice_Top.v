module YachtDice_Top(
    input CLK,             // system clock
    input RST_BTN,         // active-high reset button
    input [5:0] BTN,       // BTN0~5 (Key01~Key06)
    input [4:0] SW,        // SW1~5 (Hold)
    
    output [7:0] LED,      // LED1~5(Hold), LED7(P1), LED8(P2)
    output [7:0] SEG_DATA, // 7-Segment segment lines
    output [7:0] SEG_SEL,  // 7-Segment digit select
    
    // LCD Ports
    output LCD_E,
    output LCD_RS,
    output LCD_RW,
    output [7:0] LCD_DATA
);
    // Reset is active-low inside modules
    wire rst_n = ~RST_BTN;
    
    wire btn0_clean, btn1_clean, btn2_clean, btn3_clean;
    wire [2:0] d1, d2, d3, d4, d5;
    wire [1:0] player_turn;
    wire [3:0] state_debug;
    wire roll_sig;
    wire [3:0] cat_idx;
    wire [3:0] round_val;
    wire [8:0] p1_sc, p2_sc;
    wire [7:0] calc_score;
    wire [1:0] roll_cnt_dbg;
    wire dice_clear;

    // 1. Button debounce
    Button_Debouncer db0 (.clk(CLK), .reset_n(rst_n), .btn_in(~BTN[0]), .btn_out(btn0_clean)); // Roll
    Button_Debouncer db1 (.clk(CLK), .reset_n(rst_n), .btn_in(~BTN[1]), .btn_out(btn1_clean)); // Select
    Button_Debouncer db2 (.clk(CLK), .reset_n(rst_n), .btn_in(~BTN[4]), .btn_out(btn2_clean)); // Prev (Key05)
    Button_Debouncer db3 (.clk(CLK), .reset_n(rst_n), .btn_in(~BTN[5]), .btn_out(btn3_clean)); // Next (Key06)

    // 2. FSM
    Game_FSM fsm_inst (
        .clk(CLK), .reset_n(rst_n),
        .btn0_roll(btn0_clean), .btn1_sel(btn1_clean), 
        .btn2_prev(btn2_clean), .btn3_next(btn3_clean),
        .hold_sw(SW),
        .current_calc_score(calc_score),
        .current_state(state_debug),
        .player_turn(player_turn),
        .roll_trigger(roll_sig),
        .roll_cnt_out(roll_cnt_dbg),
        .dice_clear(dice_clear),
        .category_idx(cat_idx),
        .round_num(round_val),
        .p1_score(p1_sc), .p2_score(p2_sc)
    );

    // 3. Dice manager
    Dice_Manager dice_inst (
        .clk(CLK), .reset_n(rst_n),
        .roll_en(roll_sig),
        .hold_sw(SW),
        .roll_cnt_in(roll_cnt_dbg),
        .dice_clear(dice_clear),
        .dice1(d1), .dice2(d2), .dice3(d3), .dice4(d4), .dice5(d5)
    );

    // 4. Score calculator
    Score_Calculator score_inst (
        .d1(d1), .d2(d2), .d3(d3), .d4(d4), .d5(d5),
        .category_sel(cat_idx),
        .score_out(calc_score)
    );

    // 5. 7-seg display
    Display_Controller disp_inst (
        .clk(CLK), .reset_n(rst_n),
        .d1(d1), .d2(d2), .d3(d3), .d4(d4), .d5(d5),
        .category_idx(cat_idx),
        .round_num(round_val),
        .state(state_debug),
        .seg_data(SEG_DATA), .seg_sel(SEG_SEL)
    );

    // 6. LEDs
    assign LED[4:0] = SW[4:0]; 
    assign LED[5] = 1'b0;
    assign LED[6] = (player_turn == 2'd1);
    assign LED[7] = (player_turn == 2'd2);

    // 7. LCD
    LCD_Controller lcd_inst (
        .clk(CLK), .reset_n(rst_n),
        .current_state(state_debug),
        .round_num(round_val),
        .p1_score(p1_sc), .p2_score(p2_sc),
        .lcd_e(LCD_E), .lcd_rs(LCD_RS), .lcd_rw(LCD_RW), .lcd_data(LCD_DATA)
    );

endmodule
