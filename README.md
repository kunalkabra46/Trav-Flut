# TripThread - Travel Social Media Platform

## Architecture Overview

### Frontend: Flutter Mobile App

- **Platform**: iOS & Android
- **State Management**: Provider/Riverpod
- **Navigation**: GoRouter
- **Storage**: Flutter Secure Storage (for JWT tokens)
- **HTTP Client**: Dio with interceptors

### Backend: NextJS + TypeScript

- **Framework**: NextJS 14 with App Router
- **Language**: TypeScript
- **Database**: PostgreSQL with Prisma ORM
- **Authentication**: JWT (Access + Refresh Token)
- **API**: RESTful APIs with proper error handling

### Database: PostgreSQL

- **ORM**: Prisma
- **Schema**: User, Follow, OAuthAccount, JWTRefreshToken tables
- **Features**: UUID primary keys, proper relationships, indexes

## Project Structure

```
tripthread/
├── mobile/                 # Flutter Mobile App
│   ├── lib/
│   │   ├── models/        # Data models
│   │   ├── services/      # API services
│   │   ├── providers/     # State management
│   │   ├── screens/       # UI screens
│   │   ├── widgets/       # Reusable widgets
│   │   └── utils/         # Utilities
│   └── pubspec.yaml
├── backend/               # NextJS Backend
│   ├── src/
│   │   ├── app/          # NextJS App Router
│   │   ├── lib/          # Database, auth utilities
│   │   ├── models/       # Prisma models
│   │   └── types/        # TypeScript types
│   ├── prisma/           # Database schema
│   └── package.json
└── README.md
```

## Implementation Plan

### Phase 1: User System Module

1. **Backend Setup**

   - NextJS project with TypeScript
   - PostgreSQL database with Prisma
   - JWT authentication system
   - User, Follow, OAuth models

2. **Flutter Mobile App**

   - Authentication screens (Login/Signup)
   - User profile management
   - Follow/Unfollow functionality
   - Secure token storage

3. **API Endpoints**
   - POST /api/auth/signup
   - POST /api/auth/login
   - POST /api/auth/refresh-token
   - GET /api/users/[id]
   - POST /api/follow/[userId]

## Next Steps

Ready to implement the complete User System module with:

- NextJS backend with PostgreSQL
- Flutter mobile app
- JWT authentication
- Follow system
- Profile management

All according to your specified tech stack.

# Project Folder Structure

Below is the folder structure of the project:

