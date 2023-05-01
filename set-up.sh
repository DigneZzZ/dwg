#!/bin/bash
# Получаем внешний IP-адрес
MYHOST_IP=$(hostname -I | cut -d' ' -f1)
# Обновление пакетов
printf "\e[42mОбновление пакетов системы...\e[0m\n"
apt update
printf "\e[42mПакеты успешно обновлены.\e[0m\n"

# Установка Git
printf "\e[42mУстановка Git...\e[0m\n"
apt install git -y
printf "\e[42mGit успешно установлен.\e[0m\n"

# Клонирование репозитория
printf "\e[42mКлонирование репозитория dwg...\e[0m\n"
git clone https://github.com/dignezzz/dwg.git temp

if [ ! -d "dwg" ]; then
  mkdir dwg
  echo "Папка DWG создана."
else
  echo "Папка DWG уже существует."
fi

# копирование содержимого временной директории в целевую директорию с перезаписью существующих файлов и папок
cp -rf temp/* dwg/

# удаление временной директории со всем ее содержимым
rm -rf temp
printf "\e[42mРепозиторий dwg успешно клонирован до актуальной версии из репозитория автора.\e[0m\n"

# Установка прав на директорию tools
printf "\e[42mУстановка прав на директорию DWG...\e[0m\n"
chmod +x -R dwg
printf "\e[42mПрава на директорию DWG успешно установлены.\e[0m\n"

# Переходим в папку DWG
printf "\e[42mПереходим в папку dwg...\e[0m\n"
cd dwg
printf "\e[42mПерешли в папку dwg\e[0m\n"

# Выводим в консоль сообщение с инструкциями для пользователя
printf "Выберите, что хотите установить:\n1. DWG-CLI\n2. DWG-UI\n"

# Считываем ввод пользователя и сохраняем его в переменную
read -r user_input

# Проверяем, что пользователь ввел 1 или 2
if [[ "$user_input" == "1" ]]; then
  # Проверяем, существует ли файл docker-compose.yml
  if [[ -f "docker-compose.yml" ]]; then
    # Если файл существует, предлагаем пользователю переименовать его
    printf "Файл docker-compose.yml уже существует. Хотите переименовать его в docker-compose.yml.old? (y/n)\n"
    read -r rename_response
    if [[ "$rename_response" == "y" ]]; then
      mv docker-compose.yml docker-compose.yml.old.$((100 + RANDOM % 2900))
    else
      exit 1
    fi
  fi
  # Переименовываем файл docker-compose.yml.CLI в docker-compose.yml
  mv docker-compose.yml.CLI docker-compose.yml
  printf "Файл docker-compose.yml.CLI успешно переименован в docker-compose.yml\n"
elif [[ "$user_input" == "2" ]]; then
  # Проверяем, существует ли файл docker-compose.yml
  if [[ -f "docker-compose.yml" ]]; then
    # Если файл существует, предлагаем пользователю переименовать его
    printf "Файл docker-compose.yml уже существует. Хотите переименовать его в docker-compose.yml.old? (y/n)\n"
    read -r rename_response
    if [[ "$rename_response" == "y" ]]; then
      mv docker-compose.yml docker-compose.yml.old.$((100 + RANDOM % 2900))
    else
      exit 1
    fi
  fi
  # Переименовываем файл docker-compose.yml.UI в docker-compose.yml
  mv docker-compose.yml.UI docker-compose.yml
  printf "Файл docker-compose.yml.UI успешно переименован в docker-compose.yml\n"
else
  # Если пользователь ввел что-то кроме 1 или 2, выводим ошибку
  printf "Ошибка: некорректный ввод\n"
  exit 1
fi
