FROM nginx:alpine

RUN rm -rf /etc/nginx/conf.d/*
RUN rm -rf /usr/share/nginx/html/*

COPY nginx.conf /etc/nginx/conf.d/default.conf

COPY app/ /usr/share/nginx/html/

EXPOSE 80
