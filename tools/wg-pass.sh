#!/bin/bash

# Находим файл docker-compose.yml
file_path=$(find / -name "docker-compose.yml" 2>/dev/null)

# Проверяем, что файл существует
if [[ -z "$file_path" ]]; then
  echo "Файл docker-compose.yml не найден."
  exit 1
fi

# Ищем параметр PASSWORD в файле и получаем текущее значение
current_password=$(grep -Po "(?<=PASSWORD=).*" "$file_path")

# Проверяем, что параметр PASSWORD найден
if [[ -z "$current_password" ]]; then
  echo "Параметр PASSWORD не найден в файле docker-compose.yml."
  exit 1
fi

# Запрашиваем у пользователя новое значение для пароля
read -p "Введите новое значение для пароля: " new_password

# Проверяем, что новый пароль соответствует требованиям
if [[ ! "$new_password" =~ ^[a-zA-Z0-9!@#$%^&*()-_]{1,15}$ ]]; then
  echo "Новый пароль должен содержать только символы латинского алфавита и несколько основных знаков, и быть в длину не больше 15 символов."
  exit 1
fi

# Заменяем текущее значение пароля на новое в файле
sed -i "s/PASSWORD=$current_password/PASSWORD=$new_password/" "$file_path"

# Запрашиваем у пользователя, хочет ли он перезапустить контейнер
read -p "Хотите ли вы перезапустить контейнер? (да/нет) [да]: " restart_container
restart_container=${restart_container:-да}

# Если пользователь хочет перезапустить контейнер, переходим в папку с файлом docker-compose.yml и выполняем команду docker-compose up -d --force-recreate
if [[ "$restart_container" == "да" ]]; then
  cd "$(dirname "$file_path")"
  docker-compose up -d --force-recreate
fi

# Выводим путь до файла docker-compose.yml и заданный пароль
echo -e "\e[38;5;208mПуть до файла docker-compose.yml: $file_path\e[0m"
echo -e "\e[38;5;208mЗаданный пароль: $new_password\e[0m"
