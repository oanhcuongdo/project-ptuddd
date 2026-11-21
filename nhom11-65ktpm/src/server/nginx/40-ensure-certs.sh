#!/bin/sh
# Nếu chưa mount chứng chỉ thật (Let's Encrypt) thì sinh chứng chỉ self-signed
# để Nginx vẫn khởi động được ở môi trường dev / demo.
set -e

CERT_DIR=/etc/nginx/certs
mkdir -p "$CERT_DIR"

if [ ! -s "$CERT_DIR/fullchain.pem" ] || [ ! -s "$CERT_DIR/privkey.pem" ]; then
    echo "[nginx] Không tìm thấy chứng chỉ, tạo self-signed cho ${SERVER_NAME:-localhost}"
    openssl req -x509 -nodes -newkey rsa:2048 -days 365 \
        -subj "/CN=${SERVER_NAME:-localhost}" \
        -keyout "$CERT_DIR/privkey.pem" \
        -out "$CERT_DIR/fullchain.pem" >/dev/null 2>&1
fi
