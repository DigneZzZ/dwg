#!/bin/bash

echo '  



      ██████╗ ██╗    ██╗ ██████╗ 
      ██╔══██╗██║    ██║██╔════╝ 
      ██║  ██║██║ █╗ ██║██║  ███╗
      ██║  ██║██║███╗██║██║   ██║
      ██████╔╝╚███╔███╔╝╚██████╔╝
      ╚═════╝  ╚══╝╚══╝  ╚═════╝ 
                           
BBBB  Y   Y     DDD  III  GGG  N   N EEEE ZZZZZ ZZZZZ ZZZZZ 
B   B  Y Y      D  D  I  G     NN  N E       Z     Z     Z  
BBBB    Y       D  D  I  G  GG N N N EEE    Z     Z     Z   
B   B   Y       D  D  I  G   G N  NN E     Z     Z     Z    
BBBB    Y       DDD  III  GGG  N   N EEEE ZZZZZ ZZZZZ ZZZZZ 
                                                            

'
sleep 2s

if grep -q "VERSION_ID=\"10\"" /etc/os-release; then
  echo "Этот скрипт не может быть выполнен на Debian 10."
  exit 1
fi

# Здесь идет код скрипта, который должен быть выполнен на всех системах, кроме Debian 10

GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
RED='\033[0;31m'
NC='\033[0m'

# Проверяем, выполняется ли скрипт от имени пользователя root
if [ "$EUID" -ne 0 ]; then
  echo -e "${RED}Запустите скрипт с правами root${NC}"
  exit
fi


# Получаем внешний IP-адрес
MYHOST_IP=$(curl -s https://checkip.amazonaws.com/) 
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




# Устанавливаем редактор Nano
if ! command -v nano &> /dev/null
then
    read -p "Хотите установить текстовый редактор Nano? (y/n) " INSTALL_NANO
    if [ "$INSTALL_NANO" == "y" ]; then
        apt-get update
        apt-get install -y nano
    fi
else
    echo "Текстовый редактор Nano уже установлен."
fi
printf "\e[42mЗапускаем скрипт для установки Docker и Docker-compose...\e[0m\n"
./tools/docker.sh
printf "\e[42mЗакончили выполнение скрипта\e[0m\n"

# Выводим в консоль сообщение с инструкциями для пользователя
printf "Предлагается установка одной из следующих сборок:\n"
printf "1. DWG-CLI - сборка с классическим WireGuard и управлением через командную строку (или ручную корректировку docker-compose.yml) \n"
printf "2. DWG-UI - сборка с веб-интерфейсом в реализации WG-Easy (есть возможность использования API)\n"
printf "3. DWG-DARK - сборка (экспериментальная) с веб-интерфейсом в реализации WG-Easy, но собрано в одной сети с AdGuardHome - обеспечивает контроль за каждым пользователем.\n"
printf "Выберите, что хотите установить (введите номер 1 или 2 или 3):"

# Считываем ввод пользователя и сохраняем его в переменную
read -r dwg_set

# Проверяем, что пользователь ввел 1 или 2
if [[ "$dwg_set" == "1" ]]; then
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
    #### #### #### #### #### #### #### #### #### #### #### #### #### #### #### ####   #### #### #### #### #### #### #### #### #### #### #### #### #### #### #### #### 
      #### #### #### #### #### #### #### #### #### #### #### #### #### #### #### ####   #### #### #### #### #### #### #### #### #### #### #### #### #### #### #### #### 
        #### #### #### #### #### #### #### #### #### #### #### #### #### #### #### ####   #### #### #### #### #### #### #### #### #### #### #### #### #### #### #### #### 
          #### #### #### #### #### #### #### #### #### #### #### #### #### #### #### ####   #### #### #### #### #### #### #### #### #### #### #### #### #### #### #### #### 
            #### #### #### #### #### #### #### #### #### #### #### #### #### #### #### ####   #### #### #### #### #### #### #### #### #### #### #### #### #### #### #### #### 
  #### #### #### #### #### #### #### #### #### #### #### #### #### #### #### ####   #### #### #### #### #### #### #### #### #### #### #### #### #### #### #### #### 
 #### ЗДЕСЬ КОД ДЛЯ УСТАНОВКИ DWG-CLI


# Проверяем есть ли контейнер с именем wireguard

printf "${BLUE} Сейчас проверим свободен ли порт 51820 и не установлен ли другой wireguard.\n${NC}"

if [[ $(docker ps -q --filter "name=wireguard") ]]; then
    printf "!!!!>>> Другой Wireguard контейнер уже запущен, и вероятно занимает порт 51820. Пожалуйста удалите его и запустите скрипт заново\n "
    printf "${RED} !!!!>>> Завершаю скрипт! \n${NC}"
    exit 1
else
    printf "Wireguard контейнер не запущен в докер. Можно продолжать\n"
    # Проверка, запущен ли контейнер, использующий порт 51821
    if lsof -Pi :51820 -sTCP:LISTEN -t >/dev/null ; then
        printf "${RED}!!!!>>> Порт 51820 уже используется контейнером.!\n ${NC}"
        if docker ps --format '{{.Names}} {{.Ports}}' | grep -q "wireguard.*:51820->" ; then
            printf "WireGuard контейнер использует порт 51820. Хотите продолжить установку? (y/n): "
            read -r choice
            case "$choice" in 
              y|Y ) printf "Продолжаем установку...\n" ;;
              n|N ) printf "${RED} ******* Завершаю скрипт!\n ${NC}" ; exit 1;;
              * ) printf "${RED}Некорректный ввод. Установка остановлена.${NC}" ; exit 1;;
            esac
        else
            printf "${RED} ******* Завершаю скрипт!\n ${NC}"
            exit 1
        fi
    else
        printf "Порт 51820 свободен.\n"
        printf "Хотите продолжить установку? (y/n): "
        read -r choice
        case "$choice" in 
          y|Y ) printf "Продолжаем установку...\n" ;;
          n|N ) printf "Установка остановлена.${NC}" ; exit 1;;
          * ) printf "${RED}Некорректный ввод. Установка остановлена.${NC}" ; exit 1;;
        esac
    fi
