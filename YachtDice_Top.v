module YachtDice_Top(
    input CLK,             // 시스템 클럭
    input RST_BTN,         // 리셋 버튼
    input [3:0] BTN,       // BTN0~3
    input [4:0] SW,        // SW1~5 (Hold)
    
    output [7:0] LED,      // LED1~5(Hold), LED7(P1), LED8(P2)
    output [7:0] SEG_DATA, // 7-Segment 데이터
    output [7:0] SEG_SEL,  // 7-Segment 자릿수 선택
    
    // LCD Ports
    output LCD_E,
    output LCD_RS,
    output LCD_RW,
    output [7:0] LCD_DATA
);

    // 내부 연결 신호선 (Wires)
    wire rst_n = ~RST_BTN; // Active Low 변환
    wire btn0_clean, btn1_clean, btn2_clean, btn3_clean;
    wire [2:0] d1, d2, d3, d4, d5;
    wire [1:0] player_turn;
    wire [3:0] state_debug;
    wire roll_sig;
    wire [3:0] cat_idx;
    wire [3:0] round_val;
    wire [8:0] p1_sc, p2_sc;
    wire [7:0] calc_score;

    // 1. 버튼 디바운서 인스턴스 (4개)
    Button_Debouncer db0 (.clk(CLK), .reset_n(rst_n), .btn_in(BTN[0]), .btn_out(btn0_clean));
    Button_Debouncer db1 (.clk(CLK), .reset_n(rst_n), .btn_in(BTN[1]), .btn_out(btn1_clean));
    Button_Debouncer db2 (.clk(CLK), .reset_n(rst_n), .btn_in(BTN[2]), .btn_out(btn2_clean));
    Button_Debouncer db3 (.clk(CLK), .reset_n(rst_n), .btn_in(BTN[3]), .btn_out(btn3_clean));

    // 2. FSM (게임 로직)
    Game_FSM fsm_inst (
        .clk(CLK), .reset_n(rst_n),
        .btn0_roll(btn0_clean), .btn1_sel(btn1_clean), 
        .btn2_prev(btn2_clean), .btn3_next(btn3_clean),
        .current_calc_score(calc_score),
        .current_state(state_debug),
        .player_turn(player_turn),
        .roll_trigger(roll_sig),
        .category_idx(cat_idx),
        .round_num(round_val),
        .p1_score(p1_sc), .p2_score(p2_sc)
    );

    // 3. 주사위 매니저
    Dice_Manager dice_inst (
        .clk(CLK), .reset_n(rst_n),
        .roll_en(roll_sig),
        .hold_sw(SW),
        .dice1(d1), .dice2(d2), .dice3(d3), .dice4(d4), .dice5(d5)
    );

    // 4. 점수 계산기
    Score_Calculator score_inst (
        .d1(d1), .d2(d2), .d3(d3), .d4(d4), .d5(d5),
        .category_sel(cat_idx),
        .score_out(calc_score)
    );

    // 5. 디스플레이 컨트롤러
    Display_Controller disp_inst (
        .clk(CLK), .reset_n(rst_n),
        .d1(d1), .d2(d2), .d3(d3), .d4(d4), .d5(d5),
        .category_idx(cat_idx),
        .round_num(round_val),
        .state(state_debug),
        .seg_data(SEG_DATA), .seg_sel(SEG_SEL)
    );

    // 6. LED 출력 연결
    // LED1~5: Hold 상태 표시 (스위치 그대로 연결)
    // LED7: Player 1 Turn, LED8: Player 2 Turn
    assign LED[4:0] = SW[4:0]; 
    assign LED[5] = 1'b0; // 미사용
    // 7. LCD 컨트롤러 (추가됨)
    LCD_Controller lcd_inst (
        .clk(CLK), .reset_n(rst_n),
        .current_state(state_debug),
        .p1_score(p1_sc), .p2_score(p2_sc),
        .lcd_e(LCD_E), .lcd_rs(LCD_RS), .lcd_rw(LCD_RW), .lcd_data(LCD_DATA)
    );

endmodule