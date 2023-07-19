#!/bin/bash

# Находим все файлы docker-compose.yml
file_paths=$(find / -name "docker-compose.yml" 2>/dev/null)

# Проверяем, что найдены файлы
if [[ -z "$file_paths" ]]; then
  echo "Файлы docker-compose.yml не найдены."
  exit 1
fi

# Выводим список найденных файлов и просим пользователя выбрать один из них
echo "Найдены следующие файлы docker-compose.yml:"
i=1
for file_path in $file_paths; do
  echo "$i. $file_path"
  ((i++))
done

read -p "Введите номер файла, с которым вы хотите работать: " selected_index

# Проверяем, что выбран правильный индекс
if [[ ! "$selected_index" =~ ^[0-9]+$ || "$selected_index" -lt 1 || "$selected_index" -gt "$i" ]]; then
  echo "Некорректный номер файла."
  exit 1
fi

# Получаем путь выбранного файла
selected_file_path=$(echo "$file_paths" | sed -n "${selected_index}p")

# Ищем параметр PASSWORD в файле и получаем текущее значение
current_password=$(grep -Po "(?<=PASSWORD=).*" "$selected_file_path")

# Проверяем, что параметр PASSWORD найден
if [[ -z "$current_password" ]]; then
  echo "Параметр PASSWORD не найден в выбранном файле docker-compose.yml."
  exit 1
fi

# Запрашиваем у пользователя новое значение для пароля
read -p "Введите новое значение для пароля: " new_password

# Проверяем, что новый пароль соответствует требованиям
if ! [[ "$new_password" =~ ^[a-zA-Z0-9]+$ ]]; then
  echo "Новый пароль должен содержать только символы латинского алфавита и несколько основных знаков, и быть в длину не больше 15 символов."
  exit 1
fi

# Заменяем текущее значение пароля на новое в файле
sed -i "s/PASSWORD=$current_password/PASSWORD=$new_password/" "$selected_file_path"

# Запрашиваем у пользователя, хочет ли он перезапустить контейнер
read -p "Хотите ли вы перезапустить контейнер? (да/нет) [да]: " restart_container
restart_container=${restart_container:-да}

# Если пользователь хочет перезапустить контейнер, переходим в папку с выбранным файлом docker-compose.yml и выполняем команду docker-compose up -d --force-recreate
if [[ "$restart_container" == "да" ]]; then
  cd "$(dirname "$selected_file_path")"
  docker-compose up -d --force-recreate
fi

# Выводим путь до выбранного файла docker-compose.yml и заданный пароль
echo -e "\e[38;5;208mПуть до выбранного файла docker-compose.yml: $selected_file_path\e[0m"
echo -e "\e[38;5;208mЗаданный пароль: $new_password\e[0m"
