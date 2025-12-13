# Rytmo

리듬감 있는 몰입을 위한 macOS 메뉴바 타이머

[![Platform](https://img.shields.io/badge/platform-macOS%2014.6+-lightgrey.svg)]()
[![Swift](https://img.shields.io/badge/Swift-5.9+-orange.svg)]()

## 소개

메뉴바에서 바로 사용할 수 있는 포모도로 타이머입니다. 복잡한 설정 없이 바로 시작할 수 있습니다.

### 주요 기능

- 포모도로 타이머 (25분 집중 → 5분 휴식)
- YouTube 음악 재생
- 24시간 활동 타임라인
- Firebase 인증 (Google/익명)
- 메뉴바 전용 UI

## 시작하기

### 요구사항

- macOS 14.6+
- Xcode 15.0+
- Swift 5.9+

### 설치

```bash
git clone https://github.com/your-username/rytmo.git
cd rytmo/rytmo
```

### 설정

**1. Config 파일 생성**

```bash
cp Config.xcconfig.template Config.xcconfig
```

**2. API 키 입력**

`Config.xcconfig` 파일을 열고 다음 값을 설정하세요:

```
AMPLITUDE_API_KEY = your_amplitude_api_key
REVERSED_CLIENT_ID = your_google_reversed_client_id
```

**3. Firebase 설정**

Firebase Console에서 `GoogleService-Info.plist`를 다운로드하고 `rytmo/rytmo/` 폴더에 추가합니다.

**4. GoogleSignIn 패키지 추가**

Xcode에서:
- File → Add Package Dependencies
- URL: `https://github.com/google/GoogleSignIn-iOS`

**5. 실행**

```bash
open rytmo.xcodeproj
# Command+R로 실행
```

## 아키텍처

### 기술 스택

- Swift 5.9+
- SwiftUI (MenuBarExtra API)
- SwiftData
- Firebase Auth
- Amplitude
- YouTubePlayerKit

### 프로젝트 구조

```
rytmo/
├── rytmo/
│   ├── Models/
│   ├── Views/
│   ├── Managers/
│   └── rytmoApp.swift
├── rytmo-backend/          # v1.1+
├── rytmo-landing-page/
└── docs/
```

## 디자인

노션 스타일의 미니멀한 디자인을 따릅니다.

- 블랙/화이트/그레이 색상
- macOS 네이티브 UI
- 간결한 레이아웃

## 개발

### 빌드

```bash
# Debug
xcodebuild -scheme rytmo -configuration Debug build

# Release
xcodebuild -scheme rytmo -configuration Release build

# Test
xcodebuild test -scheme rytmo
```

### 커밋 컨벤션

```
feat: 새로운 기능
fix: 버그 수정
design: UI/UX 변경
refactor: 리팩토링
docs: 문서 수정
chore: 빌드/설정 변경
```

예시:
```
feat: Firebase 인증 추가

- Google 로그인 구현
- 익명 로그인 구현
```

## 트러블슈팅

### 메뉴바가 업데이트되지 않음

MenuBarExtra 설정과 @Published 프로퍼티의 main thread 실행을 확인하세요.

### 타이머가 백그라운드에서 멈춤

Background Mode 설정을 확인하고, Date 기반 시간 계산을 사용하세요.

### Firebase 로그인 실패

다음을 확인하세요:
- GoogleService-Info.plist 위치
- Keychain 접근 권한 (rytmo.entitlements)
- URL Schemes 설정 (Info.plist)

### 빌드 에러

```bash
# Clean build
shift + command + K

# DerivedData 삭제
rm -rf ~/Library/Developer/Xcode/DerivedData/rytmo-*
```

## 기여

PR과 이슈는 언제나 환영합니다.

1. Fork
2. Feature Branch 생성 (`git checkout -b feat/feature`)
3. Commit (`git commit -m 'feat: 기능 추가'`)
4. Push (`git push origin feat/feature`)
5. Pull Request 생성

## 라이선스

MIT License - Copyright (c) 2025 Rytmo
