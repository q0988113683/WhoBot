# 多階段建置：先用 Flutter 映像編出 web 靜態檔，再用 nginx 提供服務
FROM ghcr.io/cirruslabs/flutter:3.41.2 AS build
WORKDIR /app
COPY . .
RUN flutter pub get && flutter build web --release

FROM nginx:alpine
# Railway 會以 $PORT 注入監聽埠；本地預設 8080
ENV PORT=8080
COPY --from=build /app/build/web /usr/share/nginx/html
# nginx:alpine 的 entrypoint 會用 envsubst 把 templates 內的 ${PORT} 代入
COPY nginx.conf.template /etc/nginx/templates/default.conf.template
