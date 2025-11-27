module Display_Controller(
    input clk, reset_n,
    input [2:0] d1, d2, d3, d4, d5, // dice (1~6)
    input [3:0] category_idx,       // category index (0~11)
    input [3:0] round_num,          // round (1~12) - not shown here (LCD handles)
    input [3:0] state,              // FSM state
    output reg [7:0] seg_data,      // (a,b,c,d,e,f,g,dp) active-high
    output reg [7:0] seg_sel        // digit select active-high
);
    // SEL0~4: dice 1~5, SEL5: (blank), SEL6~7: category code
    reg [16:0] scan_cnt;
    wire [2:0] scan_idx = scan_cnt[16:14];

    always @(posedge clk) scan_cnt <= scan_cnt + 1;

    reg [3:0] digit_val;
    reg dot_en;

    // Digit MUX
    always @(*) begin
        dot_en = 1'b0;
        case (scan_idx)
            3'd0: digit_val = {1'b0, d1};
            3'd1: digit_val = {1'b0, d2};
            3'd2: digit_val = {1'b0, d3};
            3'd3: digit_val = {1'b0, d4};
            3'd4: digit_val = {1'b0, d5};
            3'd5: begin
                digit_val = 4'hF; // blank
                dot_en = 1'b0;
            end
            3'd6: begin // tens of category
                if (state == 4 || state == 9)
                    digit_val = (category_idx >= 10) ? 1 : 0;
                else digit_val = 4'hF;
            end
            3'd7: begin // ones of category
                if (state == 4 || state == 9)
                    digit_val = (category_idx >= 10) ? (category_idx - 10) : category_idx;
                else digit_val = 4'hF;
            end
            default: digit_val = 4'hF;
        endcase
    end

    // 7-seg encoding (active-high)
    always @(*) begin
        case (digit_val)
            4'h0: seg_data = 8'b0011_1111;
            4'h1: seg_data = 8'b0000_0110;
            4'h2: seg_data = 8'b0101_1011;
            4'h3: seg_data = 8'b0100_1111;
            4'h4: seg_data = 8'b0110_0110;
            4'h5: seg_data = 8'b0110_1101;
            4'h6: seg_data = 8'b0111_1101;
            4'h7: seg_data = 8'b0000_0111;
            4'h8: seg_data = 8'b0111_1111;
            4'h9: seg_data = 8'b0110_1111;
            4'hA: seg_data = 8'b0111_0111; // round 10 marker
            4'hB: seg_data = 8'b0111_1100; // round 11 marker
            4'hC: seg_data = 8'b0011_1001; // round 12 marker
            4'hF: seg_data = 8'b0000_0000; // OFF
            default: seg_data = 8'b0000_0000;
        endcase

        if (dot_en) seg_data[7] = 1'b1; // DP active-high
        seg_sel = (8'b0000_0001 << scan_idx); // digit select active-high
    end
endmodule
