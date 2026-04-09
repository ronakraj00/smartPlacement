# Smart Placement

A Flutter app that connects students with recruiters for seamless job placement.

## Features

- **Authentication** – Student and recruiter sign-up / sign-in with role selection
- **Job Listings** – Browse and search available job postings
- **Job Details** – View full job description, requirements, salary, and apply
- **Profile** – View and manage your user profile, upload resume
- **Navigation** – `go_router`-based routing with auth guards

## Getting Started

### Prerequisites

- [Flutter SDK](https://flutter.dev/docs/get-started/install) ≥ 3.0
- Android Studio / Xcode (for mobile targets) or a modern browser (for web)

### Setup

```bash
# Install dependencies
flutter pub get

# Run on a connected device or emulator
flutter run

# Run on Chrome (web)
flutter run -d chrome
```

### Project Structure

```
lib/
├── main.dart               # App entry point
├── models/                 # Data models (User, Job)
├── providers/              # State management (AuthProvider)
├── routes/                 # go_router configuration
├── screens/
│   ├── auth/               # Login & Register screens
│   ├── home/               # Home / Job list screen
│   ├── jobs/               # Job detail screen
│   └── profile/            # Profile screen
├── services/               # API/data services (AuthService, JobService)
└── widgets/                # Reusable widgets (JobCard)
```

### Running Tests

```bash
flutter test
```

## Dependencies

| Package | Purpose |
|---|---|
| `provider` | State management |
| `go_router` | Declarative navigation |
| `http` | REST API calls |
| `shared_preferences` | Local persistence |
| `flutter_secure_storage` | Secure token storage |
