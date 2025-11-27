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
    
    // 상단 보너스 계산을 위한 레지스터
    reg [8:0] p1_upper_sum, p2_upper_sum;

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
    
    // roll_trigger를 조합 회로로 변경하여 상태 진입 즉시 신호 발생
    always @(*) begin
        roll_trigger = (state == S_P1_ROLL || state == S_P2_ROLL);
    end

    always @(posedge clk or negedge reset_n) begin
        if (!reset_n) begin
            round_num <= 1;
            p1_score <= 0; p2_score <= 0;
            roll_cnt <= 0;
            category_idx <= 0;
            // roll_trigger <= 0; // 조합 회로로 이동
            player_turn <= 0;
        end else begin
            // roll_trigger <= (state == S_P1_ROLL || state == S_P2_ROLL); // 삭제

            current_state <= state; // 디버깅용

            case (state)
                S_INIT: begin
                    round_num <= 1; 
                    p1_score <= 0; p2_score <= 0;
                    p1_upper_sum <= 0; p2_upper_sum <= 0;
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
                    // 상단 항목(0~5)인 경우 상단 점수 누적
                    if (category_idx <= 5) p1_upper_sum <= p1_upper_sum + current_calc_score;
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
                    // 상단 항목(0~5)인 경우 상단 점수 누적
                    if (category_idx <= 5) p2_upper_sum <= p2_upper_sum + current_calc_score;
                end

                S_ROUND_CHK: begin
                    // 라운드 증가 (P2 턴 끝날 때만)
                    if (next_state == S_P1_START) begin
                        round_num <= round_num + 1;
                    end else if (next_state == S_GAME_END) begin
                        // 게임 종료 직전 상단 보너스 정산
                        if (p1_upper_sum >= 63) p1_score <= p1_score + 35;
                        if (p2_upper_sum >= 63) p2_score <= p2_score + 35;
                    end
                end
                
                S_GAME_END: begin
                    // 게임 종료 시 상단 보너스 체크 (63점 이상이면 +35점)
                    // 한 번만 더해지도록 로직 처리가 필요하지만, 
                    // 여기서는 S_GAME_END 상태 진입 직전에 처리하거나, 
                    // S_ROUND_CHK에서 마지막 라운드일 때 미리 더해주는 것이 안전함.
                    // 간단하게 구현하기 위해 S_ROUND_CHK에서 마지막 라운드 종료 시 처리하도록 수정 권장.
                    // 하지만 현재 구조상 S_GAME_END에서 계속 머무르므로, 
                    // S_ROUND_CHK -> S_GAME_END 넘어가는 시점에 더해주는 로직을 S_ROUND_CHK에 추가하겠습니다.
                end
            endcase
        end
    end
endmodule