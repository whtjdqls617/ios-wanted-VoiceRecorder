# VoiceRecord - iOS
프리온보딩 첫번째 과제 📱

> VoiceRecord 는 기존의 녹음 기능에 더해 저장된 데이터를 Firebase와 연동하여 보다 쉽게 관리 할 수 있도록 만든 앱입니다.

<br>

## 🧑‍💻 Developers
|Seocho(조성빈)|Peppo(이병훈)|
|---|---|
|<img width = "200" alt= "서초(조성빈)" src = "https://user-images.githubusercontent.com/64088377/177668277-f9db3eb2-b252-4795-9eec-4f8cc5e10304.jpeg">|<img width = "200" alt= "Peppo(이병훈)" src = "https://user-images.githubusercontent.com/64088377/177667367-3c9650d1-f89a-45dc-bc65-d249deedd39b.jpg">|

<br>


## 👀 미리보기
|VoiceMemoVC(1st page)|RecordDetailVC(2nd page)|PlayingVC(3rd page)|
|---|---|---|
|<img width = "250" alt="page1-VoiceRecorder" src = "https://user-images.githubusercontent.com/64088377/177675103-1a0ba9d2-2f43-4247-be2c-63af279cee1f.gif">|<img width = "250" alt= "page2-VoiceRecorder" src = "https://user-images.githubusercontent.com/64088377/177666696-d2d25b25-1354-4899-9c1c-69b586eb7a0a.gif">|<img width = "280" alt= "page3-VoiceRecorder" src = "https://user-images.githubusercontent.com/64088377/177666695-1fa3ad69-0aa6-4c4a-accd-4a321e5aed85.gif">|

<br>

## 🛠 개발환경
<img width="77" alt="스크린샷 2021-11-19 오후 3 52 02" src="https://img.shields.io/badge/iOS-13.0+-silver"> <img width="93" alt="스크린샷 2021-11-19 오후 3 52 02" src="https://img.shields.io/badge/Xcode-13.4-blue">

<br>

## 🛠 라이브러리
|라이브러리|Version|Tool|
|-------|-------|----|
|FirebaseStorage|`8.15`|`CocoaPod`|

<br>

## 구현

#### 공통 
1. FileManager, FireStorage
  - 로컬/ 원격 파일에 대한 Create, Read, Delete 구현

<br>

||VoiceMemoVC(1st page)|RecordDetailVC(2nd page)|PlayingVC(3rd page)|
|-----|-----|---|-----|
|Seocho<br>(조성빈)|1. 앱 실행시 FireStorage로 부터 받아온 데이터 tableView에 표현|1. 파형: recording파일의 averagePower를 이용해서 Wave form을 그림 <br><br>  2. 녹음: AVAudioRecorder를 사용해서 구현 <br><br> 3.cutoff frequency: AVAudioSession의 setPreferredSampleRate을 이용해서 구현|1. FireStorage로 부터 파형 image 받아오기|
|Peppo<br>(이병훈)|  1. tableView 리스트 삭제 (Local, FireStorage) 동기화 <br><br> 2.tableView pull시 데이터 받아오기 및 예외처리  <br><br>  |1. AVAudioPlayer로 해당 파일에 접근하여 오디오 시간(duration) 표기 <br><br> 2. AutoLayout 적용 (StoryBoard) <br><br> 3. 파형 시작위치 조정|1. AVAudioEngine, Node, File을 사용한 플레이어 생성 <br><br> 2. AVAudioUnitTimePitch를 이용한 목소리 보정 <br><br> 3. AVAudioFramePosition으로 오디오 파일 시간 값조정 및 5초전/후 구현 <br><br> 4. AudioPlayerNode의 volume값 조절 |


<br>

## ⚠️ Trouble Shooting

### “첫 화면에서 각 파일들의 duration”

- 문제점
    - 첫 화면에서 각 파일들의 duration을 받아오지 못함
- 원인
    - Firebase로부터 로컬에 저장하는 .write가 맨 마지막에 실행되서 player에 할당을 하지 못해서 duration이 공백으로 됨
- 해결방안
    - Closure내부 동작에 순서를 조정하여 write가 먼저 실행되게 변경
 ~~~ swift
    storageRef.write(toFile: localPath) { url, error in
				if let url = url {
		        items.append(url.absoluteString)
        }
        let sortedItems = items.sorted()
        let itemsToURL = sortedItems.compactMap { URL(string: $0) }
        completion(itemsToURL)
}
~~~

</br>

## 🤔  고민한 점
### “파형 그리기”

- 직면한 문제
    - m4a파일의 어떤 정보를 가지고 파형을 그려야할 지 모르겠음
    - view를 어떤식으로 처리해야 끊임없이 파형이 그려지는지 모르겠음
