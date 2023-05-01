#!/bin/bash

# Поиск контейнера wg-easy в файле docker-compose.yml
if grep -q "wg-easy:" docker-compose.yml; then
    echo "WG-EASY установлен!"

    # Получение текущих значений параметров
    WG_HOST=$(grep WG_HOST docker-compose.yml | cut -d '=' -f2)
    PASSWORD=$(grep PASSWORD docker-compose.yml | cut -d '=' -f2)
    WG_PORT=$(grep WG_PORT docker-compose.yml | cut -d '=' -f2)
    WG_DEFAULT_ADDRESS=$(grep WG_DEFAULT_ADDRESS docker-compose.yml | cut -d '=' -f2)
    WG_DEFAULT_DNS=$(grep WG_DEFAULT_DNS docker-compose.yml | cut -d '=' -f2)
    WG_ALLOWED_IPS=$(grep WG_ALLOWED_IPS docker-compose.yml | cut -d '=' -f2)
    WG_MTU=$(grep WG_MTU docker-compose.yml | cut -d '=' -f2)

    # Предложение пользователю отредактировать параметры
    read -p "Хотите отредактировать параметры? (Y/N): " choice
    if [[ "$choice" =~ ^[Yy]$ ]]; then
        echo "Отредактируйте параметры (оставьте пустым для сохранения старого значения):"

        read -p "WG_HOST ($WG_HOST): " new_wg_host
        if [ ! -z "$new_wg_host" ]; then
            sed -i "s/WG_HOST=$WG_HOST/#WG_HOST=$WG_HOST/g" docker-compose.yml
            echo "WG_HOST=$new_wg_host" >> docker-compose.yml
        fi

        read -p "PASSWORD ($PASSWORD): " new_password
        if [ ! -z "$new_password" ]; then
            sed -i "s/PASSWORD=$PASSWORD/#PASSWORD=$PASSWORD/g" docker-compose.yml
            echo "PASSWORD=$new_password" >> docker-compose.yml
        fi

        read -p "WG_PORT ($WG_PORT): " new_wg_port
        if [ ! -z "$new_wg_port" ]; then
            sed -i "s/WG_PORT=$WG_PORT/#WG_PORT=$WG_PORT/g" docker-compose.yml
            echo "WG_PORT=$new_wg_port" >> docker-compose.yml
        fi

        read -p "WG_DEFAULT_ADDRESS ($WG_DEFAULT_ADDRESS): " new_wg_default_address
        if [ ! -z "$new_wg_default_address" ]; then
            sed -i "s/WG_DEFAULT_ADDRESS=$WG_DEFAULT_ADDRESS/#WG_DEFAULT_ADDRESS=$WG_DEFAULT_ADDRESS/g" docker-compose.yml
            echo "WG_DEFAULT_ADDRESS=$new_wg_default_address" >> docker-compose.yml
        fi

        read -p "WG_DEFAULT_DNS ($WG_DEFAULT_DNS): " new_wg_default_dns
        if [ ! -z "$new_wg_default_dns" ]; then
            sed -i "s/WG_DEFAULT_DNS=$WG_DEFAULT_DNS/#WG_DEFAULT_DNS=$WG_DEFAULT_DNS/g" docker-compose.yml
            echo "WG_DEFAULT_DNS=$new_wg_default_dns" >> docker-compose.yml
        fi

        read -p "WG_ALLOWED_IPS ($WG_ALLOWED_IPS): " new_wg_allowed_ips
        if [ ! -z "$new_wg_allowed_ips" ]; then
            sed -i "s/WG_ALLOWED_IPS=$WG_ALLOWED_IPS/#WG_ALLOWED_IPS=$WG_ALLOWED_IPS/g" docker-compose.yml
            echo "WG_ALLOWED_IPS=$new_wg_allowed_ips" >> docker-compose.yml
        fi

        read -p "WG_MTU ($WG_MTU): " new_wg_mtu
        if [ ! -z "$new_wg_mtu" ]; then
            sed -i "s/WG_MTU=$WG_MTU/#WG_MTU=$WG_MTU/g" docker-compose.yml
            echo "WG_MTU=$new_wg_mtu" >> docker-compose.yml
        fi

        echo "Изменения сохранены."
    else
        echo "Изменения не внесены."
    fi
else
    echo "WG-EASY не установлен."
fi

# Запрашиваем у пользователя, хочет ли изменить пароль для AdGuardHome?
printf "Вы хотите изменить пароль для AGH? (y/n): "
read agh_answer
# Если пользователь отвечает "y" или "Y", запускаем скрипт для изменения пароля
if [[ "$agh_answer" == "y" || "$agh_answer" == "Y" ]]; then
  # Запуск скрипта ufw.sh
  printf "\e[42mЗапуск скрипта agh.sh для изменения параметров AGH...\e[0m\n"
  ./tools/agh.sh
  printf "\e[42mСкрипт agh.sh успешно выполнен.\e[0m\n"
fi

# Предложим пользователю пересоздать контейнеры
printf "Хотите пересоздать контейнеры? (y/n) "

# Считываем ответ пользователя
read answer

# Если пользователь ответил "y", запустим команду пересоздания контейнеров
if [ "$answer" == "y" ]; then
  docker-compose up -d --force-recreate
  printf "Контейнеры были успешно пересозданы!\n"
else
  printf "Пересоздание контейнеров отменено.\n"
fi
