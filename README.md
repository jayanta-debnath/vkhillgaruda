# vkhillgaruda
Seva App for ISKCON Vaikuntha Hill

vkhillgaruda is a collection of Flutter apps built to support seva coordination at ISKCON Vaikuntha Hill. Garuda provides the main seva management experience for organizing temple workflows, while SangeetSeva focuses on music-related seva and event participation. Together, the apps share common packages and Firebase-backed services to help teams manage registrations, schedules, communication, and records in a more organized way.

## Apps

| App | Description |
|-----|-------------|
| [vkhgaruda](vkhgaruda/README.md) | Garuda — the main seva management app |
| [vkhsangeetseva](vkhsangeetseva/README.md) | SangeetSeva — the music seva app |

# Tech Stack

## UI Framework
- Flutter
- Dart
- Material Design widgets

# Platforms
- Android
- Web

## Backend and Cloud
- Firebase Authentication
- Firebase Realtime Database
- Firebase Storage
- Firebase Remote Config
- Firebase Cloud Messaging
- Firebase Hosting
- Cloud Functions for Firebase

## Concepts and Techniques
- Responsive UI
- Shared package architecture
- Push notifications
- PDF / print-ready report generation
- Data synchronization with Last-Write-Win technique
- Local Database with abstractions for web and mobile

## Pre-requisites
- Flutter SDK (3.6.0 or higher)
- Python 3.x (for build scripts)
- Firebase account with configured project
- Firebase CLI (`firebase`)
- FlutterFire CLI (`flutterfire`)

# How to build

## Pre-requisites

## 1. Clone the Repository
```bash
git clone https://github.com/jayanta-debnath/vkhillgaruda.git
cd vkhillgaruda
```

Add the secrets:

1. Copy `google-services.json` for Garuda to:
   `vkhgaruda/android/app/google-services.json`
2. Copy `google-services.json` for SangeetSeva to:
   `vkhsangeetseva/android/app/google-services.json`
3. Copy the Firebase Admin SDK service account JSON to the repository root:
   `garuda-1ba07-firebase-adminsdk-fbsvc-c07e3d6e0a.json`
4. copy `key.properties` for both apps to:
    `<appfolder>/android`
   make sure the contents of the file has the right path to key materials

Generate Firebase Dart config files (not committed to git):

```bash
# Garuda
firebase login
cd vkhgaruda
flutterfire configure --project=garuda-1ba07 --platforms=android,web --out=lib/firebase_options.dart

# SangeetSeva
cd ../vkhsangeetseva
flutterfire configure --project=garuda-1ba07 --platforms=android,web --out=lib/firebase_options.dart
```

## 2. Install Dependencies

```bash
cd ../vkhpackages && flutter pub get && cd ..
cd vkhgaruda && flutter pub get && cd ..
cd vkhsangeetseva && flutter pub get
```

## Security Notes

### Protected Files (Never Commit These):
- ✓ `key.properties` (contains signing keys)
- ✓ `.timetracker` (personal time tracking data)

These files are automatically ignored by `.gitignore`

# Archiecture and Concepts

## data synchronization

1. The tickets page follows a "local first" approach.
1. Local data entry directly is used to update the UI
1. Update data to server asynchronously
1. Incoming "add" data from other devices will be added only when "key" not existing locally
1. For incoming "edit" data, server data will be given preference

# License

See [LICENSE](LICENSE) file for details.