- 해결방안
    - audioRecorder의 averagePower를 이용해서 파형을 그리면 되는데, 여기서 그리는 도구인 UIBezierPath, CAShapeLayer를 이용해야한다.
    
    </br>
    
    ``` swift
    private lazy var pencil = UIBezierPath()
    private let waveLayer = CAShapeLayer() // 도형 애니메이션
    
    let averagePower = self.audioRecorder?.averagePower(forChannel: 0)
                self.writeWaves(CGFloat(averagePower ?? 0.0), true)
    ```
    
    ```swift
    private func writeWaves(_ input: CGFloat, _ bool : Bool) {
            if !bool {
                start = firstPoint
                if timer != nil || audioRecorder != nil {
                    timer?.invalidate()
                    recordingTimer?.invalidate()
                    audioRecorder?.stop()
                    audioRecorder = nil
                }
                return
            } else {
                if input < -55 {
                    traitLength = 0.2
                } else if input < -40 && input > -55 {
                    traitLength = (input + 55) / 3
                } else if input < -20 && input > -40 {
                    traitLength = (input + 40) / 2
                } else if input < -10 && input > -20 {
                    traitLength = (input + 20) * 6
                } else {
                    traitLength = (input + 10) * 3
                }
                pencil.move(to: start)
                pencil.addLine(to: CGPoint(x: start.x, y: start.y + traitLength))
                pencil.move(to: start)
                pencil.addLine(to: CGPoint(x: start.x, y: start.y - traitLength))
                waveLayer.strokeColor = UIColor.gray.cgColor
                waveLayer.path = pencil.cgPath
                waveLayer.lineWidth = jump
                waveFormCanvasView.layer.addSublayer(waveLayer)
                start = CGPoint(x: start.x + jump, y: start.y)
            }
        }
    ```
    
    - view의 width를 무한대로 지정하고 그려지는 것과 view의 이동 애니메이션 타이밍을 맞춘다.

## 🔀  Git Branch

개별 브랜치 관리 및 병합의 안정성을 위해 `Git Forking WorkFlow`를 적용했습니다.

Branch를 생성하기 전 [노션페이지](https://good-pirate-c9d.notion.site/Recording-300dabbafd22487783b864820e8655e1)에 일정 및 구현내용을 작성하고,

`<Prefix>/ <구현내용>` 의 양식에 따라 브랜치 명을 작성합니다.

#### 1️⃣ prefix

- `develop` : feature 브랜치에서 구현된 기능들이 merge될 브랜치. **default 브랜치이다.**
- `feature` : 기능을 개발하는 브랜치, 이슈별/작업별로 브랜치를 생성하여 기능을 개발한다
- `main` : 개발이 완료된 산출물이 저장될 공간
- `release` : 릴리즈를 준비하는 브랜치, 릴리즈 직전 QA 기간에 사용한다
- `bug` : 버그를 수정하는 브랜치
- `hotfix` : 정말 급하게, 제출 직전에 에러가 난 경우 사용하는 브렌치

#### 2️⃣ Git forking workflow 적용

1. 팀 프로젝트 repo를 포크한다.(이하 팀 repo)
2. 포크한 개인 repo(이하 개인 repo)를 clone한다.
3. 개인 repo에서 작업하고 개인 repo의 원격저장소로 push한다.
4. pull request를 한다
5. reviewer가 코드리뷰를 진행하고 이상 없을시 팀 repo로 merge 혹은 피드백을 준다.
5. pull 받아야 할 때에는 팀 repo에서 pull 받는다.

</br>

## ⚠️  Issue Naming Rule
#### 1️⃣ 기본 형식
`[<PREFIX>]: <Description>` 의 양식을 준수하되, Prefix는 협업하며 맞춰가기로 한다.

#### 2️⃣ 예시
```
[Feat]: 녹음기능 구현
[Fix]: 원격/로컬 파일 동기화 안되던 버그 수정
```

#### 3️⃣ Prefix의 의미

```bash
[Feat] : 새로운 기능 구현
[Design] : just 화면. 레이아웃 조정
[Fix] : 버그, 오류 해결, 코드 수정
[Add] : Feat 이외의 부수적인 코드 추가, 라이브러리 추가, 새로운 View 생성
[Del] : 쓸모없는 코드, 주석 삭제
[Refactor] : 전면 수정이 있을 때 사용합니다
[Remove] : 파일 삭제
[Chore] : 그 이외의 잡일/ 버전 코드 수정, 패키지 구조 변경, 파일 이동, 파일이름 변경
[Docs] : README나 WIKI 등의 문서 개정
[Comment] : 필요한 주석 추가 및 변경
[Merge] : 머지
```

</br>

##  Commit Message Convention

#### 1️⃣ 기본 형식
prefix는 Issue에 있는 Prefix와 동일하게 사용한다.
```swift
[prefix]: 이슈제목
1. 이슈내용
2. 이슈내용
```

#### 2️⃣ 예시 : 아래와 같이 작성하도록 한다.

```swift
// 새로운 기능(Feat)을 구현한 경우
[Feat]: 기능 구현
1. TableView CRUD 구현
// 레이아웃(Design)을 구현한 경우
[Design]: 레이아웃 구현
1. page1 레이아웃 완료
```

</br>

