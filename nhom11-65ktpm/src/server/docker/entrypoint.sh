#!/bin/sh
# Chạy migration trước khi khởi động API (tắt bằng RUN_MIGRATIONS=0).
set -e

if [ "${RUN_MIGRATIONS:-1}" = "1" ]; then
    echo "[entrypoint] alembic upgrade head"
    alembic upgrade head
fi

exec "$@"
