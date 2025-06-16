FROM nginx:alpine

RUN apk add --no-cache curl

COPY nginx.conf /etc/nginx/nginx.conf

COPY page /usr/share/nginx/html

EXPOSE 80

CMD ["nginx", "-g", "daemon off;"]