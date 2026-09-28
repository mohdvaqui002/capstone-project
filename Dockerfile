FROM nginx:1.28-alpine
COPY website-master/ /usr/share/nginx/html/
EXPOSE 80
