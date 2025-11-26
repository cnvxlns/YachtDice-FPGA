# 🎲 Yacht Dice Game - FPGA Pin Mapping Reference

이 문서는 **Spartan-7 FPGA (XC7S75FGGA484-1)** 보드에서 Yacht Dice 게임을 구동하기 위한 입출력 핀 할당 정보를 기술합니다.

## 1. 시스템 (System)
기본 클럭 및 시스템 리셋 신호입니다.

| Port Name (Verilog) | I/O | Pin Loc | Board Label | Function |
| :--- | :---: | :---: | :--- | :--- |
| **CLK** | Input | **R2** | OSC_50MHZ | 메인 시스템 클럭 (50MHz) |
| **RST_BTN** | Input | **B13** | PUSH_SW4 | 시스템 리셋 (Active Low) <br> *게임 버튼과 혼동 방지를 위해 SW4 사용* |

<br>

## 2. 입력 인터페이스 (Inputs)

### 🔘 게임 조작 버튼 (Buttons)
`BTN[3:0]`은 보드의 **PUSH_SW0 ~ 3**에 매핑됩니다.

| Port Name | Pin Loc | Board Label | Game Function | 설명 |
| :--- | :---: | :--- | :--- | :--- |
| **BTN[0]** | **J1** | PUSH_SW0 | **Roll** | 주사위 굴리기 / 턴 시작 |
| **BTN[1]** | **A13** | PUSH_SW1 | **Select** | 점수 선택 모드 진입 / 점수 확정 |
| **BTN[2]** | **A14** | PUSH_SW2 | **Prev (←)** | 점수 카테고리 이동 (이전) |
| **BTN[3]** | **A15** | PUSH_SW3 | **Next (→)** | 점수 카테고리 이동 (다음) |

### 🎚️ 주사위 홀드 스위치 (DIP Switches)
`SW[4:0]`은 보드의 **DIP_SW0 ~ 4**에 매핑됩니다.

| Port Name | Pin Loc | Board Label | Game Function | 설명 |
| :--- | :---: | :--- | :--- | :--- |
| **SW[0]** | **L21** | DIP_SW0 | **Hold Dice 1** | 주사위 1번 값 고정 (ON 시) |
| **SW[1]** | **K21** | DIP_SW1 | **Hold Dice 2** | 주사위 2번 값 고정 (ON 시) |
| **SW[2]** | **J22** | DIP_SW2 | **Hold Dice 3** | 주사위 3번 값 고정 (ON 시) |
| **SW[3]** | **H22** | DIP_SW3 | **Hold Dice 4** | 주사위 4번 값 고정 (ON 시) |
| **SW[4]** | **G21** | DIP_SW4 | **Hold Dice 5** | 주사위 5번 값 고정 (ON 시) |

<br>

## 3. 출력 인터페이스 (Outputs)

### 💡 상태 표시 LED
`LED[7:0]`은 보드의 **LED0 ~ 7**에 매핑됩니다.

| Port Name | Pin Loc | Board Label | Game Function |
| :--- | :---: | :--- | :--- |
| **LED[0]** | **T20** | LED0 | 주사위 1 Hold 상태 표시 (ON) |
| **LED[1]** | **U20** | LED1 | 주사위 2 Hold 상태 표시 (ON) |
| **LED[2]** | **V20** | LED2 | 주사위 3 Hold 상태 표시 (ON) |
| **LED[3]** | **W20** | LED3 | 주사위 4 Hold 상태 표시 (ON) |
| **LED[4]** | **Y20** | LED4 | 주사위 5 Hold 상태 표시 (ON) |
| **LED[5]** | **A20** | LED5 | *(미사용 - Always OFF)* |
| **LED[6]** | **W21** | LED6 | **Player 1 Turn** 표시 |
| **LED[7]** | **U21** | LED7 | **Player 2 Turn** 표시 |

<br>

### 📟 7-Segment Display (Multiplexing)
보드의 8-Digit Common Anode 7-Segment를 사용합니다.

#### 1) Segment Data (Cathodes, `SEG_DATA[7:0]`)
숫자의 모양을 결정하는 핀입니다.

| Port Index | Pin Loc | Segment |
| :---: | :---: | :---: |
| **[0]** | **D19** | A |
| **[1]** | **B21** | B |
| **[2]** | **E19** | C |
| **[3]** | **C19** | D |
| **[4]** | **B22** | E |
| **[5]** | **C22** | F |
| **[6]** | **B20** | G |
| **[7]** | **A21** | DP (점) |

#### 2) Digit Select (Anodes, `SEG_SEL[7:0]`)
어느 자리를 켤지 결정하는 핀입니다. (Active Low)

| Port Index | Pin Loc | Board Label | Game Function | 표시 내용 예시 |
| :---: | :---: | :--- | :--- | :--- |
| **[0]** | **J14** | SEL0 | **Dice 1 Value** | 1 ~ 6 |
| **[1]** | **H14** | SEL1 | **Dice 2 Value** | 1 ~ 6 |
| **[2]** | **J19** | SEL2 | **Dice 3 Value** | 1 ~ 6 |
| **[3]** | **H19** | SEL3 | **Dice 4 Value** | 1 ~ 6 |
| **[4]** | **H17** | SEL4 | **Dice 5 Value** | 1 ~ 6 |
| **[5]** | **K18** | SEL5 | **(Unused)** | (Blank) |
| **[6]** | **J20** | SEL6 | **Category (10)** | 1n, 4k, FH 등 |
| **[7]** | **H18** | SEL7 | **Category (1)** | (코드 뒷자리) |

<br>

### 📺 Text LCD
게임 상태 및 점수 표시를 위해 사용됩니다.

| Port Name | Pin Loc | Function |
| :--- | :---: | :--- |
| **LCD_E** | **A6** | Enable Signal |
| **LCD_RS** | **G6** | Register Select (0: Cmd, 1: Data) |
| **LCD_RW** | **D6** | Read/Write (0: Write) |
| **LCD_DATA[7:0]** | **D1, C1, C5, A2,**<br>**D4, C3, B2, A4** | Data Bus (D7 ~ D0 순서) |

---

### ⚠️ 특이 사항 및 변경점
1.  **라운드 표시:** 기존 7-Segment 표시에서 제거되고, **LCD**를 통해 게임 상태와 함께 관리되거나 생략되었습니다.
2.  **LCD 추가:** 게임 시작/종료 메시지와 실시간 점수(P1, P2)를 표시하기 위해 LCD가 추가되었습니다.
3.  **리셋 버튼:** 게임 플레이 중 실수로 리셋하는 것을 방지하기 위해, 게임 버튼(SW0~3)과 물리적으로 떨어진 **SW4**에 할당되었습니다.