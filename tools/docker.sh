#!/bin/bash

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

# Проверяем, установлен ли Docker
if [ -x "$(command -v docker)" ]; then
  echo -e "${GREEN}Docker уже установлен${NC}"
else
  # Проверяем, какое распределение используется, и устанавливаем необходимые зависимости
  if [ -f /etc/debian_version ]; then
    apt-get update
    apt-get install -y apt-transport-https ca-certificates curl gnupg lsb-release
  elif [ -f /etc/redhat-release ]; then
    dnf install -y dnf-plugins-core
    dnf config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo
    dnf install -y curl
  else
    echo -e "${RED}Неподдерживаемое распределение${NC}"
    exit
  fi

  # Устанавливаем Docker
  curl -fsSL https://get.docker.com -o get-docker.sh
  sh get-docker.sh

  # Запускаем и включаем службу Docker
  systemctl start docker
  systemctl enable docker

  echo -e "${GREEN}Docker успешно установлен${NC}"
fi


# Проверка наличия docker-compose
if command -v docker-compose &> /dev/null
then
    printf "${GREEN}Docker Compose уже установлен\n${NC}"
else
    # Установка docker-compose
    curl -L --fail https://raw.githubusercontent.com/linuxserver/docker-docker-compose/master/run.sh -o /usr/local/bin/docker-compose &&
    chmod +x /usr/local/bin/docker-compose
fi
