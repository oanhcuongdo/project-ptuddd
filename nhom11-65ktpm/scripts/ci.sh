#!/usr/bin/env bash
# Chạy các bước kiểm tra giống CI ở máy local trước khi mở Pull Request.
#   bash nhom11-65ktpm/scripts/ci.sh            # backend + flutter
#   bash nhom11-65ktpm/scripts/ci.sh backend    # chỉ backend
#   bash nhom11-65ktpm/scripts/ci.sh mobile     # chỉ flutter
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TARGET="${1:-all}"

run_backend() {
    echo "==> Backend: pytest"
    cd "$ROOT/src/server"
    python -m pytest -q
}

run_mobile() {
    echo "==> Flutter: analyze + test"
    cd "$ROOT/src/app"
    flutter pub get
    flutter analyze --no-fatal-infos
    flutter test
}

case "$TARGET" in
    backend) run_backend ;;
    mobile) run_mobile ;;
    all) run_backend; run_mobile ;;
    *) echo "Cách dùng: $0 [all|backend|mobile]"; exit 2 ;;
esac

echo "==> CI local: OK"
