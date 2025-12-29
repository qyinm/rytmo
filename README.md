# Rytmo

macOS Menu Bar Timer for Rhythmic Immersion

[![Platform](https://img.shields.io/badge/platform-macOS%2014.6+-lightgrey.svg)]()
[![Swift](https://img.shields.io/badge/Swift-5.9+-orange.svg)]()

## Introduction

A Pomodoro timer that lives right in your menu bar. Start immediately without complex configurations.

### Key Features

- Pomodoro Timer (25min Focus → 5min Break)
- YouTube Music Playback
- 24-hour Activity Timeline
- Firebase Authentication (Google/Anonymous)
- Menu Bar Exclusive UI

## Getting Started

### Requirements

- macOS 14.6+
- Xcode 15.0+
- Swift 5.9+

### Installation

```bash
git clone https://github.com/your-username/rytmo.git
cd rytmo/rytmo
```

### Configuration

**1. Create Config File**

```bash
cp Config.xcconfig.template Config.xcconfig
```

**2. Enter API Keys**

Open `Config.xcconfig` file and set the following values:

```
AMPLITUDE_API_KEY = your_amplitude_api_key
REVERSED_CLIENT_ID = your_google_reversed_client_id
```

**3. Firebase Setup**

Download `GoogleService-Info.plist` from Firebase Console and add it to the `rytmo/rytmo/` folder.

**4. Add GoogleSignIn Package**

In Xcode:
- File → Add Package Dependencies
- URL: `https://github.com/google/GoogleSignIn-iOS`

**5. Run**

```bash
open rytmo.xcodeproj
# Run with Command+R
```

## Architecture

### Tech Stack

- Swift 5.9+
- SwiftUI (MenuBarExtra API)
- SwiftData
- Firebase Auth
- Amplitude
- YouTubePlayerKit

### Project Structure

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

## Design

Follows a Notion-style minimal design.

- Black/White/Gray colors
- macOS Native UI
- Concise Layout

## Development

### Build

```bash
# Debug
xcodebuild -scheme rytmo -configuration Debug build

# Release
xcodebuild -scheme rytmo -configuration Release build

# Test
xcodebuild test -scheme rytmo
```

### Commit Convention

```
feat: New feature
fix: Bug fix
design: UI/UX change
refactor: Refactoring
docs: Documentation change
chore: Build/Config change
```

Example:
```
feat: Add Firebase Authentication

- Implement Google Login
- Implement Anonymous Login
```

## Troubleshooting

### Menu bar not updating

Check MenuBarExtra configuration and @Published property execution on main thread.

### Timer stops in background

Check Background Mode settings and use Date-based time calculation.

### Firebase Login Failure

Check the following:
- GoogleService-Info.plist location
- Keychain Access Group (rytmo.entitlements)
- URL Schemes configuration (Info.plist)

### Build Errors

```bash
# Clean build
shift + command + K

# Delete DerivedData
rm -rf ~/Library/Developer/Xcode/DerivedData/rytmo-*
```

## License

MIT License - Copyright (c) 2025 Rytmo
