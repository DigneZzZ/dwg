#!/bin/bash

# Здесь идет код скрипта, который должен быть выполнен на всех системах, кроме Debian 10

GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
RED='\033[0;31m'
NC='\033[0m'



# Устанавливаем apache2-utils, если она не установлена
if ! [ -x "$(command -v htpasswd)" ]; then
  echo -e "${RED}Установка apache2-utils...${NC}" >&2
   apt-get update
   apt-get install apache2-utils -y
fi


# Если логин не введен, устанавливаем логин по умолчанию "admin"
while true; do
  echo -e "${YELLOW}Введите логин (только латинские буквы и цифры), если пропустить шаг будет задан логин admin:${NC}"  
  read username
  if [ -z "$username" ]; then
    username="admin"
    break
  fi
  if ! [[ "$username" =~ [^a-zA-Z0-9] ]]; then
    break
  else
    echo -e "${RED}Логин должен содержать только латинские буквы и цифры.${NC}"
  fi
done

# Запрашиваем у пользователя пароль
while true; do
  echo -e "${YELLOW}Введите пароль (если нажать Enter, пароль будет задан по умолчанию admin):${NC}"  
  read password
  if [ -z "$password" ]; then
    password="admin"
    break
  fi
  if ! [[ "$password" =~ [^a-zA-Z0-9] ]]; then
    break
  else
    echo -e "${RED}Пароль должен содержать латинские буквы верхнего и нижнего регистра, цифры.${NC}"
  fi
done

# Генерируем хеш пароля с помощью htpasswd из пакета apache2-utils
hashed_password=$(htpasswd -nbB $username "$password" | cut -d ":" -f 2)

# Экранируем символы / и & в hashed_password
hashed_password=$(echo "$hashed_password" | sed -e 's/[\/&]/\\&/g')

# Проверяем наличие файла AdGuardHome.yaml и его доступность для записи
if [ ! -w "conf/AdGuardHome.yaml" ]; then
  echo -e "${RED}Файл conf/AdGuardHome.yaml не существует или не доступен для записи.${NC}" >&2
  exit 1
fi

# Записываем связку логина и зашифрованного пароля в файл conf/AdGuardHome.yaml
if 
#  sed -i "s/\(name: $username\).*\(password: \).*/\1\n\2$hashed_password/" conf/AdGuardHome.yaml 
  sed -i -E "s/- name: .*/- name: $username/g" conf/AdGuardHome.yaml
  sed -i -E "s/password: .*/password: $hashed_password/g" conf/AdGuardHome.yaml
then
  # Выводим сообщение об успешной записи связки логина и пароля в файл
  echo -e "${GREEN}Связка логина и пароля успешно записана в файл conf/AdGuardHome.yaml${NC}"
else
  echo -e "${RED}Не удалось записать связку логина и пароля в файл conf/AdGuardHome.yaml.${NC}" >&2
  exit 1
fi
# Выводим связку логина и пароля в консоль
echo "Ниже представлены логин и пароль для входа в AdGuardHome"
echo -e "${GREEN}Логин: $username${NC}"
echo -e "${GREEN}Пароль: $password${NC}"
