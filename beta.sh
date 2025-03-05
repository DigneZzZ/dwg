#!/bin/bash

# Рабочая директория
WORK_DIR="/root/dwg"

# Цветовые коды
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
RED='\033[0;31m'
NC='\033[0m'

# Проверка запуска от root
if [ "$EUID" -ne 0 ]; then
    echo -e "${RED}Запустите скрипт с правами root${NC}"
    exit 1
fi

# Установка зависимостей
install_deps() {
    echo -e "${GREEN}Установка зависимостей...${NC}"
    apt update -y
    apt install -y docker.io docker-compose qrencode apache2-utils
}

# Функция для генерации bcrypt-хэша
generate_hash() {
    local password=$1
    htpasswd -nbB admin "$password" | cut -d ":" -f 2 | sed 's/\$/\$\$/g'
}

# Функция для определения версии DWG
get_dwg_version() {
    if [ ! -f "$WORK_DIR/docker-compose.yml" ]; then
        echo "unknown"
        return
    fi
    if grep -q "wg-easy" "$WORK_DIR/docker-compose.yml"; then
        echo "ui"
    elif grep -q "adwireguard" "$WORK_DIR/docker-compose.yml"; then
        echo "dark"
    elif grep -q "wireguard" "$WORK_DIR/docker-compose.yml"; then
        echo "cli"
    else
        echo "unknown"
    fi
}

