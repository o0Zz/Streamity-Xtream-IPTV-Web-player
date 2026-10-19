FROM node:24-alpine AS builder
WORKDIR /app
COPY package.json package-lock.json ./
RUN npm ci
COPY . .
RUN npm run build

FROM alpine:3.24
RUN apk upgrade --no-cache \
    && apk add --no-cache apache2 php84-apache2 php84-openssl php84-pdo_mysql php84-simplexml \
    && sed -i \
        -e 's#^DocumentRoot ".*"#DocumentRoot "/var/www/html"#' \
        -e 's#^<Directory "/var/www/localhost/htdocs">#<Directory "/var/www/html">#' \
        -e 's#^\#ServerName .*#ServerName localhost#' \
        -e 's#^ErrorLog .*#ErrorLog /dev/stderr#' \
        -e 's#^\(\s*\)CustomLog .*#\1CustomLog /dev/stdout combined#' \
        /etc/apache2/httpd.conf \
    && mkdir -p /var/www/html
COPY --from=builder /app/build /var/www/html/
WORKDIR /var/www/html/
EXPOSE 80
CMD ["httpd", "-D", "FOREGROUND"]
