# Используем легковесный Nginx
FROM nginx:alpine

# Удаляем дефолтную страницу Nginx
RUN rm -rf /usr/share/nginx/html/*

# Копируем наш index.html в папку, откуда Nginx раздает статику
COPY app/ /usr/share/nginx/html/

# Пробрасываем 80 порт
EXPOSE 80

# Nginx запускается автоматически, CMD не нужен
