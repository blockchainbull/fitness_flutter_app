#!/bin/bash

# Clone Flutter if not exists
if [ ! -d "flutter" ]; then
  git clone https://github.com/flutter/flutter.git --branch stable --depth 1
fi

# Build
flutter/bin/flutter pub get
flutter/bin/flutter build web --release \
  --dart-define=SUPABASE_URL="${SUPABASE_URL}" \
  --dart-define=SUPABASE_ANON_KEY="${SUPABASE_ANON_KEY}"