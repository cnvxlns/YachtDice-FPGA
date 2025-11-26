module Game_FSM(
    input clk, reset_n,
    input btn0_roll, btn1_sel, btn2_prev, btn3_next, // 디바운스된 버튼
    input [7:0] current_calc_score, // 계산된 현재 점수

    output reg [3:0] current_state, // 디버깅용 상태 출력
    output reg [1:0] player_turn,   // 1: P1, 2: P2
    output reg roll_trigger,        // 주사위 굴리기 신호
    output reg [3:0] category_idx,  // 현재 선택 중인 카테고리 인덱스
    output reg [3:0] round_num,     // 현재 라운드 (1~12)
    output reg [8:0] p1_score,      // P1 총점 (최대 300점대 가정)
    output reg [8:0] p2_score       // P2 총점
);

    // 상태 정의 (One-Hot Encoding or Binary)
    localparam S_INIT = 0, S_P1_START = 1, S_P1_WAIT = 2, S_P1_ROLL = 3, 
               S_P1_SELECT = 4, S_P1_CALC = 5,
               S_P2_START = 6, S_P2_WAIT = 7, S_P2_ROLL = 8, 
               S_P2_SELECT = 9, S_P2_CALC = 10,
               S_ROUND_CHK = 11, S_GAME_END = 12;

    reg [3:0] state, next_state;
    reg [1:0] roll_cnt; // 턴당 3회 제한

    // 1. 상태 천이 로직 (State Transition)
    always @(posedge clk or negedge reset_n) begin
        if (!reset_n) state <= S_INIT;
        else state <= next_state;
    end

    // 2. 다음 상태 결정 (Next State Logic)
    always @(*) begin
        next_state = state;
        case (state)
            S_INIT: next_state = S_P1_START;
            
            // --- PLAYER 1 ---
            S_P1_START: next_state = S_P1_WAIT;
            S_P1_WAIT: begin
                if (btn0_roll && roll_cnt < 3) next_state = S_P1_ROLL;
                else if (btn1_sel) next_state = S_P1_SELECT; // 롤 포기하고 점수 선택
            end
            S_P1_ROLL: begin
                // 롤 카운트가 3번 찼으면 강제로 선택 모드, 아니면 대기
                if (roll_cnt == 3) next_state = S_P1_SELECT; 
                else next_state = S_P1_WAIT;
            end
            S_P1_SELECT: begin
                if (btn1_sel) next_state = S_P1_CALC; // 카테고리 확정
            end
            S_P1_CALC: next_state = S_P2_START;

            // --- PLAYER 2 (P1과 대칭) ---
            S_P2_START: next_state = S_P2_WAIT;
            S_P2_WAIT: begin
                if (btn0_roll && roll_cnt < 3) next_state = S_P2_ROLL;
                else if (btn1_sel) next_state = S_P2_SELECT;
            end
            S_P2_ROLL: begin
                if (roll_cnt == 3) next_state = S_P2_SELECT; 
                else next_state = S_P2_WAIT;
            end
            S_P2_SELECT: begin
                if (btn1_sel) next_state = S_P2_CALC;
            end
            S_P2_CALC: next_state = S_ROUND_CHK;

            // --- ROUND CHECK ---
            S_ROUND_CHK: begin
                if (round_num >= 12) next_state = S_GAME_END;
                else next_state = S_P1_START;
            end
            S_GAME_END: next_state = S_GAME_END; // 무한 루프 (리셋 필요)
        endcase
    end

    // 3. 출력 및 데이터 처리 로직 (Output Logic)
    always @(posedge clk or negedge reset_n) begin
        if (!reset_n) begin
            round_num <= 1;
            p1_score <= 0; p2_score <= 0;
            roll_cnt <= 0;
            category_idx <= 0;
            roll_trigger <= 0;
            player_turn <= 0;
        end else begin
            // 롤 트리거는 Pulse 형태로 만들어줘야 함 (여기선 상태 기반으로 제어)
            roll_trigger <= (state == S_P1_ROLL || state == S_P2_ROLL);

            current_state <= state; // 디버깅용

            case (state)
                S_INIT: begin
                    round_num <= 1; p1_score <= 0; p2_score <= 0;
                end
                S_P1_START: begin
                    player_turn <= 1;
                    roll_cnt <= 0;
                end
                S_P1_ROLL: begin
                    // 상태 진입 시 1회만 증가하도록 엣지 디텍션 필요하나, 
                    // FSM 구조상 다음 클럭에 바로 빠져나가므로 여기서 증가시켜도 됨
                    // (실제 구현 시엔 타이밍 주의)
                    if (next_state != S_P1_ROLL) roll_cnt <= roll_cnt + 1;
                end
                S_P1_SELECT: begin
                    // 카테고리 탐색 (BTN2: 이전, BTN3: 다음)
                    if (btn3_next) category_idx <= (category_idx == 11) ? 0 : category_idx + 1;
                    else if (btn2_prev) category_idx <= (category_idx == 0) ? 11 : category_idx - 1;
                end
                S_P1_CALC: begin
                    p1_score <= p1_score + current_calc_score;
                end
                
                S_P2_START: begin
                    player_turn <= 2;
                    roll_cnt <= 0;
                end
                S_P2_ROLL: begin
                     if (next_state != S_P2_ROLL) roll_cnt <= roll_cnt + 1;
                end
                S_P2_SELECT: begin
                    if (btn3_next) category_idx <= (category_idx == 11) ? 0 : category_idx + 1;
                    else if (btn2_prev) category_idx <= (category_idx == 0) ? 11 : category_idx - 1;
                end
                S_P2_CALC: begin
                    p2_score <= p2_score + current_calc_score;
                end

                S_ROUND_CHK: begin
                    // 라운드 증가 (P2 턴 끝날 때만)
                    if (next_state == S_P1_START) round_num <= round_num + 1;
                end
            endcase
        end
    end
endmodule