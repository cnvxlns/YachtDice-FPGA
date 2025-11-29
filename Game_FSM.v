module Game_FSM(
    input clk, reset_n,
    input btn0_roll, btn1_sel, btn2_prev, btn3_next,
    input [7:0] current_calc_score,

    output reg [3:0] current_state,
    output reg [1:0] player_turn,        // 1: P1, 2: P2
    output reg roll_trigger,
    output reg [3:0] category_idx,
    output reg [3:0] round_num,          // 1~12
    output reg [8:0] p1_score,
    output reg [8:0] p2_score
);

    localparam S_INIT = 0, S_P1_START = 1, S_P1_WAIT = 2, S_P1_ROLL = 3,
               S_P1_SELECT = 4, S_P1_CALC = 5,
               S_P2_START = 6, S_P2_WAIT = 7, S_P2_ROLL = 8,
               S_P2_SELECT = 9, S_P2_CALC = 10,
               S_ROUND_CHK = 11, S_GAME_END = 12;

    reg [3:0] state, next_state;
    reg [1:0] roll_cnt;
    reg [11:0] used_mask_p1, used_mask_p2; // 1이면 이미 사용한 카테고리

    // 유틸리티: 현재 마스크에서 처음 사용 가능한 인덱스
    function [3:0] first_free;
        input [11:0] mask;
        integer k;
        reg found;
        begin
            first_free = 0;
            found = 0;
            for (k = 0; k < 12; k = k + 1) begin
                if (!mask[k] && !found) begin
                    first_free = k[3:0];
                    found = 1;
                end
            end
        end
    endfunction

    // 유틸리티: 현 위치 기준 다음/이전 사용 가능 인덱스
    function [3:0] next_free;
        input [3:0] cur;
        input dir;           // 1: +1, 0: -1
        input [11:0] mask;
        integer k;
        reg [3:0] idx;
        reg found;
        begin
            next_free = cur;
            found = 0;
            idx = cur;
            for (k = 0; k < 12; k = k + 1) begin
                idx = dir ? (idx == 11 ? 0 : idx + 1) : (idx == 0 ? 11 : idx - 1);
                if (!mask[idx] && !found) begin
                    next_free = idx;
                    found = 1;
                end
            end
        end
    endfunction

    // 상태 천이
    always @(posedge clk or negedge reset_n) begin
        if (!reset_n) state <= S_INIT;
        else state <= next_state;
    end

    // Next state
    always @(*) begin
        next_state = state;
        case (state)
            S_INIT: next_state = S_P1_START;
            S_P1_START: next_state = S_P1_WAIT;
            S_P1_WAIT: begin
                if (btn0_roll && roll_cnt < 3) next_state = S_P1_ROLL;
                else if (btn1_sel) next_state = S_P1_SELECT;
            end
            S_P1_ROLL: next_state = (roll_cnt == 3) ? S_P1_SELECT : S_P1_WAIT;
            S_P1_SELECT: if (btn1_sel && !used_mask_p1[category_idx]) next_state = S_P1_CALC;
            S_P1_CALC: next_state = S_P2_START;

            S_P2_START: next_state = S_P2_WAIT;
            S_P2_WAIT: begin
                if (btn0_roll && roll_cnt < 3) next_state = S_P2_ROLL;
                else if (btn1_sel) next_state = S_P2_SELECT;
            end
            S_P2_ROLL: next_state = (roll_cnt == 3) ? S_P2_SELECT : S_P2_WAIT;
            S_P2_SELECT: if (btn1_sel && !used_mask_p2[category_idx]) next_state = S_P2_CALC;
            S_P2_CALC: next_state = S_ROUND_CHK;

            S_ROUND_CHK: next_state = (round_num >= 12) ? S_GAME_END : S_P1_START;
            S_GAME_END: next_state = S_GAME_END;
        endcase
    end

    // 출력 및 상태별 처리
    always @(posedge clk or negedge reset_n) begin
        if (!reset_n) begin
            round_num <= 1;
            p1_score <= 0; p2_score <= 0;
            roll_cnt <= 0;
            category_idx <= 0;
            roll_trigger <= 0;
            player_turn <= 0;
            used_mask_p1 <= 0;
            used_mask_p2 <= 0;
        end else begin
            roll_trigger <= (state == S_P1_ROLL || state == S_P2_ROLL);
            current_state <= state;

            case (state)
                S_INIT: begin
                    round_num <= 1; p1_score <= 0; p2_score <= 0;
                    used_mask_p1 <= 0; used_mask_p2 <= 0;
                    category_idx <= 0;
                end
                S_P1_START: begin
                    player_turn <= 1;
                    roll_cnt <= 0;
                    category_idx <= first_free(used_mask_p1);
                end
                S_P1_WAIT: begin
                    if (btn3_next) category_idx <= next_free(category_idx, 1'b1, used_mask_p1);
                    else if (btn2_prev) category_idx <= next_free(category_idx, 1'b0, used_mask_p1);
                end
                S_P1_ROLL: if (next_state != S_P1_ROLL) roll_cnt <= roll_cnt + 1;
                S_P1_SELECT: begin
                    if (btn3_next) category_idx <= next_free(category_idx, 1'b1, used_mask_p1);
                    else if (btn2_prev) category_idx <= next_free(category_idx, 1'b0, used_mask_p1);
                    else if (used_mask_p1[category_idx]) category_idx <= first_free(used_mask_p1);
                end
                S_P1_CALC: begin
                    p1_score <= p1_score + current_calc_score;
                    used_mask_p1[category_idx] <= 1'b1;
                end

                S_P2_START: begin
                    player_turn <= 2;
                    roll_cnt <= 0;
                    category_idx <= first_free(used_mask_p2);
                end
                S_P2_WAIT: begin
                    if (btn3_next) category_idx <= next_free(category_idx, 1'b1, used_mask_p2);
                    else if (btn2_prev) category_idx <= next_free(category_idx, 1'b0, used_mask_p2);
                end
                S_P2_ROLL: if (next_state != S_P2_ROLL) roll_cnt <= roll_cnt + 1;
                S_P2_SELECT: begin
                    if (btn3_next) category_idx <= next_free(category_idx, 1'b1, used_mask_p2);
                    else if (btn2_prev) category_idx <= next_free(category_idx, 1'b0, used_mask_p2);
                    else if (used_mask_p2[category_idx]) category_idx <= first_free(used_mask_p2);
                end
                S_P2_CALC: begin
                    p2_score <= p2_score + current_calc_score;
                    used_mask_p2[category_idx] <= 1'b1;
                end

                S_ROUND_CHK: if (next_state == S_P1_START) round_num <= round_num + 1;
            endcase
        end
    end
endmodule