fi

printf "${GREEN} Этап проверки докера закончен, можно продолжить установку\n${NC}"



##### ЗДЕСЬ БУДЕТ КОД ДЛЯ КОРРЕКТИРОВКИ COMPOSE
# Получаем внешний IP-адрес
MYHOST_IP=$(curl -s https://checkip.amazonaws.com/) 

# Записываем IP-адрес в файл docker-compose.yml с меткой MYHOSTIP
sed -i -E  "s/- SERVERURL=.*/- SERVERURL=$MYHOST_IP/g" docker-compose.yml

echo "Выберите способ настройки PEERS:"
echo "1. Установить количество пиров"
echo "2. Задать имена пиров через запятую"
read -p "Введите номер способа: " choice

if [ $choice -eq 1 ]
then
    read -p "Введите количество пиров: " peers
    sed -i "s/- PEERS=1/- PEERS=$peers/g" docker-compose.yml
    echo "Количество пиров изменено на $peers"
elif [ $choice -eq 2 ]
then
    read -p "Введите имена пиров через запятую: " peers
    # Проверяем, используются ли имена
    if [[ "$peers" == *[!a-zA-Z0-9,]* ]]
    then
        echo "Ошибка: имена пиров могут содержать только латинские буквы и цифры"
        exit 1
    fi
    # Проверяем, существует ли уже переменная среды PEERS
    if grep -q "PEERS=" docker-compose.yml
    then
        # Если переменная уже существует
        # Спрашиваем пользователя, заменить ли текущие имена на новые
        echo "Переменная PEERS уже существует"
        echo "1. Заменить текущие имена на новые"
        echo "2. Добавить новые имена к текущим"
        read -p "Введите номер способа: " add_choice
        if [ $add_choice -eq 1 ]
        then
            sed -i "s/- PEERS=.*/- PEERS=$peers/g" docker-compose.yml
        elif [ $add_choice -eq 2 ]
        then
            current_peers=$(grep PEERS docker-compose.yml | cut -d '=' -f 2 | tr -d '"')
            new_peers=$(echo "$current_peers,$peers")
            sed -i "s/- PEERS=.*/- PEERS=$new_peers/g" docker-compose.yml
        else
            echo "Ошибка: неверный выбор"
            exit 1
        fi
    else
        # Если переменная не существует, добавляем ее с новыми именами
        sed -i "s/- PEERS=1/- PEERS=\"$peers\"/g" docker-compose.yml
    fi
    echo "Имена пиров изменены на $peers"
else
    echo "Ошибка: неверный выбор"
    exit 1
fi


 #### ЗДЕСЬ КОНЕЦ КОДА
  #### #### #### #### #### #### #### #### #### #### #### #### #### #### #### ####   #### #### #### #### #### #### #### #### #### #### #### #### #### #### #### #### 
    #### #### #### #### #### #### #### #### #### #### #### #### #### #### #### ####   #### #### #### #### #### #### #### #### #### #### #### #### #### #### #### #### 
      #### #### #### #### #### #### #### #### #### #### #### #### #### #### #### ####   #### #### #### #### #### #### #### #### #### #### #### #### #### #### #### #### 
        #### #### #### #### #### #### #### #### #### #### #### #### #### #### #### ####   #### #### #### #### #### #### #### #### #### #### #### #### #### #### #### #### 
          #### #### #### #### #### #### #### #### #### #### #### #### #### #### #### ####   #### #### #### #### #### #### #### #### #### #### #### #### #### #### #### #### 
          
elif [[ "$dwg_set" == "2" ]]; then
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
  #### #### #### #### #### #### #### #### #### #### #### #### #### #### #### ####   #### #### #### #### #### #### #### #### #### #### #### #### #### #### #### #### 
    #### #### #### #### #### #### #### #### #### #### #### #### #### #### #### ####   #### #### #### #### #### #### #### #### #### #### #### #### #### #### #### #### 
      #### #### #### #### #### #### #### #### #### #### #### #### #### #### #### ####   #### #### #### #### #### #### #### #### #### #### #### #### #### #### #### #### 
        #### #### #### #### #### #### #### #### #### #### #### #### #### #### #### ####   #### #### #### #### #### #### #### #### #### #### #### #### #### #### #### #### 
          #### #### #### #### #### #### #### #### #### #### #### #### #### #### #### ####   #### #### #### #### #### #### #### #### #### #### #### #### #### #### #### #### 
            #### #### #### #### #### #### #### #### #### #### #### #### #### #### #### ####   #### #### #### #### #### #### #### #### #### #### #### #### #### #### #### #### 
 #### ЗДЕСЬ КОД ДЛЯ УСТАНОВКИ DWG-UI
# Проверяем есть ли контейнер с именем wireguard

printf "${BLUE} Сейчас проверим свободен ли порт 51821 и не установлен ли другой wireguard.\n${NC}"

if [[ $(docker ps -q --filter "name=wireguard") ]]; then
    printf "!!!!>>> Другой Wireguard контейнер уже запущен, и вероятно занимает порт 51821. Пожалуйста удалите его и запустите скрипт заново\n "
    printf "${RED} !!!!>>> Завершаю скрипт! \n${NC}"
    exit 1
else
    printf "Wireguard контейнер не запущен в докер. Можно продолжать\n"
    # Проверка, запущен ли контейнер, использующий порт 51821
    if lsof -Pi :51821 -sTCP:LISTEN -t >/dev/null ; then
        printf "${RED}!!!!>>> Порт 51821 уже используется контейнером.!\n ${NC}"
        if docker ps --format '{{.Names}} {{.Ports}}' | grep -q "wg-easy.*:51821->" ; then
            echo  "Для смены параметров WireGuard и окружения, используйте скрипт change.sh: "
            printf "WG-EASY контейнер использует порт 51821. Хотите продолжить установку? (y/n): "
            read -r choice
            case "$choice" in 
              y|Y ) printf "Продолжаем установку...\n" ;;
              n|N ) printf "${RED} ******* Завершаю скрипт!\n ${NC}" ; exit 1;;
              * ) printf "${RED}Некорректный ввод. Установка остановлена.${NC}" ; exit 1;;
            esac
        else
            printf "${RED} ******* Завершаю скрипт!\n ${NC}"
            exit 1
        fi
    else
        printf "Порт 51821 свободен.\n"
        printf "Хотите продолжить установку? (y/n): "
        read -r choice
        case "$choice" in 
          y|Y ) printf "Продолжаем установку...\n" ;;
          n|N ) printf "Установка остановлена.${NC}" ; exit 1;;
          * ) printf "${RED}Некорректный ввод. Установка остановлена.${NC}" ; exit 1;;
        esac
    fi
