# Triển khai backend ChaiLish bằng Docker Compose

Stack gồm 3 container (`nhom11-65ktpm/src/server/docker-compose.yml`):

| Service | Image | Vai trò |
|:--|:--|:--|
| `db` | `postgres:16-alpine` | CSDL, dữ liệu lưu ở volume `postgres_data` |
| `api` | build từ `Dockerfile` (multi-stage, user không phải root) | FastAPI; tự chạy `alembic upgrade head` khi khởi động |
| `nginx` | build từ `nginx/Dockerfile` | Reverse proxy HTTPS, chuyển HTTP → HTTPS, tắt buffer cho streaming `/api/ai/` |

## Chạy ở máy local

```bash
cd nhom11-65ktpm/src/server
cp .env.example .env        # sửa SECRET_KEY, POSTGRES_PASSWORD, ANTHROPIC_API_KEY...
docker compose up -d --build
curl -k https://localhost/api/health
```

- Swagger: <https://localhost/docs> (trình duyệt sẽ cảnh báo vì chứng chỉ self-signed tự sinh).
- Trùng cổng 80/443/5432 thì đổi `HTTP_PORT`, `HTTPS_PORT`, `POSTGRES_PORT` trong `.env`.
- App Flutter trên Android Emulator gọi `https://10.0.2.2/api` (hoặc gọi thẳng API `http://10.0.2.2:8000/api` khi chạy uvicorn không qua Docker).

## Triển khai lên VPS với HTTPS thật (Let's Encrypt)

1. Trỏ tên miền về IP VPS, đặt trong `.env`: `SERVER_NAME=api.ten-mien.vn`, `ENVIRONMENT=production`, `SECRET_KEY` ngẫu nhiên ≥ 32 ký tự (`python -c "import secrets;print(secrets.token_urlsafe(48))"`).
2. `docker compose up -d --build` (lúc đầu Nginx dùng chứng chỉ self-signed).
3. Lấy chứng chỉ qua webroot mà Nginx đang phục vụ ở `/.well-known/acme-challenge/`:
   ```bash
   docker run --rm -v chailish_certbot_www:/var/www/certbot -v "$PWD/nginx/letsencrypt:/etc/letsencrypt" \
     certbot/certbot certonly --webroot -w /var/www/certbot -d api.ten-mien.vn --agree-tos -m email@cua-nhom.vn
   cp nginx/letsencrypt/live/api.ten-mien.vn/fullchain.pem nginx/certs/fullchain.pem
   cp nginx/letsencrypt/live/api.ten-mien.vn/privkey.pem nginx/certs/privkey.pem
   docker compose restart nginx
   ```

## Sao lưu CSDL

```bash
docker compose exec -T db pg_dump -U postgres chailish_db | gzip > backup_$(date +%F).sql.gz
# Khôi phục:
gunzip -c backup_2026-11-21.sql.gz | docker compose exec -T db psql -U postgres chailish_db
```

## CI (GitHub Actions)

Workflow nằm ở `nhom11-65ktpm/.github/workflows/ci.yml` gồm 3 job: `backend` (Alembic trên PostgreSQL 16 + pytest), `mobile` (flutter analyze + test), `docker` (build image và gọi `/api/health` qua HTTPS).

Vì quy chuẩn học phần chỉ cho commit trong thư mục nhóm, file workflow không nằm ở `.github/` gốc kho nên GitHub **chưa tự chạy**. Muốn bật trên kho Fork, copy file lên gốc (không đưa vào PR gửi giảng viên):

```bash
mkdir -p .github/workflows
cp nhom11-65ktpm/.github/workflows/ci.yml .github/workflows/nhom11-ci.yml
```

Trước khi mở PR, chạy cùng các bước ở máy local: `bash nhom11-65ktpm/scripts/ci.sh`.
