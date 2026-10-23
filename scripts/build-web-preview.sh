#!/usr/bin/env bash
set -euo pipefail

# Only the isolated preview project supplies these public client values.
# Never enable the relational sync or admin write flags here.
if [[ -z "${SUPABASE_URL:-}" || -z "${SUPABASE_PUBLISHABLE_KEY:-}" ]]; then
  echo 'Preview Supabase URL and publishable key are required.' >&2
  exit 1
fi
sdk_dir="${TMPDIR:-/tmp}/elnota-flutter-3.47.7"
if [[ ! -x "$sdk_dir/bin/flutter" ]]; then
  git clone --depth 1 --branch 3.47.7 https://github.com/flutter/flutter.git "$sdk_dir"
fi
export PATH="$sdk_dir/bin:$PATH"
flutter config --no-analytics
flutter pub get --enforce-lockfile
flutter build web --release --no-pub \
  --dart-define="SUPABASE_URL=$SUPABASE_URL" \
  --dart-define="SUPABASE_PUBLISHABLE_KEY=$SUPABASE_PUBLISHABLE_KEY"
