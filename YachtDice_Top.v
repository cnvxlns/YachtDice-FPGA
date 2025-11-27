module Score_Calculator(
    input [2:0] d1, d2, d3, d4, d5,
    input [3:0] category_sel,       // 0~11
    output reg [7:0] score_out
);
    integer i;
    reg [2:0] count [1:6];
    reg [5:0] sum_all;

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