# Функция установки
install_dwg() {
    # Проверка на Debian 10
    if grep -q "VERSION_ID=\"10\"" /etc/os-release; then
        echo -e "${RED}Этот скрипт не поддерживает Debian 10${NC}"
        exit 1
    fi

    install_deps
    mkdir -p "$WORK_DIR" && cd "$WORK_DIR" || exit 1
    MYHOST_IP=$(curl -s https://checkip.amazonaws.com/)

    echo "Выберите тип установки:"
    echo "1. DWG-CLI (WireGuard CLI)"
    echo "2. DWG-UI (WireGuard с веб-интерфейсом)"
    echo "3. DWG-DARK (WG + AdGuardHome в одном контейнере)"
    read -p "Введите номер (1-3): " setup_choice

    case $setup_choice in
        1) # DWG-CLI
            compose_file=$(cat <<EOF
version: "3"
services:
  wireguard:
    image: lscr.io/linuxserver/wireguard:latest
    container_name: wireguard
    depends_on: [adguardhome]
    cap_add:
      - NET_ADMIN
    environment:
      - TZ=Europe/Moscow
      - SERVERURL=$MYHOST_IP
      - SERVERPORT=51820
      - PEERS=1
      - PEERDNS=10.2.0.100
      - INTERNAL_SUBNET=10.10.10.0
      - DNS=10.2.0.100
      - POSTUP='iptables -A FORWARD -i %i -j ACCEPT; iptables -A FORWARD -o %i -j ACCEPT; iptables -t nat -A POSTROUTING -o eth0 -j MASQUERADE'
      - POSTDOWN='iptables -D FORWARD -i %i -j ACCEPT; iptables -D FORWARD -o %i -j ACCEPT; iptables -t nat -D POSTROUTING -o eth0 -j MASQUERADE'
      - ALLOWEDIPS=0.0.0.0/0,::/0
    volumes:
      - ./wireguard:/config
      - /lib/modules:/lib/modules
    ports:
      - "51820:51820/udp"
    sysctls:
      - net.ipv4.conf.all.src_valid_mark=1
    restart: unless-stopped
    networks:
      private_network:
        ipv4_address: 10.2.0.3

  adguardhome:
    image: adguard/adguardhome:latest
    container_name: adguardhome
    restart: unless-stopped
    environment:
      - TZ=Europe/Moscow
    volumes:
      - ./work:/opt/adguardhome/work
      - ./conf:/opt/adguardhome/conf
    networks:
      private_network:
        ipv4_address: 10.2.0.100

networks:
  private_network:
    ipam:
      driver: default
      config:
        - subnet: 10.2.0.0/24
EOF
            )
            ;;
        2) # DWG-UI
            # Обязательные параметры
            read -p "Введите пароль для wg-easy (по умолчанию: foobar123): " wg_password
            wg_password=${wg_password:-foobar123}
            if [[ ! "$wg_password" =~ ^[[:alnum:]]+$ ]]; then
                echo -e "${RED}Пароль должен содержать только буквы и цифры${NC}"
                exit 1
            fi
            wg_hash=$(generate_hash "$wg_password")
            echo -e "${YELLOW}Ваш внешний IP-адрес: $MYHOST_IP${NC}"
            read -p "Использовать внешний IP ($MYHOST_IP) или указать свой домен для wg-easy? (ip/domain, по умолчанию: ip): " host_choice
            host_choice=${host_choice:-ip}
            if [ "$host_choice" == "domain" ]; then
                read -p "Введите ваш домен (например, my.domain.com): " wg_host
                if [ -z "$wg_host" ]; then
                    echo -e "${RED}Домен не указан, используется внешний IP${NC}"
                    wg_host=$MYHOST_IP
                fi
            else
                wg_host=$MYHOST_IP
            fi

            # Опциональные параметры
            echo -e "${YELLOW}Настройка опциональных параметров:${NC}"
            read -p "Выберите язык интерфейса (en, ru, fr и т.д., по умолчанию: en): " lang
            lang=${lang:-en}
            read -p "Порт веб-интерфейса (по умолчанию: 51821): " port
            port=${port:-51821}
            read -p "Порт WireGuard (по умолчанию: 51820): " wg_port
            wg_port=${wg_port:-51820}
            read -p "Порт конфигурации WireGuard (по умолчанию: 92820): " wg_config_port
            wg_config_port=${wg_config_port:-92820}
            read -p "Шаблон IP-адресов клиентов (по умолчанию: 10.8.0.x): " wg_default_address
            wg_default_address=${wg_default_address:-10.8.0.x}
            read -p "DNS-сервер по умолчанию (по умолчанию: 1.1.1.1): " wg_default_dns
            wg_default_dns=${wg_default_dns:-1.1.1.1}
            read -p "MTU WireGuard (по умолчанию: 1420): " wg_mtu
            wg_mtu=${wg_mtu:-1420}
            read -p "Разрешенные IP (по умолчанию: 0.0.0.0/0, ::/0): " wg_allowed_ips
            wg_allowed_ips=${wg_allowed_ips:-"0.0.0.0/0, ::/0"}
            read -p "Persistent Keepalive (по умолчанию: 25): " wg_persistent_keepalive
            wg_persistent_keepalive=${wg_persistent_keepalive:-25}
            read -p "Pre-Up команда (по умолчанию: пусто): " wg_pre_up
            read -p "Post-Up команда (по умолчанию: пусто): " wg_post_up
            read -p "Pre-Down команда (по умолчанию: пусто): " wg_pre_down
            read -p "Post-Down команда (по умолчанию: пусто): " wg_post_down
            read -p "Включить статистику трафика в UI? (true/false, по умолчанию: false): " ui_traffic_stats
            ui_traffic_stats=${ui_traffic_stats:-false}
            read -p "Тип графиков в UI (0 - выкл, 1 - линия, 2 - область, 3 - столбцы, по умолчанию: 0): " ui_chart_type
            ui_chart_type=${ui_chart_type:-0}
            read -p "Включить одноразовые ссылки? (true/false, по умолчанию: false): " wg_enable_one_time_links
            wg_enable_one_time_links=${wg_enable_one_time_links:-false}
            read -p "Включить сортировку клиентов в UI? (true/false, по умолчанию: false): " ui_enable_sort_clients
            ui_enable_sort_clients=${ui_enable_sort_clients:-false}
            read -p "Включить время истечения для клиентов? (true/false, по умолчанию: false): " wg_enable_expires_time
            wg_enable_expires_time=${wg_enable_expires_time:-false}
            read -p "Включить Prometheus метрики? (true/false, по умолчанию: false): " enable_prometheus_metrics
            enable_prometheus_metrics=${enable_prometheus_metrics:-false}
            if [ "$enable_prometheus_metrics" == "true" ]; then
                read -p "Введите пароль для Prometheus (по умолчанию: prometheus_password): " prometheus_password
                prometheus_password=${prometheus_password:-prometheus_password}
                prometheus_hash=$(generate_hash "$prometheus_password")
            fi

            compose_file=$(cat <<EOF
version: "3.8"
volumes:
  etc_wireguard:

services:
  wg-easy:
    image: ghcr.io/wg-easy/wg-easy
    container_name: wg-easy
    volumes:
      - etc_wireguard:/etc/wireguard
    ports:
      - "$wg_port:$wg_port/udp"
      - "$port:$port/tcp"
    restart: unless-stopped
    cap_add:
      - NET_ADMIN
      - SYS_MODULE
    sysctls:
      - net.ipv4.ip_forward=1
      - net.ipv4.conf.all.src_valid_mark=1
    environment:
      - LANG=$lang
      - WG_HOST=$wg_host
      - PASSWORD_HASH=$wg_hash
      - PORT=$port
      - WG_PORT=$wg_port
      - WG_CONFIG_PORT=$wg_config_port
      - WG_DEFAULT_ADDRESS=$wg_default_address
      - WG_DEFAULT_DNS=$wg_default_dns
      - WG_MTU=$wg_mtu
      - WG_ALLOWED_IPS=$wg_allowed_ips
      - WG_PERSISTENT_KEEPALIVE=$wg_persistent_keepalive
EOF
            )
            [ -n "$wg_pre_up" ] && compose_file+=$(echo -e "\n      - WG_PRE_UP=$wg_pre_up")
            [ -n "$wg_post_up" ] && compose_file+=$(echo -e "\n      - WG_POST_UP=$wg_post_up")
            [ -n "$wg_pre_down" ] && compose_file+=$(echo -e "\n      - WG_PRE_DOWN=$wg_pre_down")
            [ -n "$wg_post_down" ] && compose_file+=$(echo -e "\n      - WG_POST_DOWN=$wg_post_down")
            compose_file+=$(echo -e "\n      - UI_TRAFFIC_STATS=$ui_traffic_stats")
            compose_file+=$(echo -e "\n      - UI_CHART_TYPE=$ui_chart_type")
            compose_file+=$(echo -e "\n      - WG_ENABLE_ONE_TIME_LINKS=$wg_enable_one_time_links")
            compose_file+=$(echo -e "\n      - UI_ENABLE_SORT_CLIENTS=$ui_enable_sort_clients")
            compose_file+=$(echo -e "\n      - WG_ENABLE_EXPIRES_TIME=$wg_enable_expires_time")
            compose_file+=$(echo -e "\n      - ENABLE_PROMETHEUS_METRICS=$enable_prometheus_metrics")
            [ "$enable_prometheus_metrics" == "true" ] && compose_file+=$(echo -e "\n      - PROMETHEUS_METRICS_PASSWORD=$prometheus_hash")
            ;;
        3) # DWG-DARK
            compose_file=$(cat <<EOF
version: "3.8"
services:
  adwireguard:
    container_name: dwg-agh-wg
    image: iganesh/adwireguard-dark:v0.108.0-b.50
    restart: unless-stopped
    ports:
      - "51820:51820/udp"
      - "51821:51821/tcp"
    environment:
      - WG_HOST=$MYHOST_IP
      - PASSWORD_HASH=$(generate_hash "openode")
      - WG_PORT=51820
      - WG_DEFAULT_ADDRESS=10.10.10.x
      - WG_DEFAULT_DNS=10.2.0.100
      - WG_MTU=1280
    volumes:
      - ./work:/opt/adwireguard/work
      - ./conf:/opt/adwireguard/conf
      - ./wireguard:/etc/wireguard
    cap_add:
      - NET_ADMIN
      - SYS_MODULE
    sysctls:
      - net.ipv4.ip_forward=1
      - net.ipv4.conf.all.src_valid_mark=1
      - net.ipv6.conf.all.disable_ipv6=1
    networks:
      vpn_net:
        ipv4_address: 10.2.0.100

networks:
  vpn_net:
    ipam:
      driver: default
      config:
        - subnet: 10.2.0.0/24
EOF
            )
            mkdir -p conf
            cat <<EOF > conf/AdGuardHome.yaml
