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