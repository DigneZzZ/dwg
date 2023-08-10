#!/bin/bash

# Установка certbot
apt-get install certbot -y

# Запрос доменного имени у пользователя
read -p "Введите доменное имя: " domain

# Выдача сертификатов с помощью certbot
cert_path="/etc/letsencrypt/live/$domain"
certbot certonly --standalone --agree-tos --register-unsafely-without-email -d $domain --cert-name $domain

# Проверка обновления сертификатов в режиме "dry-run"
certbot renew --dry-run

# Вывод пути к файлам сертификатов и ключа
echo "Путь к файлам сертификатов и ключа: $cert_path"
