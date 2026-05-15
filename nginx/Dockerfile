FROM nginx:alpine
RUN echo "$SSL_KEY" > /etc/nginx/ssl/fullchain.pem \
  && echo "$SSL_CRT" > /etc/nginx/ssl/privatekey.pem