users:
  - name: admin
    password: $(htpasswd -nbB admin "admin" | cut -d ":" -f 2)
dns:
  bind_hosts:
    - 0.0.0.0
EOF
            ;;
        *)
            echo -e "${RED}Некорректный выбор${NC}"
            exit 1
            ;;
    esac

    echo "$compose_file" > "$WORK_DIR/docker-compose.yml"
    docker-compose up -d
    echo -e "${GREEN}Установка завершена${NC}"
    show_info
}

# Функция вывода информации после установки
show_info() {
    VERSION=$(get_dwg_version)
    case $VERSION in
        cli)
            echo -e "${BLUE}Для управления WireGuard: 'dwg peers' или 'docker exec -it wireguard wg'${NC}"
            echo -e "${BLUE}AdGuardHome доступен через VPN: http://10.2.0.100${NC}"
            ;;
        ui)
            echo -e "${BLUE}Веб-интерфейс WireGuard: http://$wg_host:$port${NC}"
            echo -e "${GREEN}Пароль: $wg_password${NC}"
            ;;
        dark)
            echo -e "${BLUE}Веб-интерфейс WireGuard: http://$MYHOST_IP:51821${NC}"
            echo -e "${GREEN}Пароль wg-easy: openode${NC}"
            echo -e "${BLUE}AdGuardHome через VPN: http://10.2.0.100${NC}"
            echo -e "${GREEN}Логин: admin${NC}"
            echo -e "${GREEN}Пароль: admin${NC}"
            ;;
    esac
}

