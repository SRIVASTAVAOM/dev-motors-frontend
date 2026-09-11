#!/bin/bash
set -e

echo "=== Vercel Flutter Web Build ==="

if ! command -v flutter &> /dev/null; then
  echo "Flutter SDK not found in PATH. Downloading Flutter SDK..."
  if [ ! -d "flutter" ]; then
    git clone https://github.com/flutter/flutter.git --depth 1 -b stable flutter
  fi
  export PATH="$PATH:`pwd`/flutter/bin"
fi

flutter --version
flutter config --no-analytics
flutter build web --release

echo "=== Build Complete: output available in build/web ==="
