<<<<<<< HEAD
module Score_Calculator(
    input [2:0] d1, d2, d3, d4, d5,
    input [3:0] category_sel,       // 0~11
    output reg [7:0] score_out
=======
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
>>>>>>> 0c3cb4fed3063647abc77ad9768dd2ccd4a481e9
);
    integer i;
    reg [2:0] count [1:6];
    reg [5:0] sum_all;

<<<<<<< HEAD
    always @(*) begin
        for (i=1; i<=6; i=i+1) count[i] = 0;
        sum_all = d1 + d2 + d3 + d4 + d5;
        score_out = 0;

        count[d1] = count[d1] + 1;
        count[d2] = count[d2] + 1;
        count[d3] = count[d3] + 1;
        count[d4] = count[d4] + 1;
        count[d5] = count[d5] + 1;

        case (category_sel)
            4'd0: score_out = count[1] * 1;
            4'd1: score_out = count[2] * 2;
            4'd2: score_out = count[3] * 3;
            4'd3: score_out = count[4] * 4;
            4'd4: score_out = count[5] * 5;
            4'd5: score_out = count[6] * 6;
            4'd6: score_out = sum_all; // Choice
            4'd7: score_out = (count[1]>=4 || count[2]>=4 || count[3]>=4 ||
                               count[4]>=4 || count[5]>=4 || count[6]>=4) ? sum_all : 0;
            4'd8: begin // Full House
                if ((count[1]==3 || count[2]==3 || count[3]==3 || count[4]==3 || count[5]==3 || count[6]==3) &&
                    (count[1]==2 || count[2]==2 || count[3]==2 || count[4]==2 || count[5]==2 || count[6]==2))
                    score_out = 25;
                else if (count[1]==5 || count[2]==5 || count[3]==5 || count[4]==5 || count[5]==5 || count[6]==5)
                    score_out = 25;
                else score_out = 0;
            end
            4'd9: score_out = ((count[1]&&count[2]&&count[3]&&count[4]) ||
                               (count[2]&&count[3]&&count[4]&&count[5]) ||
                               (count[3]&&count[4]&&count[5]&&count[6])) ? 30 : 0;
            4'd10: score_out = ((count[1]&&count[2]&&count[3]&&count[4]&&count[5]) ||
                                (count[2]&&count[3]&&count[4]&&count[5]&&count[6])) ? 40 : 0;
            4'd11: score_out = (count[1]==5 || count[2]==5 || count[3]==5 ||
                                count[4]==5 || count[5]==5 || count[6]==5) ? 50 : 0;
            default: score_out = 0;
        endcase
    end
endmodule
=======
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
    Button_Debouncer db0 (.clk(CLK), .reset_n(rst_n), .btn_in(~BTN[0]), .btn_out(btn0_clean));
    Button_Debouncer db1 (.clk(CLK), .reset_n(rst_n), .btn_in(~BTN[1]), .btn_out(btn1_clean));
    Button_Debouncer db2 (.clk(CLK), .reset_n(rst_n), .btn_in(~BTN[4]), .btn_out(btn2_clean)); // Key05
    Button_Debouncer db3 (.clk(CLK), .reset_n(rst_n), .btn_in(~BTN[5]), .btn_out(btn3_clean)); // Key06

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
>>>>>>> 0c3cb4fed3063647abc77ad9768dd2ccd4a481e9
