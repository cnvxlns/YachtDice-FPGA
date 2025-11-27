module Button_Debouncer(
    input clk,          // 시스템 클럭 (예: 50MHz or 100MHz)
    input reset_n,      // Active Low 리셋
    input btn_in,       // 실제 버튼 입력
    output reg btn_out  // 디바운싱 완료된 신호 (한 클럭 주기의 펄스)
);
    // [작동 원리]
    // 시프트 레지스터를 사용하여 버튼 입력이 일정 시간(약 20ms) 동안
    // 동일한 값으로 유지될 때만 유효한 입력으로 간주합니다.

    reg [19:0] cnt;             // 타이머 카운터
    reg btn_sync_0, btn_sync_1; // 클럭 도메인 교차(CDC) 방지용 플립플롭
    reg btn_stable;             // 안정화된 버튼 상태

    always @(posedge clk or negedge reset_n) begin
        if (!reset_n) begin
            cnt <= 0;
            btn_sync_0 <= 0;
            btn_sync_1 <= 0;
            btn_stable <= 0;
            btn_out <= 0;
        end else begin
            // 1. 입력 신호 동기화 (메타스테이빌리티 방지)
            btn_sync_0 <= btn_in;
            btn_sync_1 <= btn_sync_0;

            // 2. 카운터 동작: 입력이 바뀌면 카운터 리셋, 아니면 증가
            if (btn_stable == btn_sync_1) begin
                cnt <= 0;
            end else begin
                cnt <= cnt + 1;
                // 일정 시간(예: 2^16 클럭, 약 1.3ms @ 50MHz) 경과 시 상태 변경 인정
                // 반응성을 높이기 위해 카운터 값을 줄임 (기존 20'hFFFFF -> 20'h0FFFF)
                if (cnt == 20'h0FFFF) begin
                    btn_stable <= btn_sync_1;
                    // 버튼이 눌린 순간(0->1)에만 1클럭 펄스 출력 (Rising Edge Detect)
                    if (btn_sync_1 == 1'b1) btn_out <= 1'b1;
                end
            end
            
            // 펄스는 한 클럭만 유지하고 끔
            if (btn_out) btn_out <= 1'b0; 
        end
    end
endmodule