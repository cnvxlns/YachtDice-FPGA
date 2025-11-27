# 🎲 Yacht Dice Game - FPGA Pin Mapping Reference

이 문서는 **Spartan-7 FPGA (XC7S75FGGA484-1)** 보드에서 Yacht Dice 게임을 구동하기 위한 입출력 핀 할당 정보를 기술합니다.

## 1. 시스템 (System)


기본 클럭 및 시스템 리셋 신호입니다.

| Port Name (Verilog) |  I/O  |   Pin Loc   | Board Label | Function                                                                     |
| :------------------ | :---: | :----------: | :---------- | :--------------------------------------------------------------------------- |
| **CLK**       | Input | **B6** | FPGA_CLK1   | 메인 시스템 클럭 (50MHz)                                                     |
| **RST_BTN**   | Input | **K6** | KEY12       | 시스템 리셋 (Active Low)`<br>` *게임 버튼과 혼동 방지를 위해 KEY12 사용* |

<br>

## 2. 입력 인터페이스 (Inputs)

### 🔘 게임 조작 버튼 (Buttons)

`BTN[3:0]`은 보드의 **KEY01 ~ 04**에 매핑됩니다.

| Port Name        |   Pin Loc   | Board Label | Game Function       | 설명                            |
| :--------------- | :----------: | :---------- | :------------------ | :------------------------------ |
| **BTN[0]** | **K4** | KEY01       | **Roll**      | 주사위 굴리기 / 턴 시작         |
| **BTN[1]** | **N8** | KEY02       | **Select**    | 점수 선택 모드 진입 / 점수 확정 |
| **BTN[4]** | **P6** | KEY05       | **Prev (←)** | 점수 카테고리 이동 (이전)       |
| **BTN[5]** | **N6** | KEY06       | **Next (→)** | 점수 카테고리 이동 (다음)       |

### 🎚️ 주사위 홀드 스위치 (DIP Switches)

`SW[4:0]`은 보드의 **DIP_SW1 ~ 5**에 매핑됩니다.

| Port Name       |   Pin Loc   | Board Label | Game Function         | 설명                       |
| :-------------- | :----------: | :---------- | :-------------------- | :------------------------- |
| **SW[0]** | **Y1** | DIP_SW1     | **Hold Dice 1** | 주사위 1번 값 고정 (ON 시) |
| **SW[1]** | **W3** | DIP_SW2     | **Hold Dice 2** | 주사위 2번 값 고정 (ON 시) |
| **SW[2]** | **U2** | DIP_SW3     | **Hold Dice 3** | 주사위 3번 값 고정 (ON 시) |
| **SW[3]** | **T1** | DIP_SW4     | **Hold Dice 4** | 주사위 4번 값 고정 (ON 시) |
| **SW[4]** | **W4** | DIP_SW5     | **Hold Dice 5** | 주사위 5번 값 고정 (ON 시) |

<br>

## 3. 출력 인터페이스 (Outputs)

### 💡 상태 표시 LED

`LED[7:0]`은 보드의 **LED_D1 ~ D8**에 매핑됩니다.

| Port Name        |   Pin Loc   | Board Label | Game Function                |
| :--------------- | :----------: | :---------- | :--------------------------- |
| **LED[0]** | **L4** | LED_D1      | 주사위 1 Hold 상태 표시 (ON) |
| **LED[1]** | **M4** | LED_D2      | 주사위 2 Hold 상태 표시 (ON) |
| **LED[2]** | **M2** | LED_D3      | 주사위 3 Hold 상태 표시 (ON) |
| **LED[3]** | **N7** | LED_D4      | 주사위 4 Hold 상태 표시 (ON) |
| **LED[4]** | **M7** | LED_D5      | 주사위 5 Hold 상태 표시 (ON) |
| **LED[5]** | **M3** | LED_D6      | *(미사용 - Always OFF)*    |
| **LED[6]** | **M1** | LED_D7      | **Player 1 Turn** 표시 |
| **LED[7]** | **N5** | LED_D8      | **Player 2 Turn** 표시 |

<br>

### 📟 7-Segment Display (Multiplexing)

보드의 8-Digit Common Anode 7-Segment를 사용합니다.

#### 1) Segment Data (Cathodes, `SEG_DATA[7:0]`)

숫자의 모양을 결정하는 핀입니다.

|  Port Index  |   Pin Loc   | Segment |
| :-----------: | :----------: | :-----: |
| **[0]** | **F1** |    A    |
| **[1]** | **F5** |    B    |
| **[2]** | **E2** |    C    |
| **[3]** | **E4** |    D    |
| **[4]** | **J1** |    E    |
| **[5]** | **J3** |    F    |
| **[6]** | **J7** |    G    |
| **[7]** | **H2** | DP (점) |

#### 2) Digit Select (Anodes, `SEG_SEL[7:0]`)

어느 자리를 켤지 결정하는 핀입니다. (Active Low)

|  Port Index  |   Pin Loc   | Board Label | Game Function           | 표시 내용 예시 |
| :-----------: | :----------: | :---------- | :---------------------- | :------------- |
| **[0]** | **H4** | AR_SEG_S0   | **Dice 1 Value**  | 1 ~ 6          |
| **[1]** | **H6** | AR_SEG_S1   | **Dice 2 Value**  | 1 ~ 6          |
| **[2]** | **G1** | AR_SEG_S2   | **Dice 3 Value**  | 1 ~ 6          |
| **[3]** | **G3** | AR_SEG_S3   | **Dice 4 Value**  | 1 ~ 6          |
| **[4]** | **L6** | AR_SEG_S4   | **Dice 5 Value**  | 1 ~ 6          |
| **[5]** | **K1** | AR_SEG_S5   | **(Unused)**      | (Blank)        |
| **[6]** | **K3** | AR_SEG_S6   | **Category (10)** | 1. 4n, FH 등   |
| **[7]** | **K5** | AR_SEG_S7   | **Category (1)**  | (코드 뒷자리)  |

<br>

### 📺 Text LCD

게임 상태 및 점수 표시를 위해 사용됩니다.

| Port Name               |                           Pin Loc                           | Function                          |
| :---------------------- | :---------------------------------------------------------: | :-------------------------------- |
| **LCD_E**         |                        **A6**                        | Enable Signal                     |
| **LCD_RS**        |                        **G6**                        | Register Select (0: Cmd, 1: Data) |
| **LCD_RW**        |                        **D6**                        | Read/Write (0: Write)             |
| **LCD_DATA[7:0]** | **D1, C1, C5, A2,** `<br>` **D4, C3, B2, A4** | Data Bus (D7 ~ D0 순서)           |

---

### ⚠️ 특이 사항 및 변경점

1. **라운드 표시:** 기존 7-Segment 표시에서 제거되고, **LCD**를 통해 게임 상태와 함께 관리되거나 생략되었습니다.
2. **LCD 추가:** 게임 시작/종료 메시지와 실시간 점수(P1, P2)를 표시하기 위해 LCD가 추가되었습니다.
3. **리셋 버튼:** 게임 플레이 중 실수로 리셋하는 것을 방지하기 위해, 게임 버튼(KEY01~05)과 물리적으로 떨어진 **KEY12**에 할당되었습니다.
