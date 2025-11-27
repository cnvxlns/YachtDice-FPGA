module Dice_Manager(
    input clk,
    input reset_n,
    input roll_en,          // FSM에서 오는 '굴리기' 신호
    input [4:0] hold_sw,    // DIP 스위치 (Hold 설정)
    output reg [2:0] dice1, dice2, dice3, dice4, dice5 // 각 주사위 값 (1~6)
);
    // [작동 원리]
    // 32비트 LFSR(Linear Feedback Shift Register)을 사용하여 의사 난수를 생성합니다.
    // roll_en 신호가 들어올 때, hold_sw가 0인(Hold되지 않은) 주사위만 값을 갱신합니다.

    reg [31:0] lfsr_reg;
    reg [31:0] seed_counter; // 시드값 생성을 위한 카운터
    reg first_roll;          // 첫 번째 굴리기 여부 확인

    // LFSR 난수 생성 로직
    wire feedback = lfsr_reg[31] ^ lfsr_reg[21] ^ lfsr_reg[1] ^ lfsr_reg[0];

    always @(posedge clk or negedge reset_n) begin
        if (!reset_n) begin
            lfsr_reg <= 32'hACE1; // 초기값
            seed_counter <= 0;
            first_roll <= 1;      // 리셋 시 첫 굴리기 상태로 설정
            dice1 <= 0; dice2 <= 0; dice3 <= 0; dice4 <= 0; dice5 <= 0;
        end else begin
            // 1. 시드 카운터는 계속 증가 (사람의 버튼 입력 타이밍에 따라 값이 달라짐)
            seed_counter <= seed_counter + 1;

            // 2. LFSR 난수 생성 (계속 섞어줌)
            lfsr_reg <= {lfsr_reg[30:0], feedback};

            // 3. 굴리기 신호가 왔을 때 (BTN0 누름)
            if (roll_en) begin
                // 첫 번째 굴리기라면, 현재 카운터 값을 시드에 섞어줌 (랜덤성 확보)
                if (first_roll) begin
                    lfsr_reg <= lfsr_reg ^ seed_counter;
                    first_roll <= 0;
                end

                // SW가 0(Low)일 때만 주사위 값 갱신
                // % 6 + 1 연산으로 1~6 사이의 값 추출
                if (!hold_sw[0]) dice1 <= (lfsr_reg[2:0] % 6) + 1;
                if (!hold_sw[1]) dice2 <= (lfsr_reg[5:3] % 6) + 1;
                if (!hold_sw[2]) dice3 <= (lfsr_reg[8:6] % 6) + 1;
                if (!hold_sw[3]) dice4 <= (lfsr_reg[11:9] % 6) + 1;
                if (!hold_sw[4]) dice5 <= (lfsr_reg[14:12] % 6) + 1;
            end
        end
    end
endmodule