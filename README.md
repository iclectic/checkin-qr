# Meetup Check In QR

## Problem statement
Meetups and community events often rely on paper lists or spreadsheets for attendance.
This app provides a fast, offline-friendly way to check people in with QR codes and
export clean attendance data when the event is over.

## Features
- Create events with a QR code payload.
- Scan QR codes or add check-ins manually.
- Optional attendee name/email/company capture.
- Duplicate scan protection with configurable behaviour.
- Attendance list with search.
- CSV export with configurable date and export formats.
- Offline-first storage (local by default; optional cloud sync).
- Optional attendee self check-in via hosted web form + cloud sync/export.

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

## Optional: Attendee self check-in (Supabase)
This optional phase adds a hosted attendee form that writes to Supabase and lets the
organiser app sync/export cloud check-ins.

### 1) Create the Supabase table
Run this SQL in Supabase:
```sql
create table if not exists public.check_ins (
  id uuid primary key,
  event_id text not null,
  event_code text not null,
  attendee_name text,
  attendee_email text,
  attendee_company text,
  method text not null default 'self',
  timestamp timestamptz not null default now(),
  created_at timestamptz not null default now()
);

create index if not exists check_ins_event_idx
  on public.check_ins (event_id, event_code);
```

Security note: the demo uses the Supabase anon key from the client. For production,
add RLS or an edge function to protect read access.

### 2) Configure the hosted form
Edit `web/self_checkin/config.js` and set:
- `supabaseUrl`
- `supabaseAnonKey`

Deploy `web/self_checkin/` to any static host (Vercel, Netlify, Supabase hosting, etc).

### 3) Configure the organiser app
Build/run the app with:
```bash
flutter run \
  --dart-define=SUPABASE_URL=YOUR_SUPABASE_URL \
  --dart-define=SUPABASE_ANON_KEY=YOUR_SUPABASE_ANON_KEY \
  --dart-define=SELF_CHECKIN_BASE_URL=https://your-host/self_checkin/
```

Then enable **Cloud sync** in Settings and use **Sync now** in the event screen.

## Roadmap
- Passcode / organiser mode lock.
- More export formats (JSON, XLSX).
- Optional attendee notes and tags.
- Badge printing support.
- Cloud sync enhancements (background, conflict handling).
