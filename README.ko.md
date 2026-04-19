# gtop

작고 빠른 HUD 형태의 macOS 실시간 시스템 모니터링 유틸리티입니다.

English version: [README.md](README.md)

## 개요

`gtop`은 macOS 메뉴바에서 동작하는 유틸리티로, 주요 시스템 상태를 작은 플로팅 HUD로 보여줍니다.

현재 프로젝트 방향은 다음과 같습니다.

- macOS 네이티브 유틸리티 느낌
- 작은 플로팅 모니터 창
- 저부하 로컬 시스템 모니터링
- 메뉴바 중심의 단순한 제어

## 기능

- 메뉴바 앱
- 메뉴바 아이콘 좌클릭으로 HUD 표시/숨김
- 메뉴바 아이콘 우클릭으로:
  - 단축키 설정 열기
  - foreground mode 토글
  - 로그인 시 자동실행 토글
  - 앱 종료
- HUD 리소스 카드:
  - CPU
  - Memory
  - Disk
  - Network
- 카드 클릭 시 해당 리소스 기준 상위 프로세스 표시
- foreground mode가 꺼져 있으면 HUD 바깥 클릭 시 자동으로 숨김
- `Assets.xcassets` 기반 앱 아이콘 적용

## 기술 스택

- Swift
- SwiftUI
- AppKit 브리지
- Ruby 스크립트로 생성한 Xcode 프로젝트

## 저장소 구조

- `gtop/`: 앱 소스
- `gtopTests/`: 단위 테스트
- `gtop.xcodeproj/`: 생성된 Xcode 프로젝트
- `tools/generate_xcodeproj.rb`: 프로젝트 생성 스크립트
- `tools/generate_app_icon.swift`: 앱 아이콘 에셋 생성 보조 스크립트

## 요구 사항

- macOS 14 이상
- Xcode
- `swiftlint`
- Xcode 프로젝트를 다시 생성하려면 Ruby와 `xcodeproj` gem 필요

## Xcode로 열기

```bash
open gtop.xcodeproj
```

## 빌드

```bash
xcodebuild -project gtop.xcodeproj -scheme gtop build
```

## 테스트

```bash
xcodebuild -project gtop.xcodeproj -scheme gtop test
```

## 린트

```bash
swiftlint lint --strict .
```

## Xcode 프로젝트 다시 생성

```bash
ruby tools/generate_xcodeproj.rb
```

## 로그인 시 자동실행 참고

`gtop`은 `ServiceManagement` 기반으로 로그인 시 자동실행 토글을 제공합니다.

다만 개발용 빌드에서는 앱 서명 상태나 설치 위치에 따라 macOS가 등록을 거부할 수 있습니다. UI 흐름은 준비되어 있지만, 실제 등록 성공은 서명된 앱 빌드에서 더 안정적입니다.

## 참고 사항

- 로컬 전용 유틸리티이며 텔레메트리를 전송하지 않습니다
- 현재 asset catalog에서 `AccentColor` 경고가 보일 수 있지만 앱 동작에는 영향이 없습니다
- HUD는 설정이 많은 앱보다는 작고 빠른 유틸리티 방향에 맞춰 설계되어 있습니다