fi

printf "${GREEN} Этап проверки докера закончен, можно продолжить установку\n${NC}"

# Получаем внешний IP-адрес
MYHOST_IP=$(curl -s https://checkip.amazonaws.com/) 

# Записываем IP-адрес в файл docker-compose.yml с меткой MYHOSTIP
sed -i -E  "s/- WG_HOST=.*/- WG_HOST=$MYHOST_IP/g" docker-compose.yml

# Запросите у пользователя пароль
echo ""
echo ""
#while true; do
#  read -p "Введите пароль для веб-интерфейса: " WEBPASSWORD
#  echo ""

# if [[ "$WEBPASSWORD" =~ ^[[:alnum:]]+$ ]]; then
#    # Записываем в файл новый пароль в кодировке UTF-8
#    sed -i -E "s/- PASSWORD=.*/- PASSWORD=$WEBPASSWORD/g" docker-compose.yml
#    break
#  else
#    echo "Пароль должен состоять только из английских букв и цифр, без пробелов и специальных символов."
#  fi
#done
echo -e "Введите пароль для веб-интерфейса (если пропустить, по умолчанию будет задан openode) "
read -p "Требования к паролю: Пароль может содержать только цифры и английские символы: " WEBPASSWORD || WEBPASSWORD="openode"
echo ""

if [[ "$WEBPASSWORD" =~ ^[[:alnum:]]+$ ]]; then
  # Записываем в файл новый пароль в кодировке UTF-8
  sed -i -E "s/- PASSWORD=.*/- PASSWORD=$WEBPASSWORD/g" docker-compose.yml
else
  echo "Пароль должен состоять только из английских букв и цифр, без пробелов и специальных символов."
fi


# Даем пользователю информацию по установке
# Читаем текущие значения из файла docker-compose.yml
CURRENT_PASSWORD=$(grep PASSWORD docker-compose.yml | cut -d= -f2)
CURRENT_WG_HOST=$(grep WG_HOST docker-compose.yml | cut -d= -f2)
CURRENT_WG_DEFAULT_ADDRESS=$(grep WG_DEFAULT_ADDRESS docker-compose.yml | cut -d= -f2)
CURRENT_WG_DEFAULT_DNS=$(grep WG_DEFAULT_DNS docker-compose.yml | cut -d= -f2)


# Выводим текущие значения
echo ""
echo -e "${BLUE}Текущие значения:${NC}"
echo ""
echo -e "Пароль от веб-интерфейса: ${BLUE}$CURRENT_PASSWORD${NC}"
echo -e "IP адрес сервера: ${BLUE}$CURRENT_WG_HOST${NC}"
echo -e "Маска пользовательских IP: ${BLUE}$CURRENT_WG_DEFAULT_ADDRESS${NC}"
echo -e "Адрес входа в веб-интерфейс WireGuard после установки: ${YELLOW}http://$CURRENT_WG_HOST:51821${NC}"
echo ""

 #### ЗДЕСЬ КОНЕЦ КОДА
  #### #### #### #### #### #### #### #### #### #### #### #### #### #### #### ####   #### #### #### #### #### #### #### #### #### #### #### #### #### #### #### #### 
    #### #### #### #### #### #### #### #### #### #### #### #### #### #### #### ####   #### #### #### #### #### #### #### #### #### #### #### #### #### #### #### #### 
      #### #### #### #### #### #### #### #### #### #### #### #### #### #### #### ####   #### #### #### #### #### #### #### #### #### #### #### #### #### #### #### #### 
        #### #### #### #### #### #### #### #### #### #### #### #### #### #### #### ####   #### #### #### #### #### #### #### #### #### #### #### #### #### #### #### #### 
          #### #### #### #### #### #### #### #### #### #### #### #### #### #### #### ####   #### #### #### #### #### #### #### #### #### #### #### #### #### #### #### #### 
          
elif [[ "$dwg_set" == "3" ]]; then  #DWG-DARK
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

  #### #### #### #### #### #### #### #### #### #### #### #### #### #### #### ####   #### #### #### #### #### #### #### #### #### #### #### #### #### #### #### #### 
    #### #### #### #### #### #### #### #### #### #### #### #### #### #### #### ####   #### #### #### #### #### #### #### #### #### #### #### #### #### #### #### #### 
      #### #### #### #### #### #### #### #### #### #### #### #### #### #### #### ####   #### #### #### #### #### #### #### #### #### #### #### #### #### #### #### #### 
        #### #### #### #### #### #### #### #### #### #### #### #### #### #### #### ####   #### #### #### #### #### #### #### #### #### #### #### #### #### #### #### #### 
          #### #### #### #### #### #### #### #### #### #### #### #### #### #### #### ####   #### #### #### #### #### #### #### #### #### #### #### #### #### #### #### #### 
            #### #### #### #### #### #### #### #### #### #### #### #### #### #### #### ####   #### #### #### #### #### #### #### #### #### #### #### #### #### #### #### #### 
 #### ЗДЕСЬ КОД ДЛЯ УСТАНОВКИ DWG-DARK
# Проверяем есть ли контейнер с именем wireguard

printf "${BLUE} Сейчас проверим свободен ли порт 51821 и не установлен ли другой wireguard.\n${NC}"

if [[ $(docker ps -q --filter "name=wireguard") ]]; then
    printf "!!!!>>> Другой Wireguard контейнер уже запущен, и вероятно занимает порт 51821. Пожалуйста удалите его и запустите скрипт заново\n "
    printf "${RED} !!!!>>> Завершаю скрипт! \n${NC}"
    exit 1
else
    printf "Wireguard контейнер не запущен в докер. Можно продолжать\n"
    # Проверка, запущен ли контейнер, использующий порт 51821
    if lsof -Pi :51821 -sTCP:LISTEN -t >/dev/null ; then
        printf "${RED}!!!!>>> Порт 51821 уже используется контейнером.!\n ${NC}"
        if docker ps --format '{{.Names}} {{.Ports}}' | grep -q "wg-easy.*:51821->" ; then
            printf "WG-EASY контейнер использует порт 51821. Хотите продолжить установку? (y/n): "
            read -r choice
            case "$choice" in 
              y|Y ) printf "Продолжаем установку...\n" ;;
              n|N ) printf "${RED} ******* Завершаю скрипт!\n ${NC}" ; exit 1;;
              * ) printf "${RED}Некорректный ввод. Установка остановлена.${NC}" ; exit 1;;
            esac
        else
            printf "${RED} ******* Завершаю скрипт!\n ${NC}"
            exit 1
        fi
    else
        printf "Порт 51821 свободен.\n"
        printf "Хотите продолжить установку? (y/n): "
        read -r choice
        case "$choice" in 
          y|Y ) printf "Продолжаем установку...\n" ;;
          n|N ) printf "Установка остановлена.${NC}" ; exit 1;;
          * ) printf "${RED}Некорректный ввод. Установка остановлена.${NC}" ; exit 1;;
        esac
    fi
