module Display_Controller(
    input clk, reset_n,
    input [2:0] d1, d2, d3, d4, d5, // 주사위 값 (1~6)
    input [3:0] category_idx,       // 카테고리 인덱스 (0~11)
    input [3:0] round_num,          // 현재 라운드 (1~12)
    input [3:0] state,              // 현재 FSM 상태
    output reg [7:0] seg_data,      // 7-Seg 패턴 (a,b,c,d,e,f,g,dp)
    output reg [7:0] seg_sel        // 자릿수 선택 (Active Low)
);
    
    // [설계 변경 사항]
    // SEL0~4: 주사위 1~5
    // SEL6~7: 카테고리 코드

    reg [16:0] scan_cnt; // 스캔 속도 조절
    wire [2:0] scan_idx = scan_cnt[16:14]; // 0~7 순환

    always @(posedge clk) scan_cnt <= scan_cnt + 1;

    reg [4:0] digit_val; // 표시할 값 (0~31로 확장하여 알파벳 포함)
    reg dot_en;          // 소수점 켤지 여부

    // 1. 자릿수별 표시 데이터 결정 (MUX)
    always @(*) begin
        dot_en = 0; // 기본적으로 끔
        case (scan_idx)
            3'd0: digit_val = {2'b00, d1}; // Digit 0: 주사위 1
            3'd1: digit_val = {2'b00, d2}; // Digit 1: 주사위 2
            3'd2: digit_val = {2'b00, d3}; // Digit 2: 주사위 3
            3'd3: digit_val = {2'b00, d4}; // Digit 3: 주사위 4
            3'd4: digit_val = {2'b00, d5}; // Digit 4: 주사위 5
            
            // 3'd5: 라운드 표시 제거 (LCD로 이동)
            3'd5: begin 
                digit_val = 5'h1F; // Blank (1F로 변경)
                dot_en = 0; 
            end
            
            3'd6: begin // Digit 6: 카테고리 앞글자
                if (state == 4 || state == 9) begin
                    case (category_idx)
                        0: begin digit_val = 1; dot_en = 1; end // 1. (Aces)
                        1: begin digit_val = 2; dot_en = 1; end // 2. (Twos)
                        2: begin digit_val = 3; dot_en = 1; end // 3. (Threes)
                        3: begin digit_val = 4; dot_en = 1; end // 4. (Fours)
                        4: begin digit_val = 5; dot_en = 1; end // 5. (Fives)
                        5: begin digit_val = 6; dot_en = 1; end // 6. (Sixes)
                        6: digit_val = 5'h0C; // C (Choice)
                        7: digit_val = 4;     // 4 (4 of a Kind)
                        8: digit_val = 5'h0F; // F (Full House)
                        9: digit_val = 5'h15; // S (Small Straight)
                        10: digit_val = 5'h10; // L (Large Straight)
                        11: digit_val = 5'h19; // Y (Yacht)
                        default: digit_val = 5'h1F;
                    endcase
                end else digit_val = 5'h1F; // 꺼짐
            end
            
            3'd7: begin // Digit 7: 카테고리 뒷글자
                if (state == 4 || state == 9) begin
                    case (category_idx)
                        0: digit_val = 5'h1F; // (꺼짐)
                        1: digit_val = 5'h1F; // (꺼짐)
                        2: digit_val = 5'h1F; // (꺼짐)
                        3: digit_val = 5'h1F; // (꺼짐)
                        4: digit_val = 5'h1F; // (꺼짐)
                        5: digit_val = 5'h1F; // (꺼짐)
                        6: digit_val = 5'h12; // H (CH)
                        7: digit_val = 5'h11; // n (4n)
                        8: digit_val = 5'h12; // H (FH)
                        9: digit_val = 5'h15; // S (SS)
                        10: digit_val = 5'h15; // S (LS)
                        11: digit_val = 5'h0A; // A (YA)
                        default: digit_val = 5'h1F;
                    endcase
                end else digit_val = 5'h1F; // 꺼짐
            end
            
            default: digit_val = 5'h1F; // Blank
        endcase
    end

    // 2. 7-Segment 패턴 디코딩 (Active Low: 0이 켜짐)
    always @(*) begin
        case (digit_val)
            5'h00: seg_data = 8'b1100_0000; // 0
            5'h01: seg_data = 8'b1111_1001; // 1
            5'h02: seg_data = 8'b1010_0100; // 2
            5'h03: seg_data = 8'b1011_0000; // 3
            5'h04: seg_data = 8'b1001_1001; // 4
            5'h05: seg_data = 8'b1001_0010; // 5
            5'h06: seg_data = 8'b1000_0010; // 6
            5'h07: seg_data = 8'b1111_1000; // 7
            5'h08: seg_data = 8'b1000_0000; // 8
            5'h09: seg_data = 8'b1001_0000; // 9
            
            // 알파벳 패턴 정의
            5'h0A: seg_data = 8'b1000_1000; // A (YA)
            5'h0C: seg_data = 8'b1100_0110; // C (CH)
            5'h0F: seg_data = 8'b1000_1110; // F (FH)
            
            5'h10: seg_data = 8'b1100_0111; // L (LS)
            5'h11: seg_data = 8'b1010_1011; // n (4n)
            5'h12: seg_data = 8'b1000_1001; // H (CH, FH)
            5'h15: seg_data = 8'b1001_0010; // S (SS, LS)
            5'h19: seg_data = 8'b1001_0001; // Y (YA)
            
            5'h1F: seg_data = 8'b1111_1111; // OFF (Blank)
            default: seg_data = 8'b1111_1111;
        endcase
        
        // 소수점(DP) 제어: 7번 비트가 DP (Active Low)
        if (dot_en) seg_data[7] = 0; 
        
        // 자릿수 선택 (Active Low)
        seg_sel = ~(1 << scan_idx);
    end

endmodule