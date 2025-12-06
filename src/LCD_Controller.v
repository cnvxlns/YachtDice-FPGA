module LCD_Controller(
    input clk,                  // 시스템 클럭 (50MHz)
    input reset_n,              // Active Low 리셋
    input [3:0] current_state,  // 현재 게임 FSM 상태 (Game_FSM에서 입력)
    input [3:0] round_num,      // 현재 라운드 (1~12)
    input [8:0] p1_score,       // Player 1 현재 점수
    input [8:0] p2_score,       // Player 2 현재 점수
    
    output reg lcd_rs,          // LCD Register Select (0: Command, 1: Data)
    output reg lcd_rw,          // LCD Read/Write (0: Write, 1: Read) - 항상 0(Write) 사용
    output reg lcd_e,           // LCD Enable 신호
    output reg [7:0] lcd_data   // LCD 8-bit 데이터 버스
);

    // [모듈 설명]
    // 16x2 Character LCD (HD44780 호환)를 제어하여 게임 상태와 점수를 표시합니다.
    // - Line 1: 게임 상태 메시지 (GAME START, PLAYING, GAME END)
    // - Line 2: 플레이어 점수 (P1:XXX  P2:XXX)

    // ============================================================================
    // 1. 파라미터 및 상태 정의
    // ============================================================================

    // 게임 FSM 상태 상수 (Game_FSM.v와 일치해야 함)
    localparam S_INIT = 0, S_GAME_END = 12;

    // LCD 제어 FSM 상태 정의
    localparam IDLE      = 0, // 대기 상태
               INIT      = 1, // 초기화 시퀀스 수행
               SEND_CMD  = 2, // 명령어 전송 설정
               SEND_DATA = 3, // 데이터(문자) 전송 설정
               DELAY     = 4; // Enable 펄스 및 처리 대기

    reg [4:0] state_lcd;      // LCD FSM 현재 상태
    
    // LCD 제어용 내부 레지스터
    reg [7:0] data_buffer;    // 전송할 데이터/명령어 버퍼
    reg rs_buffer;            // 전송할 RS 값 버퍼
    
    reg [31:0] delay_cnt;     // 딜레이 카운터
    reg [31:0] delay_target;  // 목표 딜레이 시간 (클럭 사이클 수)
    
    // 화면 버퍼 (16글자 x 2줄)
    reg [7:0] line1 [0:15];   // 첫 번째 줄 문자열 버퍼
    reg [7:0] line2 [0:15];   // 두 번째 줄 문자열 버퍼
    
    // 변경 감지용 레지스터
    reg [8:0] old_p1_score;
    reg [8:0] old_p2_score;
    reg [3:0] old_game_state;
    reg [3:0] old_round_num;
    
    reg refresh_req;          // 화면 갱신 요청 플래그
    reg [4:0] char_idx;       // 현재 전송 중인 문자 인덱스 (0~15)
    reg line_sel;             // 현재 전송 중인 줄 (0: Line 1, 1: Line 2)
    
    reg first_init;           // 리셋 후 최초 갱신을 위한 플래그

    // ============================================================================
    // 2. 유틸리티 함수 (Character Encoding)
    // ============================================================================

    // 숫자를 ASCII 문자로 변환하는 함수
    function [7:0] get_char;
        input [7:0] val;
        begin
            case(val)
                0: get_char = "0"; 1: get_char = "1"; 2: get_char = "2";
                3: get_char = "3"; 4: get_char = "4"; 5: get_char = "5";
                6: get_char = "6"; 7: get_char = "7"; 8: get_char = "8";
                9: get_char = "9"; default: get_char = " ";
            endcase
        end
    endfunction

    // ============================================================================
    // 3. 화면 버퍼 업데이트 로직
    // ============================================================================
    // 점수나 게임 상태가 변경되었을 때, line1과 line2 버퍼의 내용을 갱신합니다.
    
    integer i;
    always @(posedge clk or negedge reset_n) begin
        if (!reset_n) begin
            old_p1_score <= 0;
            old_p2_score <= 0;
            old_game_state <= 0;
            old_round_num <= 0;
            refresh_req <= 0;
            first_init <= 1; // 리셋 시 플래그 설정
            // 버퍼를 공백으로 초기화
            for(i=0; i<16; i=i+1) begin line1[i] <= " "; line2[i] <= " "; end
        end else begin
            // 입력값 변경 감지 (점수 또는 상태가 바뀌면 갱신 요청)
            // 또는 리셋 후 첫 실행(first_init)일 때 강제 갱신
            if (p1_score != old_p1_score || p2_score != old_p2_score || current_state != old_game_state || round_num != old_round_num || first_init) begin
                refresh_req <= 1; // LCD 갱신 트리거
                first_init <= 0;  // 플래그 해제
                old_p1_score <= p1_score;
                old_p2_score <= p2_score;
                old_game_state <= current_state;
                old_round_num <= round_num;
                
                // [Line 1 업데이트] 게임 상태 메시지
                if (current_state == S_INIT) begin
                    // "GAME START      "
                    line1[0] <= "G"; line1[1] <= "A"; line1[2] <= "M"; line1[3] <= "E"; 
                    line1[4] <= " "; line1[5] <= "S"; line1[6] <= "T"; line1[7] <= "A"; 
                    line1[8] <= "R"; line1[9] <= "T"; 
                    for(i=10; i<16; i=i+1) line1[i] <= " ";
                end else if (current_state == S_GAME_END) begin
                    // "GAME END" + 승자 표시
                    line1[0] <= "G"; line1[1] <= "A"; line1[2] <= "M"; line1[3] <= "E"; 
                    line1[4] <= " "; line1[5] <= "E"; line1[6] <= "N"; line1[7] <= "D"; 
                    
                    if (p1_score > p2_score) begin
                        // " P1 WIN "
                        line1[8] <= " "; line1[9] <= "P"; line1[10] <= "1"; line1[11] <= " ";
                        line1[12] <= "W"; line1[13] <= "I"; line1[14] <= "N"; line1[15] <= " ";
                    end else if (p2_score > p1_score) begin
                        // " P2 WIN "
                        line1[8] <= " "; line1[9] <= "P"; line1[10] <= "2"; line1[11] <= " ";
                        line1[12] <= "W"; line1[13] <= "I"; line1[14] <= "N"; line1[15] <= " ";
                    end else begin
                        // "  DRAW  "
                        line1[8] <= " "; line1[9] <= " "; line1[10] <= "D"; line1[11] <= "R";
                        line1[12] <= "A"; line1[13] <= "W"; line1[14] <= " "; line1[15] <= " ";
                    end
                end else begin
                    // "ROUND XX        "
                    line1[0] <= "R"; line1[1] <= "O"; line1[2] <= "U"; line1[3] <= "N"; 
                    line1[4] <= "D"; line1[5] <= " "; 
                    if (round_num >= 10) begin
                        line1[6] <= "1";
                        line1[7] <= get_char(round_num - 10);
                    end else begin
                        line1[6] <= get_char(round_num);
                        line1[7] <= " ";
                    end
                    for(i=8; i<16; i=i+1) line1[i] <= " ";
                end
                
                // [Line 2 업데이트] 점수 표시 "P1:XXX  P2:XXX"
                // P1 점수
                line2[0] <= "P"; line2[1] <= "1"; line2[2] <= ":";
                line2[3] <= get_char(p1_score / 100);        // 백의 자리
                line2[4] <= get_char((p1_score % 100) / 10); // 십의 자리
                line2[5] <= get_char(p1_score % 10);         // 일의 자리
                
                line2[6] <= " "; line2[7] <= " "; // 공백
                
                // P2 점수
                line2[8] <= "P"; line2[9] <= "2"; line2[10] <= ":";
                line2[11] <= get_char(p2_score / 100);
                line2[12] <= get_char((p2_score % 100) / 10);
                line2[13] <= get_char(p2_score % 10);
                
                line2[14] <= " "; line2[15] <= " ";
            end else if (state_lcd == IDLE) begin
                // 갱신이 완료되어 IDLE 상태로 돌아오면 요청 플래그 해제
                refresh_req <= 0;
            end
        end
    end

    // ============================================================================
    // 4. LCD 드라이버 상태 머신 (Main FSM)
    // ============================================================================
    // 실제 LCD 모듈에 신호를 보내는 타이밍 제어를 담당합니다.

    reg [3:0] init_step; // 초기화 단계 카운터
    
    always @(posedge clk or negedge reset_n) begin
        if (!reset_n) begin
            state_lcd <= INIT;
            init_step <= 0;
            delay_cnt <= 0;
            lcd_e <= 0;
            lcd_rs <= 0;
            lcd_rw <= 0;
            char_idx <= 0;
            line_sel <= 0;
        end else begin
            case (state_lcd)
                // ------------------------------------------------------------
                // [초기화 단계] 전원 인가 후 LCD 초기 설정
                // ------------------------------------------------------------
                INIT: begin
                    if (delay_cnt == 0) begin
                        case (init_step)
                            0: begin data_buffer <= 8'h38; rs_buffer <= 0; delay_target <= 500000; end // Function Set: 8-bit, 2 lines
                            1: begin data_buffer <= 8'h0C; rs_buffer <= 0; delay_target <= 2000; end   // Display ON, Cursor OFF
                            2: begin data_buffer <= 8'h01; rs_buffer <= 0; delay_target <= 200000; end // Clear Display
                            3: begin data_buffer <= 8'h06; rs_buffer <= 0; delay_target <= 2000; end   // Entry Mode: Auto Increment
                            default: begin state_lcd <= IDLE; end
                        endcase
                        
                        if (init_step < 4) begin
                            state_lcd <= SEND_CMD; // 명령 전송 상태로 이동
                            init_step <= init_step + 1;
                        end
                    end
                end
                
                // ------------------------------------------------------------
                // [대기 상태] 갱신 요청을 기다림
                // ------------------------------------------------------------
                IDLE: begin
                    if (refresh_req) begin
                        char_idx <= 0;
                        line_sel <= 0;
                        // 커서를 첫 번째 줄 맨 앞으로 이동 (0x80)
                        data_buffer <= 8'h80; 
                        rs_buffer <= 0; 
                        delay_target <= 2000;
                        state_lcd <= SEND_CMD;
                    end
                end
                
                // ------------------------------------------------------------
                // [명령어/데이터 설정] RS, RW, Data 버스 설정 및 Enable 시작
                // ------------------------------------------------------------
                SEND_CMD: begin
                    lcd_rs <= rs_buffer;
                    lcd_rw <= 0;
                    lcd_data <= data_buffer;
                    lcd_e <= 1; // Enable High
                    state_lcd <= DELAY;
                    delay_cnt <= 0;
                end
                
                // ------------------------------------------------------------
                // [딜레이 및 완료 처리] Enable 펄스 생성 및 처리 시간 대기
                // ------------------------------------------------------------
                DELAY: begin
                    // Enable 신호는 최소 펄스 폭 이상 유지 후 Low로 떨어뜨림
                    if (delay_cnt < 50) begin 
                        lcd_e <= 1;
                    end else begin
                        lcd_e <= 0;
                    end
                    
                    // 목표 딜레이 시간만큼 대기
                    if (delay_cnt >= delay_target) begin
                        delay_cnt <= 0;
                        
                        // 상태 분기 처리
                        if (state_lcd == INIT) state_lcd <= INIT; // (안전 장치)
                        else if (init_step < 4 && state_lcd != IDLE && !refresh_req) state_lcd <= INIT; // 초기화 중이면 계속 초기화
                        else begin
                            // 화면 갱신 중일 때의 로직
                            if (refresh_req) begin
                                if (rs_buffer == 0) begin // 방금 보낸 것이 명령어(커서 이동 등)였다면
                                    // 커서 이동 후 데이터 전송 시작
                                    state_lcd <= SEND_DATA;
                                end else begin // 방금 보낸 것이 데이터(문자)였다면
                                    char_idx <= char_idx + 1;
                                    
                                    // 한 줄(16자) 전송 완료 확인
                                    if (char_idx == 15) begin
                                        if (line_sel == 0) begin
                                            // 첫 줄 끝 -> 두 번째 줄로 이동
                                            line_sel <= 1;
                                            char_idx <= 0;
                                            // 커서를 두 번째 줄 맨 앞으로 이동 (0xC0)
                                            data_buffer <= 8'hC0; 
                                            rs_buffer <= 0; 
                                            delay_target <= 2000;
                                            state_lcd <= SEND_CMD;
                                        end else begin
                                            // 두 번째 줄까지 모두 완료 -> 대기 상태로
                                            state_lcd <= IDLE;
                                            // refresh_req는 첫 번째 always 블록에서 IDLE 상태일 때 해제됨
                                        end
                                    end else begin
                                        // 다음 문자 전송
                                        state_lcd <= SEND_DATA;
                                    end
                                end
                            end else begin
                                state_lcd <= INIT; // 예외 상황 시 초기화로 복귀
                            end
                        end
                    end else begin
                        delay_cnt <= delay_cnt + 1;
                    end
                end
                
                // ------------------------------------------------------------
                // [데이터 준비] 버퍼에서 다음 문자 가져오기
                // ------------------------------------------------------------
                SEND_DATA: begin
                    if (line_sel == 0) data_buffer <= line1[char_idx];
                    else data_buffer <= line2[char_idx];
                    
                    rs_buffer <= 1; // Data 모드
                    delay_target <= 2000; // 약 40us 대기
                    state_lcd <= SEND_CMD; // SEND_CMD 상태를 재사용하여 신호 출력
                end
            endcase
        end
    end

endmodule