fi

printf "${GREEN} Этап проверки докера закончен, можно продолжить установку\n${NC}"

#  printf "Для корректной работы данной сборки необходимо освободить 53 порт. Сделать это автоматическим скриптом? Гарантий работоспособности на вашей операционной системе мы не даем!!! (Y/n) (по умолчанию - Y, можете нажать Enter): "
#read choice_resolv

#  if [[ $choice_resolv == "" || $choice_resolv == "Y" || $choice_resolv == "y" ]]; then

    #printf "\e[42mДля корректной работы сборки DWG-DARK запустите скрипт {RED}./dwg/53getfree.sh \e[42m (будет выполнена перезагрузка)\e[0m\n"
    #printf "\e[42mЕсли вы это уже сделали, подождите просто 5 секунд  и установка продолжится.\e[0m\n"
    #sleep 5

  #else
  #  printf "Скрипт не будет запущен.\n"
  #  exit 1
  #fi


  # Переименовываем файл docker-compose.yml.UI в docker-compose.yml
  mv docker-compose.yml.DARK docker-compose.yml
  printf "Файл docker-compose.yml.DARK успешно переименован в docker-compose.yml\n"
  
# Получаем внешний IP-адрес
MYHOST_IP=$(curl -s https://checkip.amazonaws.com/) 

# Записываем IP-адрес в файл docker-compose.yml с меткой MYHOSTIP
sed -i -E  "s/- WG_HOST=.*/- WG_HOST=$MYHOST_IP/g" docker-compose.yml

# Запросите у пользователя пароль
echo ""
echo ""

echo -e "Введите пароль для веб-интерфейса (если пропустить, по умолчанию будет задан openode) "
read -p "Требования к паролю: Пароль может содержать только цифры и английские символы: " WEBPASSWORD || WEBPASSWORD="openode"
echo ""

if [[ "$WEBPASSWORD" =~ ^[[:alnum:]]+$ ]]; then
  # Записываем в файл новый пароль в кодировке UTF-8
  sed -i -E "s/- PASSWORD=.*/- PASSWORD=$WEBPASSWORD/g" docker-compose.yml
else
  echo "Пароль должен состоять только из английских букв и цифр, без пробелов и специальных символов."
fi


# Даем пользователю информацию по установке
# Читаем текущие значения из файла docker-compose.yml
CURRENT_PASSWORD=$(grep PASSWORD docker-compose.yml | cut -d= -f2)
CURRENT_WG_HOST=$(grep WG_HOST docker-compose.yml | cut -d= -f2)
CURRENT_WG_DEFAULT_ADDRESS=$(grep WG_DEFAULT_ADDRESS docker-compose.yml | cut -d= -f2)
CURRENT_WG_DEFAULT_DNS=$(grep WG_DEFAULT_DNS docker-compose.yml | cut -d= -f2)


# Выводим текущие значения
echo ""
echo -e "${BLUE}Текущие значения:${NC}"
echo ""
echo -e "Пароль от веб-интерфейса: ${BLUE}$CURRENT_PASSWORD${NC}"
echo -e "IP адрес сервера: ${BLUE}$CURRENT_WG_HOST${NC}"
echo -e "Маска пользовательских IP: ${BLUE}$CURRENT_WG_DEFAULT_ADDRESS${NC}"
echo -e "Адрес входа в веб-интерфейс WireGuard после установки: ${YELLOW}http://$CURRENT_WG_HOST:51821${NC}"
echo ""

 #### ЗДЕСЬ КОНЕЦ КОДА
  #### #### #### #### #### #### #### #### #### #### #### #### #### #### #### ####   #### #### #### #### #### #### #### #### #### #### #### #### #### #### #### #### 
    #### #### #### #### #### #### #### #### #### #### #### #### #### #### #### ####   #### #### #### #### #### #### #### #### #### #### #### #### #### #### #### #### 
      #### #### #### #### #### #### #### #### #### #### #### #### #### #### #### ####   #### #### #### #### #### #### #### #### #### #### #### #### #### #### #### #### 
        #### #### #### #### #### #### #### #### #### #### #### #### #### #### #### ####   #### #### #### #### #### #### #### #### #### #### #### #### #### #### #### #### 
          #### #### #### #### #### #### #### #### #### #### #### #### #### #### #### ####   #### #### #### #### #### #### #### #### #### #### #### #### #### #### #### #### 
else
  # Если пользователь ввел что-то кроме 1 или 2 или 3, выводим ошибку
  printf "Ошибка: некорректный ввод\n"
  exit 1
fi


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
  sed -i -E "s/- name: .*/- name: $username/g" conf/AdGuardHome.yaml &&
  sed -i -E "s/password: .*/password: $hashed_password/g" conf/AdGuardHome.yaml
then
  # Выводим сообщение об успешной записи связки логина и пароля в файл
  echo -e "${GREEN}Связка логина и пароля успешно записана в файл conf/AdGuardHome.yaml${NC}"
else
  echo -e "${RED}Не удалось записать связку логина и пароля в файл conf/AdGuardHome.yaml.${NC}" >&2
  exit 1
fi




# Запускаем docker-compose
docker-compose up -d

# Проверяем, что пользователь ввел 1 или 2
if [[ "$dwg_set" == "2" ]]; then
  echo ""
  echo -e "${BLUE}Текущие значения:${NC}"
  echo ""
  echo -e "Пароль от веб-интерфейса: ${BLUE}$CURRENT_PASSWORD${NC}"
  echo -e "IP адрес сервера: ${BLUE}$CURRENT_WG_HOST${NC}"
  echo -e "Маска пользовательских IP: ${BLUE}$CURRENT_WG_DEFAULT_ADDRESS${NC}"
  echo -e "Адрес входа в веб-интерфейс WireGuard после установки: ${YELLOW}http://$CURRENT_WG_HOST:51821${NC}"
  echo ""
  printf '\e[48;5;202m\e[30m ################################################################## \e[0m\n'
  printf '\e[48;5;202m\e[30m Не забудь отдельно установить UFW-Docker, для закрытия веб-интерфейса wireguard. \e[0m\n'
  printf '\e[48;5;196m\e[97m ВНИМАНИЕ! Запускать только после того как создадите для себя клиента в WireGUARD!!! \e[0m\n'
  printf '\e[48;5;202m\e[30m команда для установки: ./dwg/tools/ufw-docker.sh \e[0m\n'
  printf '\e[48;5;202m\e[30m ################################################################## \e[0m\n'
  
  printf "Хотите запустить скрипт wg-ru.sh для русификации и модернизации интерфейса?? (Y/n) (по умолчанию - Y, можете нажать Enter): "
read choice_ru

  if [[ $choice_ru == "" || $choice_ru == "Y" || $choice_ru == "y" ]]; then
    ./tools/wg-ru.sh
  else
    printf "Скрипт не будет запущен.\n"
  fi

fi



if [[ "$dwg_set" == "3" ]]; then
  echo ""
  echo -e "${BLUE}Текущие значения DWG:${NC}"
  echo ""
  echo -e "Пароль от веб-интерфейса: ${BLUE}$CURRENT_PASSWORD${NC}"
  echo -e "IP адрес сервера: ${BLUE}$CURRENT_WG_HOST${NC}"
  echo -e "Маска пользовательских IP: ${BLUE}$CURRENT_WG_DEFAULT_ADDRESS${NC}"
  echo -e "Адрес входа в веб-интерфейс WireGuard после установки: ${YELLOW}http://$CURRENT_WG_HOST:51821${NC}"
  echo ""
  printf '\e[48;5;202m\e[30m ################################################################## \e[0m\n'
  printf '\e[48;5;202m\e[30m Не забудь отдельно установить UFW-Docker, для закрытия веб-интерфейса wireguard. \e[0m\n'
  printf '\e[48;5;196m\e[97m ВНИМАНИЕ! Запускать только после того как создадите для себя клиента в WireGUARD!!! \e[0m\n'
  printf '\e[48;5;202m\e[30m команда для установки: ./dwg/tools/ufw-docker.sh \e[0m\n'
  printf '\e[48;5;202m\e[30m ################################################################## \e[0m\n'
  
  printf "Хотите запустить скрипт wg-ru-d.sh для русификации и модернизации интерфейса?? (Y/n) (по умолчанию - Y, можете нажать Enter): "
read choice_ru

  if [[ $choice_ru == "" || $choice_ru == "Y" || $choice_ru == "y" ]]; then
    ./tools/wg-ru-d.sh
  else
    printf "Скрипт не будет запущен.\n"
  fi

fi

if [[ "$dwg_set" == "1" ]]; then
  echo ""
  echo -e "${BLUE}Для получения списка Пиров и данных по их подключению, воспользуйтесь командой {RED}cd dwg && ./peer.sh${NC}"
  echo -e "${BLUE}(Запуск производится из папки dwg скрипта ./peer.sh)${NC}"
fi
# Выводим связку логина и пароля в консоль
echo -e "Адрес входа в веб-интерфейс AdGuardHome после установки (только когда подключитесь к сети WireGuard!!!): ${BLUE}http://10.2.0.100${NC}"
echo "Ниже представлены логин и пароль для входа в AdGuardHome"
echo -e "${GREEN}Логин: $username${NC}"
echo -e "${GREEN}Пароль: $password${NC}"

# Запрашиваем у пользователя, хочет ли он поменять пароль для SSH
printf "Вы хотите поменять порт для SSH? (y/n): "
read ssh_answer

# Если пользователь отвечает "y" или "Y", запускаем скрипт для изменения порта
if [[ "$ssh_answer" == "y" || "$ssh_answer" == "Y" ]]; then
  # Запуск скрипта ssh.sh
  printf "\e[42mЗапуск скрипта ssh.sh для смены стандартного порта SSH...\e[0m\n"
  ./tools/ssh.sh
  printf "\e[42mСкрипт ssh.sh успешно выполнен.\e[0m\n"
fi

# Запрашиваем у пользователя, хочет ли установить UFW Firewall
printf "Вы хотите установить UFW Firewall? (y/n): "
read ufw_answer

# Если пользователь отвечает "y" или "Y", запускаем скрипт для изменения пароля
if [[ "$ufw_answer" == "y" || "$ufw_answer" == "Y" ]]; then
  # Запуск скрипта ufw.sh
  printf "\e[42mЗапуск скрипта ufw.sh для установки UFW Firewall...\e[0m\n"
  ./tools/ufw.sh
  printf "\e[42mСкрипт ufw.sh успешно выполнен.\e[0m\n"
fi
printf '\e[48;5;202m\e[30m Если вам понравился мой скрипт, вы можете меня отблагодарить суммой на ваше усмотрение: https://yoomoney.ru/to/41001707910216 \e[0m\n'
# Переходим в папку /
printf "\e[42mПереходим в папку /root/...\e[0m\n"
cd
printf "\e[42mПерешли в папку /root/ \e[0m\n"
