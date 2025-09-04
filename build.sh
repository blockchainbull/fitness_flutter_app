#!/bin/bash

# Download Flutter SDK
git clone https://github.com/flutter/flutter.git
export PATH="$PATH:`pwd`/flutter/bin"

# Verify Flutter installation
flutter doctor -v

# Clean and get dependencies
flutter clean
flutter pub get

# Build the web app with environment variables
flutter build web --release \
  --dart-define=SUPABASE_URL=$SUPABASE_URL \
  --dart-define=SUPABASE_ANON_KEY=$SUPABASE_ANON_KEY