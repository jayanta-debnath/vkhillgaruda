#!/usr/bin/env bash

set -e

echo "======================================="
echo "Flutter Web Codespace Setup"
echo "======================================="

# Install required packages
sudo apt-get update
sudo apt-get install -y curl git unzip xz-utils zip libglu1-mesa

# Install Flutter if not already installed
if [ ! -d "$HOME/flutter" ]; then
    echo "Installing Flutter..."
    git clone https://github.com/flutter/flutter.git "$HOME/flutter"
else
    echo "Flutter already installed."
fi

# Add Flutter and Dart global CLI paths to ~/.bashrc
if ! grep -q 'flutter/bin' "$HOME/.bashrc"; then
    echo 'export PATH="$PATH:$HOME/flutter/bin"' >> "$HOME/.bashrc"
fi

if ! grep -q 'pub-cache/bin' "$HOME/.bashrc"; then
    echo 'export PATH="$PATH:$HOME/.pub-cache/bin"' >> "$HOME/.bashrc"
fi

# Reload shell environment so the new PATH settings are available immediately
# shellcheck disable=SC1090
source "$HOME/.bashrc"

export PATH="$PATH:$HOME/flutter/bin:$HOME/.pub-cache/bin"

# Install Firebase tooling if not already available
if ! command -v firebase >/dev/null 2>&1; then
    echo "Installing Firebase CLI..."
    npm install -g firebase-tools
else
    echo "Firebase CLI already installed."
fi

if ! command -v flutterfire >/dev/null 2>&1; then
    echo "Installing FlutterFire CLI..."
    dart pub global activate flutterfire_cli
else
    echo "FlutterFire CLI already installed."
fi

# Login to Firebase if not already authenticated
if ! firebase login:list >/dev/null 2>&1; then
    echo "Please run 'firebase login' to authenticate Firebase CLI."
else
    echo "Firebase CLI already authenticated."
fi

# Pre-download Flutter SDK artifacts
flutter doctor

# Enable web support
flutter config --enable-web

# Accept Android licenses if available
yes | flutter doctor --android-licenses 2>/dev/null || true

# Fetch project dependencies
if [ -f "pubspec.yaml" ]; then
    echo "Installing Flutter dependencies..."
    flutter pub get
fi

echo ""
echo "======================================="
echo "Setup completed"
echo "======================================="
echo ""

flutter doctor

echo ""
echo "======================================="
echo "Next steps: copy required secrets"
echo "======================================="
echo "1. Copy google-services.json for Garuda to: vkhgaruda/android/app/google-services.json"
echo "2. Copy google-services.json for SangeetSeva to: vkhsangeetseva/android/app/google-services.json"
echo "3. Copy the Firebase Admin SDK JSON to: garuda-1ba07-firebase-adminsdk-fbsvc-c07e3d6e0a.json"
echo "4. Copy key.properties for both apps to: <app>/android"
echo "5. Then run:"
echo "   cd vkhgaruda && flutterfire configure --project=garuda-1ba07 --platforms=android,web --out=lib/firebase_options.dart"
echo "   cd ../vkhsangeetseva && flutterfire configure --project=garuda-1ba07 --platforms=android,web --out=lib/firebase_options.dart"
echo ""
echo "Run your application using:"
echo ""
echo "flutter run -d web-server --web-hostname 0.0.0.0 --web-port 8080"
echo ""
echo "When Codespaces prompts to forward port 8080,"
echo "click 'Open in Browser'."