FROM nginx:1.27-alpine

# openssl để tự sinh chứng chỉ self-signed khi chưa có chứng chỉ thật.
RUN apk add --no-cache openssl

COPY nginx.conf /etc/nginx/nginx.conf
COPY conf.d/ /etc/nginx/conf.d/
COPY 40-ensure-certs.sh /docker-entrypoint.d/40-ensure-certs.sh
RUN chmod +x /docker-entrypoint.d/40-ensure-certs.sh
