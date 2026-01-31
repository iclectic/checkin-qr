# Meetup Check In QR

## Problem statement
Meetups and community events often rely on paper lists or spreadsheets for attendance.
This app provides a fast, offline-friendly way to check people in with QR codes and
export clean attendance data when the event is over.

## Features
- Create events with a QR code payload.
- Scan QR codes or add check-ins manually.
- Optional attendee name/email/company capture.
- Duplicate scan protection with configurable behavior.
- Attendance list with search.
- CSV export with configurable date and export formats.
- Offline-first storage (local device only).

## Screenshots / GIF
Add images to `docs/screenshots/` and reference them here.

Example placeholders:
![Onboarding](docs/screenshots/onboarding.png)
![Event Detail](docs/screenshots/event_detail.png)
![Scanner](docs/screenshots/scanner.png)
![Attendance](docs/screenshots/attendance.png)

## How to run
Prerequisites:
- Flutter SDK installed
- A device, emulator, or simulator

Install dependencies:
```bash
flutter pub get
```

Run the app:
```bash
flutter run
```

Run tests:
```bash
flutter test
flutter test integration_test/app_smoke_test.dart
```

## Roadmap
- Passcode / organiser mode lock.
- More export formats (JSON, XLSX).
- Optional attendee notes and tags.
- Badge printing support.
- Cloud sync (opt-in).
