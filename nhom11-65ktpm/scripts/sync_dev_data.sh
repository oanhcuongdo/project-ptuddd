#!/usr/bin/env bash
# Chép dữ liệu bài học dùng chung sang assets của app (bản giả LessonRepository đọc từ đó).
# Chạy sau mỗi lần sửa nhom11-65ktpm/data/lessons/. Test flutter sẽ báo lỗi nếu hai nơi lệch nhau.
#
#   bash nhom11-65ktpm/scripts/sync_dev_data.sh
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
SRC="$ROOT/data/lessons"
DST="$ROOT/src/app/assets/dev/lessons"
rm -rf "$DST"
mkdir -p "$DST"
cp -r "$SRC"/. "$DST"/
echo "Đã chép $(find "$DST" -name '*.json' | wc -l) file bài học vào src/app/assets/dev/lessons"
echo "Nhớ khai báo thư mục cấp độ mới (vd. assets/dev/lessons/hsk2/) trong src/app/pubspec.yaml nếu có."
