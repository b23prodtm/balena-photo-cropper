FROM nginx:alpine
RUN echo "$SSL_KEY" > /etc/nginx/certs/privkey.pem \
  && echo "$SSL_CRT" > /etc/nginx/certs/fullchain.pem
