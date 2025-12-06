# 🎲 Yacht Dice Game

## 프로젝트 개요
이 프로젝트는 **Xilinx Spartan-7 FPGA (XC7S75FGGA484-1) 보드**에서 동작하는 **Yacht Dice** 게임을 구현한 것입니다.<br>
`Verilog`를 사용하여 설계되었으며, 유한 상태 머신(FSM)을 통해 게임의 흐름, 점수 계산, 그리고 버튼/스위치/디스플레이와 같은 사용자 입출력을 제어합니다.

## 주요 기능
*   **2인 플레이 모드**: 두 명의 플레이어가 번갈아 가며 턴을 진행하는 방식을 지원합니다.
*   **무작위 주사위 생성**: 32비트 LFSR(Linear Feedback Shift Register) 알고리즘을 사용하여 랜덤 주사위 값을 생성합니다.
*   **Hold 기능**: 플레이어는 DIP 스위치를 사용하여 전략적으로 원하는 주사위를 유지(Hold)하고 나머지만 다시 굴릴 수 있습니다.
*   **실시간 점수 계산**: 현재 주사위 조합에 따라 다양한 카테고리(Full House, Yacht 등)의 점수 규칙을 적용하여 계산합니다.
*   **시각적 피드백**:
    *   **7-Segment Display**: 현재 주사위 5개의 값(1~6)과 선택 중인 점수 카테고리를 보여줍니다.
    *   **16x2 LCD**: 게임 상태(시작/종료), 현재 라운드, 그리고 두 플레이어의 실시간 총점을 표시합니다.
    *   **LEDs**: 현재 Hold 설정된 주사위, 점수 선택 모드(LED6), 그리고 누구의 턴인지(P1/P2)를 알려줍니다.

## 하드웨어 요구사항
*   **FPGA 보드**: Xilinx Spartan-7 (XC7S75FGGA484-1)
*   **입력 장치**:
    *   5x Button Switches (KEY PAD)
    *   5x DIP Switches
*   **출력 장치**:
    *   8 Array 7-Segment
    *   16x2 Text LCD
    *   8x LEDs

자세한 핀 매핑 정보는 `docs/README_PinMap.md`를 참고하세요.

## 모듈 구조 
| 모듈명 | 설명 |
| :--- | :--- |
| `YachtDice_Top.v` | 최상위 모듈로, 모든 하위 모듈과 물리적 I/O 핀을 연결합니다. |
| `Game_FSM.v` | 게임의 상태(굴리기, 선택, 점수 계산, 턴 교체)를 관리하는 메인 제어 장치입니다. |
| `Dice_Manager.v` | 무작위 주사위 값을 생성하고 Hold 로직을 처리합니다. |
| `Score_Calculator.v` | 현재 주사위 값과 선택된 카테고리에 따른 점수를 계산합니다. |
| `Display_Controller.v` | 7-Segment를 제어하여 주사위 값과 카테고리를 표시합니다. |
| `LCD_Controller.v` | 16x2 Text LCD를 제어하여 게임 메시지와 점수를 출력합니다. |
| `Button_Debouncer.v` | 기계적 버튼의 노이즈를 제거하여 안정적인 입력을 보장합니다. |

자세한 모듈 정보는 `docs/README_Work.md`를 참고하세요.

## 게임 방법

### 1. 게임 시작
*   **Reset 버튼 (KEY12)** 을 눌러 게임을 초기화합니다.

### 2. 주사위 굴리기 
*   **Player 1**부터 시작합니다.
*   **Roll (KEY01)** 버튼을 눌러 5개의 주사위를 굴립니다.
*   **DIP 스위치 (SW1-SW5)** 를 올려서 유지하고 싶은 주사위를 선택할 수 있습니다.
*   한 턴당 최대 **3번**까지 주사위를 굴릴 수 있습니다.

### 3. 점수 선택 (Scoring Phase)
*   **Select (KEY02)** 버튼을 눌러 점수 선택 모드로 진입합니다.
    *   이때 **LED6**이 점등되어 점수 선택 단계임을 알려줍니다.
*   **Prev (KEY05)** 와 **Next (KEY06)** 버튼을 사용하여 점수 카테고리(Ones, Full House, Yacht 등)를 탐색합니다.
    *   점수 선택 모드 진입 전(주사위 굴리기 단계)에도 미리 카테고리를 탐색해볼 수 있습니다.
    *   선택된 카테고리의 약어(예: `1.`,`FH`, `YA`)가 7-Segment 오른쪽 끝에 표시됩니다.
*   원하는 카테고리에서 **Select (KEY02)** 버튼을 다시 누르면 점수가 확정되고 총점에 합산됩니다.
*   **보너스 점수**: 상단 항목(1~6)의 점수 합계가 **63점 이상**이 되면 즉시 **35점**의 보너스 점수가 추가됩니다.

### 4. 턴 교체 (Turn Change)
*   점수 확정 후 상대방에게 턴이 넘어갑니다.
*   **LED7 (Player 1)** 과 **LED8 (Player 2)** 이 점등되어 현재 누구의 턴인지 알려줍니다.
*   턴이 시작될 때 모든 주사위 값은 **0으로 초기화**됩니다.

### 5. 게임 종료 (Game Over)
*   게임은 총 **12 라운드**로 진행됩니다.
*   모든 라운드가 종료되면 LCD에 최종 점수와 함께 "GAME END"가 표시됩니다.
*   **승자 표시**: 점수가 더 높은 플레이어(P1 WIN, P2 WIN) 또는 무승부(DRAW)를 LCD에 표시합니다.

## 팀원
<table>
  <tr>
    <td align="center">
      <a href="https://github.com/7hyunii">
        <img src="https://github.com/7hyunii.png" width="100px;" alt=""/>
        <br />
            7hyunii
      </a>
    </td>
    <td align="center">
      <a href="https://github.com/cnvxlns">
        <img src="https://github.com/cnvxlns.png"           width="100px;" alt=""/>
        <br />
            cnvxlns
      </a>
    </td>
  </tr>
</table>

