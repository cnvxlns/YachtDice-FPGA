module YachtDice_Top(
    input CLK,             // 시스템 클럭
    input RST_BTN,         // 리셋 버튼
    input [5:0] BTN,       // BTN0~5 (Key01~Key06)
    input [4:0] SW,        // SW1~5 (Hold)
    
    output [7:0] LED,      // LED1~5(Hold), LED7(P1), LED8(P2)
    output [7:0] SEG_DATA, // 7-Segment 데이터
    output [7:0] SEG_SEL,  // 7-Segment 자릿수 선택
    
    // LCD Ports
    output LCD_E,          // LCD Enable 신호
    output LCD_RS,         // 레지스터 선택 (0:명령, 1:데이터)
    output LCD_RW,         // 읽기/쓰기 선택 (0:쓰기, 1:읽기)
    output [7:0] LCD_DATA  // LCD 데이터 버스
);

    // 내부 연결 신호선 (Wires)
    // RST_BTN이 눌렀을 때 High(1), 뗐을 때 Low(0)로 동작하는 경우 (Active High)
    // 시스템은 Active Low 리셋을 사용하므로 반전시켜줍니다.
    // 눌렀을 때(1) -> 0 (Reset), 뗐을 때(0) -> 1 (Run)
    wire rst_n = ~RST_BTN; 
    
    wire btn0_clean, btn1_clean, btn2_clean, btn3_clean; // 디바운싱된 버튼 신호
    wire [2:0] d1, d2, d3, d4, d5; // 주사위 1~5의 값 (1~6)
    wire [1:0] player_turn;        // 현재 턴인 플레이어 (1: P1, 2: P2)
    wire [3:0] state_debug;        // FSM 현재 상태 (디버깅/표시용)
    wire roll_sig;                 // 주사위 굴리기 트리거 신호
    wire [3:0] cat_idx;            // 선택된 족보(카테고리) 인덱스
    wire [3:0] round_val;          // 현재 라운드 (1~12)
    wire [8:0] p1_sc, p2_sc;       // 플레이어 1, 2의 총점
    wire [7:0] calc_score;         // 현재 주사위 조합에 대한 예상 점수

    // 1. 버튼 디바운서 인스턴스
    // BTN[0] (Key01): Roll
    // BTN[1] (Key02): Select
    // BTN[4] (Key05): Prev (변경됨)
    // BTN[5] (Key06): Next (변경됨)
    // 버튼이 Active High(누르면 1)인 것으로 추정되므로 반전(~)을 제거합니다.
    Button_Debouncer db0 (.clk(CLK), .reset_n(rst_n), .btn_in(BTN[0]), .btn_out(btn0_clean));
    Button_Debouncer db1 (.clk(CLK), .reset_n(rst_n), .btn_in(BTN[1]), .btn_out(btn1_clean));
    Button_Debouncer db2 (.clk(CLK), .reset_n(rst_n), .btn_in(BTN[4]), .btn_out(btn2_clean)); // Key05
    Button_Debouncer db3 (.clk(CLK), .reset_n(rst_n), .btn_in(BTN[5]), .btn_out(btn3_clean)); // Key06

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
    // LED6: 점수 선택 모드 (Select Phase) 표시
    // LED7: Player 1 Turn, LED8: Player 2 Turn
    assign LED[4:0] = SW[4:0]; 
    assign LED[5] = (state_debug == 4'd4 || state_debug == 4'd9); // S_P1_SELECT(4) or S_P2_SELECT(9)
    assign LED[6] = (player_turn == 2'd1); // P1 Turn
    assign LED[7] = (player_turn == 2'd2); // P2 Turn

    // 7. LCD 컨트롤러 (추가됨)
    LCD_Controller lcd_inst (
        .clk(CLK), .reset_n(rst_n),
        .current_state(state_debug),
        .round_num(round_val),
        .p1_score(p1_sc), .p2_score(p2_sc),
        .lcd_e(LCD_E), .lcd_rs(LCD_RS), .lcd_rw(LCD_RW), .lcd_data(LCD_DATA)
    );

endmodule