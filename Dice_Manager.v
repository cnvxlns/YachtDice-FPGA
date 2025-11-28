module Dice_Manager(
    input clk,
    input reset_n,
    input roll_en,          // FSM에서 오는 '굴리기' 신호
    input [4:0] hold_sw,    // DIP 스위치(Hold 설정)
    output reg [2:0] dice1, dice2, dice3, dice4, dice5 // 각 주사위값(1~6)
);

    // 32비트 LFSR 레지스터
    reg [31:0] lfsr_reg;

    // reset 동안 계속 증가하는 seed mix (reset 해제 타이밍 때마다 다른 값)
    reg [31:0] seed_mix;

    // LFSR feedback 계산 (32, 22, 2, 1번째 비트를 XOR)
    wire feedback = lfsr_reg[31] ^ lfsr_reg[21] ^ lfsr_reg[1] ^ lfsr_reg[0];

    // ------------------------------------------------------------
    // [Seed Mix 증가 로직] 
    // reset_n = 0 동안 clk마다 계속 증가 -> reset 해제 시점이 매번 다른 값
    // ------------------------------------------------------------
    always @(posedge clk or negedge reset_n) begin
        if (!reset_n)
            // 리셋 동안 클럭 주기에 맞춰 seed_mix를 계속 증가
            seed_mix <= seed_mix + 32'h1;
        else
            seed_mix <= seed_mix; // 해제 후 값 유지
    end

    // ------------------------------------------------------------
    // [LFSR 및 Dice 갱신 로직]
    // reset 해제 순간(seed_mix와 XOR하여 랜덤한 초기값 생성)
    // ------------------------------------------------------------
    always @(posedge clk or negedge reset_n) begin
        if (!reset_n) begin
            // reset 해제 타이밍 기반 랜덤 시드 생성
            lfsr_reg <= (32'hACE1 ^ seed_mix);

            // 기본 주사위값 초기화(각 주사위의 초기 값 1)
            dice1 <= 0; 
            dice2 <= 0; 
            dice3 <= 0; 
            dice4 <= 0; 
            dice5 <= 0;
        end else begin
            // LFSR 상태 업데이트 (매 clk에서 시프트)
            lfsr_reg <= {lfsr_reg[30:0], feedback};

            // roll_en = 1이면 Hold되지 않은 주사위만 갱신
            if (roll_en) begin
                if (!hold_sw[0]) dice1 <= (lfsr_reg[ 2: 0] % 6) + 1;
                if (!hold_sw[1]) dice2 <= (lfsr_reg[ 5: 3] % 6) + 1;
                if (!hold_sw[2]) dice3 <= (lfsr_reg[ 8: 6] % 6) + 1;
                if (!hold_sw[3]) dice4 <= (lfsr_reg[11: 9] % 6) + 1;
                if (!hold_sw[4]) dice5 <= (lfsr_reg[14:12] % 6) + 1;
            end
        end
    end

endmodule