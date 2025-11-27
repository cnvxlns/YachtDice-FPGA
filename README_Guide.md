# YachtDice-FPGA

FPGA를 이용한 Yacht Dice 게임 구현 프로젝트입니다.

## 🤝 협업 및 기여 가이드 (Contribution Guide)

이 프로젝트는 **Fork & Pull Request** 방식을 통해 협업을 진행합니다.
모든 코드 수정은 본인의 Fork 저장소 내 **별도 브랜치**에서 진행하며, 최종적으로 원본 저장소(Upstream)의 `main` 브랜치로 PR을 보내 병합합니다.

### 🛠️ 작업 순서 (Workflow)

#### 1. 저장소 Fork (포크)

1. GitHub 웹페이지 우측 상단의 **Fork** 버튼을 클릭하여 본인의 계정으로 저장소를 복제합니다.

#### 2. 로컬로 Clone (복제)

본인의 계정에 Fork된 저장소를 로컬 컴퓨터로 가져옵니다.

```bash
# 본인 아이디의 저장소를 clone 해야 합니다.
git clone https://github.com/<본인아이디>/YachtDice-FPGA.git
cd YachtDice-FPGA
```

#### 3. 작업 브랜치 생성 (Branch)

**절대 `main` 브랜치에서 직접 작업하지 마세요.**
작업할 기능이나 본인의 이름을 딴 브랜치를 생성하고 이동합니다.

```bash
git checkout -b <브랜치명>
```

#### 4. 코드 수정 및 커밋 (Commit)

작업을 진행한 후 변경 사항을 커밋합니다. <br>
**아래의 커밋 메시지 규칙(Conventional Commits)을 반드시 준수해주세요.**

**커밋 메시지 구조:** `타입: 제목`

**주요 타입(Type):**

* `feat`: 새로운 기능 추가
* `fix`: 버그 수정
* `docs`: 문서 수정 (README 등)
* `style`: 코드 포맷팅, 세미콜론 누락 등 (코드 변경 없음)
* `refactor`: 코드 리팩토링 (기능 변경 없음)
* `test`: 테스트 코드 추가/수정
* `chore`: 기타 자잘한 수정 (빌드 설정, 패키지 관리 등)

**작성 예시:**

```bash
git add .
# 기능 추가 시
git commit -m "feat: 점수 계산 로직 구현"
# 버그 수정 시
git commit -m "fix: 주사위 굴리기 타이밍 오류 수정"
# 문서 수정 시
git commit -m "docs: README 협업 가이드 추가"
```

#### 5. 본인 원격 저장소로 Push

작업한 브랜치를 본인의 GitHub 저장소(Fork된 곳)로 업로드합니다.

```bash
git push origin <브랜치명>
```

#### 6. Pull Request (PR) 생성

1. GitHub의 원본 저장소(7hyunii/YachtDice-FPGA) 또는 본인의 Fork 저장소 페이지로 이동합니다.
2. **"New pull request"** 버튼을 클릭합니다.
3. **Base repository**가 `7hyunii/YachtDice-FPGA`의 `main`인지 확인합니다.
4. **Head repository**가 본인의 저장소 및 작업한 브랜치인지 확인합니다.
5. 변경 내용을 요약하여 작성하고 **Create Pull Request**를 클릭합니다.

### ⚠️ PR 제출 시 필수 확인 사항 및 팁

**반드시 FPGA 보드에서 비트스트림(Bitstream) 생성 및 동작 확인이 완료된 파일만 PR을 보내주세요.**

#### 💡 권장 작업 방식: 기능별로 브랜치 나누기

가장 좋은 방법은 **작업을 시작할 때부터 기능 단위로 브랜치를 나누는 것**입니다. 이렇게 하면 나중에 파일을 골라낼 필요 없이 브랜치 자체를 바로 PR 보낼 수 있어 편리합니다.

**예시 시나리오:**
1. **주사위 기능** 만들 때: `main`에서 `feat/dice` 브랜치 생성 -> 작업 -> PR
2. **점수판 기능** 만들 때: 다시 `main`으로 돌아와서 `feat/score` 브랜치 생성 -> 작업 -> PR
