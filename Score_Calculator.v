module Score_Calculator(
    input [2:0] d1, d2, d3, d4, d5, // 주사위 5개 값
    input [3:0] category_sel,       // 선택한 점수 카테고리 (0~11)
    output reg [7:0] score_out      // 계산된 점수
);
    // [작동 원리]
    // 1. 각 주사위 눈금(1~6)이 몇 개 나왔는지 개수(Count)를 셉니다.
    // 2. 카테고리(category_sel)에 따라 조건문을 수행하여 점수를 부여합니다.
    
    integer i;
    reg [2:0] count [1:6]; // 1~6 눈금의 등장 횟수 저장
    reg [5:0] sum_all;     // 주사위 5개의 합

    always @(*) begin
        // 변수 초기화
        for (i=1; i<=6; i=i+1) count[i] = 0;
        sum_all = d1 + d2 + d3 + d4 + d5;
        score_out = 0;

        // 눈금 개수 세기
        count[d1] = count[d1] + 1;
        count[d2] = count[d2] + 1;
        count[d3] = count[d3] + 1;
        count[d4] = count[d4] + 1;
        count[d5] = count[d5] + 1;

        // 카테고리별 점수 계산
        case (category_sel)
            // 상단 항목 (숫자 합)
            4'd0: score_out = count[1] * 1; // Aces (1의 합)
            4'd1: score_out = count[2] * 2; // Twos
            4'd2: score_out = count[3] * 3; // Threes
            4'd3: score_out = count[4] * 4; // Fours
            4'd4: score_out = count[5] * 5; // Fives
            4'd5: score_out = count[6] * 6; // Sixes
            
            // 하단 항목 (족보)
            4'd6: begin // Choice (모든 합)
                score_out = sum_all; 
            end
            4'd7: begin // 4 of a Kind (같은 숫자 4개 이상)
                if (count[1]>=4) score_out = 1 * 4;
                else if (count[2]>=4) score_out = 2 * 4;
                else if (count[3]>=4) score_out = 3 * 4;
                else if (count[4]>=4) score_out = 4 * 4;
                else if (count[5]>=4) score_out = 5 * 4;
                else if (count[6]>=4) score_out = 6 * 4;
                else score_out = 0;
            end
            4'd8: begin // Full House (3장 동일 + 2장 동일)
                // (3장, 2장) 조합 혹은 (5장 모두 동일)인 경우
                // 로직 단순화를 위해 3장인 숫자와 2장인 숫자가 존재하는지 확인
                if ((count[1]==3 || count[2]==3 || count[3]==3 || count[4]==3 || count[5]==3 || count[6]==3) &&
                    (count[1]==2 || count[2]==2 || count[3]==2 || count[4]==2 || count[5]==2 || count[6]==2))
                    score_out = sum_all; // 주사위 5개의 총 합
                else if (count[1]==5 || count[2]==5 || count[3]==5 || count[4]==5 || count[5]==5 || count[6]==5)
                    score_out = sum_all; // Yacht인 경우도 Full House 인정 (총 합)
                else score_out = 0;
            end
            4'd9: begin // Small Straight (4개 연속) -> 구현 복잡하여 예시 단순화 (실제로는 정렬 필요)
                 // 여기서는 간단히 1,2,3,4 or 2,3,4,5 or 3,4,5,6 존재 여부 체크
                 if ((count[1]&&count[2]&&count[3]&&count[4]) || 
                     (count[2]&&count[3]&&count[4]&&count[5]) || 
                     (count[3]&&count[4]&&count[5]&&count[6]))
                     score_out = 15;
                 else score_out = 0;
            end
            4'd10: begin // Large Straight (5개 연속)
                 if ((count[1]&&count[2]&&count[3]&&count[4]&&count[5]) || 
                     (count[2]&&count[3]&&count[4]&&count[5]&&count[6]))
                     score_out = 30;
                 else score_out = 0;
            end
            4'd11: begin // Yacht (5개 모두 동일)
                if (count[1]==5 || count[2]==5 || count[3]==5 || count[4]==5 || count[5]==5 || count[6]==5)
                    score_out = 50;
                else score_out = 0;
            end
            default: score_out = 0;
        endcase
    end
endmodule