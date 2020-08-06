FROM node:alpine

RUN apk update
RUN apk add supervisor
RUN apk add nginx

COPY configs/supervisord.conf /etc/
COPY configs/nginxDefaultSite  /etc/nginx/conf.d/default.conf

COPY client/dist/client /var/www/html
COPY server /home/node/

RUN ls

RUN mkdir -p /run/nginx

ENTRYPOINT /usr/bin/supervisord -c /etc/supervisord.conf

EXPOSE 80 3000