# Функция управления пирами (CLI версия)
manage_peers() {
    wg_conf_path="$WORK_DIR/wireguard/wg_confs/wg0.conf"
    if [ ! -f "$wg_conf_path" ]; then
        echo -e "${RED}Файл конфигурации $wg_conf_path не найден${NC}"
        exit 1
    fi

    peers=$(grep -oP '(?<=#).*$' "$wg_conf_path" | nl)
    echo -e "${YELLOW}Список пиров в файле конфигурации $wg_conf_path:${NC}"
    echo "$peers"

    echo -en "${YELLOW}Введите номер пира: ${NC}"
    read peer_number

    peer=$(echo "$peers" | awk -v n="$peer_number" '$1 == n {print $2}')
    if [ -z "$peer" ]; then
        echo -e "${RED}Пир с номером $peer_number не найден${NC}"
        exit 1
    fi

    peer_conf_path="$WORK_DIR/wireguard/$peer/$peer.conf"
    if [ -f "$peer_conf_path" ]; then
        echo -e "${BLUE}Содержимое файла конфигурации $peer_conf_path:${NC}"
        echo -e "${GREEN}Создайте файл peer.conf с этим содержимым и импортируйте в WireGuard${NC}"
        echo -e "${YELLOW}=========================================${NC}"
        cat "$peer_conf_path"
        echo -e "${YELLOW}=========================================${NC}"
        echo -e "${BLUE}QR-код для подключения:${NC}"
        qrencode -t ansiutf8 < "$peer_conf_path"
    else
        echo -e "${RED}Файл конфигурации $peer_conf_path не найден${NC}"
    fi
    echo -e "${YELLOW}https://openode.ru${NC}"
}

