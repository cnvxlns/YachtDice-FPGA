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
    // SEL5:   라운드 (16진수로 표시: 1~9, A, B, C)
    // SEL6~7: 카테고리 코드

    reg [16:0] scan_cnt; // 스캔 속도 조절
    wire [2:0] scan_idx = scan_cnt[16:14]; // 0~7 순환

    always @(posedge clk) scan_cnt <= scan_cnt + 1;

    reg [3:0] digit_val; // 표시할 값(0~F)
    reg dot_en;          // 소수점 켤지 여부

    // 1. 자릿수별 표시 데이터 결정 (MUX)
    always @(*) begin
        dot_en = 0; // 기본적으로 끔
        case (scan_idx)
            3'd0: digit_val = {1'b0, d1}; // Digit 0: 주사위 1
            3'd1: digit_val = {1'b0, d2}; // Digit 1: 주사위 2
            3'd2: digit_val = {1'b0, d3}; // Digit 2: 주사위 3
            3'd3: digit_val = {1'b0, d4}; // Digit 3: 주사위 4
            3'd4: digit_val = {1'b0, d5}; // Digit 4: 주사위 5
            
            // 3'd5: 라운드 표시 제거 (LCD로 이동)
            3'd5: begin 
                digit_val = 4'hF; // Blank
                dot_en = 0; 
            end
            
            3'd6: begin // Digit 6: 카테고리 십의 자리 (또는 코드 앞글자)
                // 점수 선택 모드(4, 9)일 때만 표시
                if (state == 4 || state == 9) begin
                     // 예: category 10 -> '1', category 5 -> '0'
                     digit_val = (category_idx >= 10) ? 1 : 0;
                end else digit_val = 4'hF; // 꺼짐(Blank)
            end
            
            3'd7: begin // Digit 7: 카테고리 일의 자리
                if (state == 4 || state == 9) begin
                     digit_val = (category_idx >= 10) ? (category_idx - 10) : category_idx;
                end else digit_val = 4'hF; // 꺼짐
            end
            
            default: digit_val = 4'hF; // Blank
        endcase
    end

    // 2. 7-Segment 패턴 디코딩 (Active Low: 0이 켜짐)
    always @(*) begin
        case (digit_val)
            4'h0: seg_data = 8'b1100_0000; // 0
            4'h1: seg_data = 8'b1111_1001; // 1
            4'h2: seg_data = 8'b1010_0100; // 2
            4'h3: seg_data = 8'b1011_0000; // 3
            4'h4: seg_data = 8'b1001_1001; // 4
            4'h5: seg_data = 8'b1001_0010; // 5
            4'h6: seg_data = 8'b1000_0010; // 6
            4'h7: seg_data = 8'b1111_1000; // 7
            4'h8: seg_data = 8'b1000_0000; // 8
            4'h9: seg_data = 8'b1001_0000; // 9
            4'hA: seg_data = 8'b1000_1000; // A (10라운드)
            4'hB: seg_data = 8'b1000_0011; // b (11라운드)
            4'hC: seg_data = 8'b1100_0110; // C (12라운드)
            4'hF: seg_data = 8'b1111_1111; // OFF (Blank)
            default: seg_data = 8'b1111_1111;
        endcase
        
        // 소수점(DP) 제어: 7번 비트가 DP (Active Low)
        if (dot_en) seg_data[7] = 0; 
        
        // 자릿수 선택 (Active Low)
        seg_sel = ~(1 << scan_idx);
    end

endmodule