```plaintext
project/
  ├── cursor_rules.md
  ├── mobile/
  │   ├── analysis_options.yaml
  │   ├── android/
  │   │   ├── app/
  │   │   │   ├── build.gradle.kts
  │   │   │   └── src/
  │   │   │       ├── debug/
  │   │   │       │   └── AndroidManifest.xml
  │   │   │       ├── main/
  │   │   │       │   ├── AndroidManifest.xml
  │   │   │       │   ├── java/
  │   │   │       │   │   └── io/flutter/plugins/
  │   │   │       │   ├── kotlin/
  │   │   │       │   │   └── com/example/tripthread/MainActivity.kt
  │   │   │       │   └── res/
  │   │   │       │       ├── drawable/
  │   │   │       │       │   └── launch_background.xml
  │   │   │       │       ├── drawable-v21/
  │   │   │       │       │   └── launch_background.xml
  │   │   │       │       ├── mipmap-hdpi/
  │   │   │       │       │   └── ic_launcher.png
  │   │   │       │       ├── mipmap-mdpi/
  │   │   │       │       │   └── ic_launcher.png
  │   │   │       │       ├── mipmap-xhdpi/
  │   │   │       │       │   └── ic_launcher.png
  │   │   │       │       ├── mipmap-xxhdpi/
  │   │   │       │       │   └── ic_launcher.png
  │   │   │       │       ├── mipmap-xxxhdpi/
  │   │   │       │       │   └── ic_launcher.png
  │   │   │       │       ├── values/
  │   │   │       │       │   └── styles.xml
  │   │   │       │       └── values-night/
  │   │   │       │           └── styles.xml
  │   │   │       └── profile/
  │   │   │           └── AndroidManifest.xml
  │   │   ├── build.gradle.kts
  │   │   ├── gradle/
  │   │   │   └── wrapper/
  │   │   │       └── gradle-wrapper.properties
  │   │   ├── gradle.properties
  │   │   └── settings.gradle.kts
  │   ├── ios/
  │   │   ├── Flutter/
  │   │   │   ├── AppFrameworkInfo.plist
  │   │   │   ├── Debug.xcconfig
  │   │   │   ├── ephemeral/
  │   │   │   └── Release.xcconfig
  │   │   ├── Runner/
  │   │   │   ├── AppDelegate.swift
  │   │   │   ├── Assets.xcassets/
  │   │   │   │   ├── AppIcon.appiconset/
  │   │   │   │   │   ├── Contents.json
  │   │   │   │   │   └── ...
  │   │   │   │   └── LaunchImage.imageset/
  │   │   │   │       ├── Contents.json
  │   │   │   │       └── ...
  │   │   │   ├── Base.lproj/
  │   │   │   │   ├── LaunchScreen.storyboard
  │   │   │   │   └── Main.storyboard
  │   │   │   ├── Info.plist
  │   │   │   ├── Runner-Bridging-Header.h
  │   │   ├── Runner.xcodeproj/
  │   │   │   ├── project.pbxproj
  │   │   │   ├── project.xcworkspace/
  │   │   │   │   ├── contents.xcworkspacedata
  │   │   │   │   └── xcshareddata/
  │   │   │   │       ├── IDEWorkspaceChecks.plist
  │   │   │   │       └── WorkspaceSettings.xcsettings
  │   │   │   └── xcshareddata/
  │   │   │       └── xcschemes/
  │   │   │           └── Runner.xcscheme
  │   │   ├── Runner.xcworkspace/
  │   │   │   ├── contents.xcworkspacedata
  │   │   │   └── xcshareddata/
  │   │   │       ├── IDEWorkspaceChecks.plist
  │   │   │       └── WorkspaceSettings.xcsettings
  │   │   └── RunnerTests/
  │   │       └── RunnerTests.swift
  │   ├── lib/
  │   │   ├── main.dart
  │   │   ├── models/
  │   │   │   ├── api_response.dart
  │   │   │   ├── api_response.g.dart
  │   │   │   ├── trip.dart
  │   │   │   ├── trip.g.dart
  │   │   │   ├── user.dart
  │   │   │   └── user.g.dart
  │   │   ├── providers/
  │   │   │   ├── auth_provider.dart
  │   │   │   ├── trip_provider.dart
  │   │   │   └── user_provider.dart
  │   │   ├── screens/
  │   │   │   ├── auth/
  │   │   │   │   ├── login_screen.dart
  │   │   │   │   └── signup_screen.dart
  │   │   │   ├── home/
  │   │   │   │   └── home_screen.dart
  │   │   │   ├── profile/
  │   │   │   │   ├── edit_profile_screen.dart
  │   │   │   │   └── profile_screen.dart
  │   │   │   ├── splash_screen.dart
  │   │   │   └── trip/
  │   │   │       ├── create_trip_screen.dart
  │   │   │       ├── trip_detail_screen.dart
  │   │   │       └── trip_thread_screen.dart
  │   │   ├── services/
  │   │   │   ├── api_service.dart
  │   │   │   ├── connectivity_service.dart
  │   │   │   ├── storage_service.dart
  │   │   │   └── trip_service.dart
  │   │   ├── utils/
  │   │   │   ├── app_theme.dart
  │   │   │   ├── error_handler.dart
  │   │   │   ├── security.dart
  │   │   │   └── validators.dart
  │   │   └── widgets/
  │   │       ├── custom_text_field.dart
  │   │       └── loading_button.dart
  │   ├── linux/
  │   │   ├── CMakeLists.txt
  │   │   ├── flutter/
  │   │   │   ├── CMakeLists.txt
  │   │   │   ├── generated_plugin_registrant.cc
  │   │   │   ├── generated_plugin_registrant.h
  │   │   │   └── generated_plugins.cmake
  │   │   └── runner/
  │   │       ├── CMakeLists.txt
  │   │       ├── main.cc
  │   │       ├── my_application.cc
  │   │       └── my_application.h
  │   ├── macos/
  │   │   ├── Flutter/
  │   │   │   ├── ephemeral/
  │   │   │   ├── Flutter-Debug.xcconfig
  │   │   │   ├── Flutter-Release.xcconfig
  │   │   │   └── GeneratedPluginRegistrant.swift
  │   │   ├── Runner/
  │   │   │   ├── AppDelegate.swift
  │   │   │   ├── Assets.xcassets/
  │   │   │   │   ├── app_icon_1024.png
  │   │   │   │   ├── app_icon_128.png
  │   │   │   │   ├── app_icon_16.png
  │   │   │   │   ├── app_icon_256.png
  │   │   │   │   ├── app_icon_32.png
  │   │   │   │   ├── app_icon_512.png
  │   │   │   │   ├── app_icon_64.png
  │   │   │   │   └── Contents.json
  │   │   │   ├── Base.lproj/
  │   │   │   │   └── MainMenu.xib
  │   │   │   ├── Configs/
  │   │   │   │   ├── AppInfo.xcconfig
  │   │   │   │   ├── Debug.xcconfig
  │   │   │   │   ├── Release.xcconfig
  │   │   │   │   └── Warnings.xcconfig
  │   │   │   ├── DebugProfile.entitlements
  │   │   │   ├── Info.plist
  │   │   │   ├── MainFlutterWindow.swift
  │   │   │   ├── Release.entitlements
  │   │   ├── Runner.xcodeproj/
  │   │   │   ├── project.pbxproj
  │   │   │   ├── project.xcworkspace/
  │   │   │   │   └── xcshareddata/
  │   │   │   │       └── IDEWorkspaceChecks.plist
  │   │   │   └── xcshareddata/
  │   │   │       └── xcschemes/
  │   │   │           └── Runner.xcscheme
  │   │   ├── Runner.xcworkspace/
  │   │   │   ├── contents.xcworkspacedata
  │   │   │   └── xcshareddata/
  │   │   │       └── IDEWorkspaceChecks.plist
  │   │   └── RunnerTests/
  │   │       └── RunnerTests.swift
  │   ├── pubspec.lock
  │   ├── pubspec.yaml
  │   ├── README.md
  │   ├── test/
  │   │   └── widget_test.dart
  │   ├── web/
  │   │   ├── favicon.png
  │   │   ├── icons/
  │   │   │   ├── Icon-192.png
  │   │   │   ├── Icon-512.png
  │   │   │   ├── Icon-maskable-192.png
  │   │   │   └── Icon-maskable-512.png
  │   │   ├── index.html
  │   │   └── manifest.json
  │   └── windows/
  │       ├── CMakeLists.txt
  │       ├── flutter/
  │       │   ├── CMakeLists.txt
  │       │   ├── ephemeral/
  │       │   ├── generated_plugin_registrant.cc
  │       │   ├── generated_plugin_registrant.h
  │       │   └── generated_plugins.cmake
  │       └── runner/
  │           ├── CMakeLists.txt
  │           ├── flutter_window.cpp
  │           ├── flutter_window.h
  │           ├── main.cpp
  │           ├── resource.h
  │           ├── resources/
  │           │   └── app_icon.ico
  │           ├── runner.exe.manifest
  │           ├── Runner.rc
  │           ├── utils.cpp
  │           ├── utils.h
  │           ├── win32_window.cpp
  │           └── win32_window.h
  ├── next-env.d.ts
  ├── next.config.js
  ├── package-lock.json
  ├── package.json
  ├── prisma/
  │   └── schema.prisma
  ├── README.md
  ├── src/
  │   ├── app/
  │   │   └── api/
  │   │       ├── auth/
  │   │       │   ├── login/route.ts
  │   │       │   ├── logout/route.ts
  │   │       │   ├── refresh-token/route.ts
  │   │       │   └── signup/route.ts
  │   │       ├── follow/[userId]/route.ts
  │   │       ├── health/route.ts
  │   │       ├── trips/
  │   │       │   ├── [id]/end/route.ts
  │   │       │   ├── [id]/entries/route.ts
  │   │       │   ├── [id]/final-post/route.ts
  │   │       │   ├── [id]/participants/route.ts
  │   │       │   ├── [id]/publish/route.ts
  │   │       │   ├── [id]/route.ts
  │   │       │   ├── [id]/status/route.ts
  │   │       │   ├── route.ts
  │   │       ├── users/
  │   │       │   ├── [id]/followers/route.ts
  │   │       │   ├── [id]/following/route.ts
  │   │       │   ├── [id]/privacy/route.ts
  │   │       │   ├── [id]/route.ts
  │   │       │   ├── [id]/stats/route.ts
  │   ├── data/
  │   │   └── mockData.ts
  │   ├── lib/
  │   │   ├── auth.ts
  │   │   ├── db.ts
  │   │   ├── errors.ts
  │   │   ├── middleware.ts
  │   │   ├── monitoring.ts
  │   │   ├── prisma.ts
  │   │   ├── security.ts
  │   │   └── validation.ts
  │   ├── types/
  │   │   └── api.ts
  │   └── vite-env.d.ts
  ├── tsconfig.json
```