# Основная логика обработки команд
case "$1" in
    status)
        if [ -f "$WORK_DIR/docker-compose.yml" ]; then
            echo -e "${GREEN}Статус контейнеров:${NC}"
            docker-compose -f "$WORK_DIR/docker-compose.yml" ps
        else
            echo -e "${RED}Контейнеры не установлены${NC}"
        fi
        ;;
    install)
        if [ -f "$WORK_DIR/docker-compose.yml" ]; then
            echo -e "${YELLOW}Контейнеры уже установлены. Удалите их сначала с помощью 'dwg uninstall'${NC}"
            exit 1
        fi
        install_dwg
        ;;
    uninstall)
        if [ -f "$WORK_DIR/docker-compose.yml" ]; then
            echo -e "${GREEN}Удаление контейнеров и томов...${NC}"
            docker-compose -f "$WORK_DIR/docker-compose.yml" down -v
            rm -rf "$WORK_DIR"/*
            echo -e "${GREEN}Удаление завершено${NC}"
        else
            echo -e "${RED}Нечего удалять${NC}"
        fi
        ;;
    restart)
        if [ -f "$WORK_DIR/docker-compose.yml" ]; then
            echo -e "${GREEN}Перезапуск контейнеров...${NC}"
            docker-compose -f "$WORK_DIR/docker-compose.yml" restart
            echo -e "${GREEN}Перезапуск завершен${NC}"
        else
            echo -e "${RED}Контейнеры не установлены${NC}"
        fi
        ;;
    change-password)
        VERSION=$(get_dwg_version)
        if [ "$VERSION" == "unknown" ]; then
            echo -e "${RED}Не удалось определить версию DWG${NC}"
            exit 1
        fi
        if [ "$VERSION" == "ui" ] || [ "$VERSION" == "dark" ]; then
            echo -en "${YELLOW}Введите новый пароль для wg-easy: ${NC}"
            read -s new_password
            echo
            hash=$(generate_hash "$new_password")
            sed -i "s/PASSWORD_HASH=.*/PASSWORD_HASH=$hash/" "$WORK_DIR/docker-compose.yml"
            docker-compose -f "$WORK_DIR/docker-compose.yml" restart
            echo -e "${GREEN}Пароль для wg-easy обновлен${NC}"
        fi
        if [ "$VERSION" == "dark" ]; then
            echo -en "${YELLOW}Введите новый логин для AdGuardHome (Enter для сохранения текущего): ${NC}"
            read new_adguard_user
            echo -en "${YELLOW}Введите новый пароль для AdGuardHome: ${NC}"
            read -s new_adguard_password
            echo
            if [ -n "$new_adguard_user" ]; then
                sed -i "s/name: .*/name: $new_adguard_user/" "$WORK_DIR/conf/AdGuardHome.yaml"
            fi
            if [ -n "$new_adguard_password" ]; then
                adguard_hash=$(htpasswd -nbB "${new_adguard_user:-admin}" "$new_adguard_password" | cut -d ":" -f 2)
                sed -i "s/password: .*/password: $adguard_hash/" "$WORK_DIR/conf/AdGuardHome.yaml"
            fi
            docker-compose -f "$WORK_DIR/docker-compose.yml" restart adwireguard
            echo -e "${GREEN}Пароль для AdGuardHome обновлен${NC}"
        fi
        if [ "$VERSION" == "cli" ]; then
            echo -e "${YELLOW}Для CLI версии смена пароля не требуется${NC}"
        fi
        ;;
    peers)
        VERSION=$(get_dwg_version)
        if [ "$VERSION" == "cli" ]; then
            manage_peers
        else
            echo -e "${RED}Команда peers доступна только для CLI версии${NC}"
        fi
        ;;
    *)
        echo "Использование: dwg {status|install|uninstall|restart|change-password|peers}"
        echo "Текущая версия DWG: $(get_dwg_version)"
        ;;
esac
