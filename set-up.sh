#!/bin/bash

# URL для загрузки скрипта
SCRIPT_URL="https://raw.githubusercontent.com/DigneZzZ/dwg/refs/heads/main/set-up.sh"

# Рабочая директория для контейнеров
WORK_DIR="/opt/dwg"
# Папка для конфигурации AdGuardHome
CONF_DIR="$WORK_DIR/conf"

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

# Функция проверки доступности порта
check_port() {
    local port=$1
    local proto=$2  # "tcp" или "udp"
    if ss -tuln | grep -q ":$port "; then
        echo -e "${RED}Порт $port ($proto) уже занят${NC}"
        exit 1
    fi
    echo -e "${GREEN}Порт $port ($proto) свободен${NC}"
}

# Установка зависимостей
install_deps() {
    echo -e "${GREEN}Проверка и установка зависимостей...${NC}"
    apt update -y

    if ! command -v docker &> /dev/null; then
        echo "Docker не установлен, устанавливаем..."
        apt install -y docker.io
    else
        echo "Docker уже установлен"
    fi

    if ! docker compose version &> /dev/null; then
        echo "Docker Compose не установлен, устанавливаем..."
        apt install -y docker-compose
    else
        echo "Docker Compose уже установлен"
    fi

    if ! command -v qrencode &> /dev/null; then
        echo "qrencode не установлен, устанавливаем..."
        apt install -y qrencode
    else
        echo "qrencode уже установлен"
    fi

    if ! command -v htpasswd &> /dev/null; then
        echo "htpasswd не установлен, устанавливаем apache2-utils..."
        apt install -y apache2-utils
    else
        echo "htpasswd уже установлен"
    fi

    if ! command -v ss &> /dev/null; then
        echo "net-tools не установлен, устанавливаем..."
        apt install -y net-tools
    else
        echo "net-tools уже установлен"
    fi

    if ! command -v docker &> /dev/null || ! docker compose version &> /dev/null; then
        echo -e "${RED}Ошибка: Docker или Docker Compose не установлены${NC}"
        exit 1
    fi
    if ! command -v htpasswd &> /dev/null; then
        echo -e "${RED}Ошибка: htpasswd не установлен${NC}"
        exit 1
    fi
    if ! command -v ss &> /dev/null; then
        echo -e "${RED}Ошибка: ss (net-tools) не установлен${NC}"
        exit 1
    fi
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

# Функция установки скрипта как сервиса
script_install() {
    echo -e "${GREEN}Установка скрипта как сервиса в /usr/local/bin/dwg...${NC}"
    wget -qO /usr/local/bin/dwg "$SCRIPT_URL"
    chmod +x /usr/local/bin/dwg
    if [ -s /usr/local/bin/dwg ]; then
        echo -e "${GREEN}Скрипт успешно установлен${NC}"
    else
        echo -e "${RED}Ошибка при установке скрипта: файл пустой или не скачан${NC}"
        exit 1
    fi
}

# Функция установки DWG
install_dwg() {
    if grep -q "VERSION_ID=\"10\"" /etc/os-release; then
        echo -e "${RED}Этот скрипт не поддерживает Debian 10${NC}"
        exit 1
    fi

    script_install
    install_deps
    mkdir -p "$WORK_DIR" && cd "$WORK_DIR" || exit 1
    mkdir -p "$CONF_DIR" || exit 1
    MYHOST_IP=$(curl -s https://checkip.amazonaws.com/)

    echo "Выберите тип установки:"
    echo "1. DWG-CLI (WireGuard CLI)"
    echo "2. DWG-UI (WireGuard с веб-интерфейсом + AdGuardHome)"
    echo "3. DWG-DARK (WG + AdGuardHome в одном контейнере)"
    read -p "Введите номер (1-3): " setup_choice

    case $setup_choice in
        1) # DWG-CLI
            check_port 51820 "udp"
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
      - $CONF_DIR:/opt/adguardhome/conf
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
            read -p "Введите логин для AdGuardHome (по умолчанию: admin): " adguard_user
            adguard_user=${adguard_user:-admin}
            read -p "Введите пароль для AdGuardHome (по умолчанию: admin): " adguard_password
            adguard_password=${adguard_password:-admin}
            adguard_hash=$(htpasswd -nbB "$adguard_user" "$adguard_password" | cut -d ":" -f 2)
            ;;
        2) # DWG-UI с AdGuardHome
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

            echo -e "${YELLOW}Настройка опциональных параметров:${NC}"
            read -p "Выберите язык интерфейса (en, ru, fr и т.д., по умолчанию: en): " lang
            lang=${lang:-en}
            read -p "Порт веб-интерфейса (по умолчанию: 51821): " port
            port=${port:-51821}
            check_port "$port" "tcp"
            read -p "Порт WireGuard (по умолчанию: 51820): " wg_port
            wg_port=${wg_port:-51820}
            check_port "$wg_port" "udp"
            read -p "Порт конфигурации WireGuard (по умолчанию: 92820): " wg_config_port
            wg_config_port=${wg_config_port:-92820}
            check_port "$wg_config_port" "tcp"
            read -p "Шаблон IP-адресов клиентов (по умолчанию: 10.8.0.x): " wg_default_address
            wg_default_address=${wg_default_address:-10.8.0.x}
            read -p "DNS-сервер по умолчанию (по умолчанию: 10.2.0.100 для AdGuardHome): " wg_default_dns
            wg_default_dns=${wg_default_dns:-10.2.0.100}
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

            read -p "Введите логин для AdGuardHome (по умолчанию: admin): " adguard_user
            adguard_user=${adguard_user:-admin}
            read -p "Введите пароль для AdGuardHome (по умолчанию: admin): " adguard_password
            adguard_password=${adguard_password:-admin}
            adguard_hash=$(htpasswd -nbB "$adguard_user" "$adguard_password" | cut -d ":" -f 2)

            compose_file=$(cat <<EOF
version: "3.8"
volumes:
  etc_wireguard:

services:
  wg-easy:
    image: ghcr.io/wg-easy/wg-easy
    container_name: wg-easy
    depends_on: [adguardhome]
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
    dns:
      - 10.2.0.100
    networks:
      private_network:
        ipv4_address: 10.2.0.3
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
            compose_file+=$(cat <<EOF

  adguardhome:
    image: adguard/adguardhome:latest
    container_name: adguardhome
    restart: unless-stopped
    environment:
      - TZ=Europe/Moscow
    volumes:
      - ./work:/opt/adguardhome/work
      - $CONF_DIR:/opt/adguardhome/conf
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
        3) # DWG-DARK
            check_port 51820 "udp"
            check_port 51821 "tcp"
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
      - $CONF_DIR:/opt/adguardhome/conf
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
            read -p "Введите логин для AdGuardHome (по умолчанию: admin): " adguard_user
            adguard_user=${adguard_user:-admin}
            read -p "Введите пароль для AdGuardHome (по умолчанию: admin): " adguard_password
            adguard_password=${adguard_password:-admin}
            adguard_hash=$(htpasswd -nbB "$adguard_user" "$adguard_password" | cut -d ":" -f 2)
            ;;
        *)
            echo -e "${RED}Некорректный выбор${NC}"
            exit 1
            ;;
    esac

    cat <<EOF > "$CONF_DIR/AdGuardHome.yaml"
http:
  pprof:
    port: 6060
    enabled: false
  address: 0.0.0.0:80
  session_ttl: 720h
users:
  - name: $adguard_user
    password: $adguard_hash
auth_attempts: 5
block_auth_min: 15
http_proxy: ""
language: ""
theme: auto
dns:
  bind_hosts:
    - 0.0.0.0
  port: 53
  anonymize_client_ip: false
  ratelimit: 20
  ratelimit_subnet_len_ipv4: 24
  ratelimit_subnet_len_ipv6: 56
  ratelimit_whitelist: []
  refuse_any: true
  upstream_dns:
    - https://cloudflare-dns.com/dns-query
    - https://dns.adguard-dns.com/dns-query
    - https://dns.quad9.net/dns-query
  upstream_dns_file: ""
  bootstrap_dns:
    - 9.9.9.10
    - 149.112.112.10
    - 2620:fe::10
    - 2620:fe::fe:10
  fallback_dns:
    - https://dns.quad9.net/dns-query
    - quic://unfiltered.adguard-dns.com
  upstream_mode: parallel
  fastest_timeout: 1s
  allowed_clients: []
  disallowed_clients: []
  blocked_hosts:
    - version.bind
    - id.server
    - hostname.bind
  trusted_proxies:
    - 127.0.0.0/8
    - ::1/128
  cache_size: 4194304
  cache_ttl_min: 0
  cache_ttl_max: 0
  cache_optimistic: false
  bogus_nxdomain: []
  aaaa_disabled: false
  enable_dnssec: false
  edns_client_subnet:
    custom_ip: ""
    enabled: false
    use_custom: false
  max_goroutines: 300
  handle_ddr: true
  ipset: []
  ipset_file: ""
  bootstrap_prefer_ipv6: false
  upstream_timeout: 10s
  private_networks: []
  use_private_ptr_resolvers: false
  local_ptr_upstreams: []
  use_dns64: false
  dns64_prefixes: []
  serve_http3: false
  use_http3_upstreams: false
  serve_plain_dns: true
  hostsfile_enabled: true
tls:
  enabled: false
  server_name: ""
  force_https: false
  port_https: 443
  port_dns_over_tls: 853
  port_dns_over_quic: 853
  port_dnscrypt: 0
  dnscrypt_config_file: ""
  allow_unencrypted_doh: false
  certificate_chain: ""
  private_key: ""
  certificate_path: ""
  private_key_path: ""
  strict_sni_check: false
querylog:
  dir_path: ""
  ignored: []
  interval: 24h
  size_memory: 1000
  enabled: true
  file_enabled: true
statistics:
  dir_path: ""
  ignored: []
  interval: 24h
  enabled: true
filters:
  - enabled: true
    url: https://adguardteam.github.io/AdGuardSDNSFilter/Filters/filter.txt
    name: AdGuard DNS filter
    id: 1
  - enabled: true
    url: https://adaway.org/hosts.txt
    name: AdAway Default Blocklist
    id: 2
  - enabled: true
    url: https://easylist-downloads.adblockplus.org/advblock.txt
    name: RuAdlist
    id: 1670584470
  - enabled: false
    url: https://easylist-downloads.adblockplus.org/bitblock.txt
    name: BitBlock
    id: 1670584471
  - enabled: true
    url: https://easylist-downloads.adblockplus.org/cntblock.txt
    name: cntblock
    id: 1670584472
  - enabled: true
    url: https://easylist-downloads.adblockplus.org/easylist.txt
    name: easyList
    id: 1670584473
  - enabled: false
    url: https://schakal.ru/hosts/alive_hosts_ru_com.txt
    name: то же без неотвечающих хостов и доменов вне зон RU, NET и COM
    id: 1677533164
  - enabled: true
    url: https://schakal.ru/hosts/hosts_mail_fb.txt
    name: файл с разблокированными r.mail.ru и graph.facebook.com
    id: 1677533165
  - enabled: true
    url: https://adguardteam.github.io/HostlistsRegistry/assets/filter_1.txt
    name: AdGuard DNS filter
    id: 1726948599
  - enabled: true
    url: https://adguardteam.github.io/HostlistsRegistry/assets/filter_59.txt
    name: AdGuard DNS Popup Hosts filter
    id: 1726948600
  - enabled: true
    url: https://adguardteam.github.io/HostlistsRegistry/assets/filter_27.txt
    name: OISD Blocklist Big
    id: 1726948601
  - enabled: true
    url: https://adguardteam.github.io/HostlistsRegistry/assets/filter_24.txt
    name: 1Hosts (Lite)
    id: 1726948602
  - enabled: true
    url: https://adguardteam.github.io/HostlistsRegistry/assets/filter_10.txt
    name: Scam Blocklist by DurableNapkin
    id: 1726948603
  - enabled: true
    url: https://adguardteam.github.io/HostlistsRegistry/assets/filter_11.txt
    name: Malicious URL Blocklist (URLHaus)
    id: 1726948604
  - enabled: true
    url: https://adguardteam.github.io/HostlistsRegistry/assets/filter_50.txt
    name: uBlock₀ filters – Badware risks
    id: 1726948605
whitelist_filters: []
user_rules: []
dhcp:
  enabled: false
  interface_name: ""
  local_domain_name: lan
  dhcpv4:
    gateway_ip: ""
    subnet_mask: ""
    range_start: ""
    range_end: ""
    lease_duration: 86400
    icmp_timeout_msec: 1000
    options: []
  dhcpv6:
    range_start: ""
    lease_duration: 86400
    ra_slaac_only: false
    ra_allow_slaac: false
filtering:
  blocking_ipv4: ""
  blocking_ipv6: ""
  blocked_services:
    schedule:
      time_zone: America/Los_Angeles
    ids: []
  protection_disabled_until: null
  safe_search:
    enabled: false
    bing: true
    duckduckgo: true
    google: true
    pixabay: true
    yandex: true
    youtube: true
  blocking_mode: default
  parental_block_host: family-block.dns.adguard.com
  safebrowsing_block_host: standard-block.dns.adguard.com
  rewrites: []
  safebrowsing_cache_size: 1048576
  safesearch_cache_size: 1048576
  parental_cache_size: 1048576
  cache_time: 30
  filters_update_interval: 24
  blocked_response_ttl: 10
  filtering_enabled: true
  parental_enabled: false
  safebrowsing_enabled: false
  protection_enabled: true
clients:
  runtime_sources:
    whois: true
    arp: true
    rdns: true
    dhcp: true
    hosts: true
  persistent: []
log:
  enabled: true
  file: ""
  max_backups: 0
  max_size: 100
  max_age: 3
  compress: false
  local_time: false
  verbose: false
os:
  group: ""
  user: ""
  rlimit_nofile: 0
schema_version: 28
EOF

    echo "$compose_file" > "$WORK_DIR/docker-compose.yml"
    docker compose up -d
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
            echo -e "${GREEN}Логин: $adguard_user${NC}"
            echo -e "${GREEN}Пароль: $adguard_password${NC}"
            ;;
        ui)
            echo -e "${BLUE}Веб-интерфейс WireGuard: http://$wg_host:$port${NC}"
            echo -e "${GREEN}Пароль: $wg_password${NC}"
            echo -e "${BLUE}AdGuardHome доступен через VPN: http://10.2.0.100${NC}"
            echo -e "${GREEN}Логин: $adguard_user${NC}"
            echo -e "${GREEN}Пароль: $adguard_password${NC}"
            ;;
        dark)
            echo -e "${BLUE}Веб-интерфейс WireGuard: http://$MYHOST_IP:51821${NC}"
            echo -e "${GREEN}Пароль wg-easy: openode${NC}"
            echo -e "${BLUE}AdGuardHome через VPN: http://10.2.0.100${NC}"
            echo -e "${GREEN}Логин: $adguard_user${NC}"
            echo -e "${GREEN}Пароль: $adguard_password${NC}"
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

# Функция статуса
status() {
    if [ -f "$WORK_DIR/docker-compose.yml" ]; then
        echo -e "\e[48;5;202m\e[30m ================================ \e[0m"
        echo -e "\e[48;5;202m\e[30m          DWG Service Status      \e[0m"
        echo -e "\e[48;5;202m\e[30m ================================ \e[0m"
        VERSION=$(get_dwg_version)
        echo -e "${GREEN}Installed Version:${NC} $VERSION"

        STATUS=$(docker compose -f "$WORK_DIR/docker-compose.yml" ps --format "{{.Name}} {{.Image}} {{.Status}} {{.Ports}}")
        if [ -z "$STATUS" ]; then
            echo -e "${RED}No containers running${NC}"
        else
            echo -e "${GREEN}Containers:${NC}"
            echo "$STATUS" | while IFS= read -r line; do
                NAME=$(echo "$line" | awk '{print $1}')
                IMAGE=$(echo "$line" | awk '{print $2}')
                STATUS=$(echo "$line" | awk '{print $3}')
                PORTS=$(echo "$line" | awk '{$1=$2=$3=""; print substr($0, index($0,$3)+length($3)+1)}')
                echo -e "  - ${BLUE}$NAME${NC}: $IMAGE - $STATUS"
                [ -n "$PORTS" ] && echo -e "    ${YELLOW}Ports:${NC} $PORTS"
            done
        fi

        echo -e "${GREEN}Node IP:${NC} $MYHOST_IP"
        echo -e "${GREEN}Config Path:${NC} $CONF_DIR/AdGuardHome.yaml"
        if [ "$VERSION" == "ui" ] || [ "$VERSION" == "dark" ]; then
            echo -e "${GREEN}WireGuard Web UI:${NC} http://$MYHOST_IP:51821"
        fi
        if [ "$VERSION" != "unknown" ]; then
            echo -e "${GREEN}AdGuardHome:${NC} http://10.2.0.100 (via VPN)"
        fi
        echo -e "\e[48;5;202m\e[30m ================================ \e[0m"
    else
        echo -e "${RED}Контейнеры не установлены${NC}"
    fi
}

# Новые функции
up() {
    if [ -f "$WORK_DIR/docker-compose.yml" ]; then
        echo -e "${GREEN}Запуск сервисов...${NC}"
        docker compose -f "$WORK_DIR/docker-compose.yml" up -d
        echo -e "${GREEN}Сервисы запущены${NC}"
    else
        echo -e "${RED}Контейнеры не установлены${NC}"
    fi
}

down() {
    if [ -f "$WORK_DIR/docker-compose.yml" ]; then
        echo -e "${GREEN}Остановка сервисов...${NC}"
        docker compose -f "$WORK_DIR/docker-compose.yml" down
        echo -e "${GREEN}Сервисы остановлены${NC}"
    else
        echo -e "${RED}Контейнеры не установлены${NC}"
    fi
}

logs() {
    if [ -f "$WORK_DIR/docker-compose.yml" ]; then
        echo -e "${GREEN}Логи сервисов:${NC}"
        docker compose -f "$WORK_DIR/docker-compose.yml" logs --tail=50
    else
        echo -e "${RED}Контейнеры не установлены${NC}"
    fi
}

edit() {
    if [ -f "$WORK_DIR/docker-compose.yml" ]; then
        nano "$WORK_DIR/docker-compose.yml"
    else
        echo -e "${RED}Файл docker-compose.yml не найден${NC}"
    fi
}

update() {
    echo -e "${GREEN}Обновление DWG до последней версии...${NC}"
    wget -qO /usr/local/bin/dwg "$SCRIPT_URL"
    chmod +x /usr/local/bin/dwg
    if [ -s /usr/local/bin/dwg ]; then
        echo -e "${GREEN}Скрипт обновлен${NC}"
        echo -e "${YELLOW}Перезапустите контейнеры с помощью 'dwg restart' для применения обновлений${NC}"
    else
        echo -e "${RED}Ошибка при обновлении скрипта${NC}"
    fi
}

version() {
    echo -e "${GREEN}Текущая версия DWG:${NC} $(get_dwg_version)"
    echo -e "${YELLOW}Скрипт версии: beta2${NC}"
}

# Основная логика обработки команд
case "$1" in
    script-install) script_install ;;
    status) status ;;
    install) install_dwg ;;
    uninstall)
        if [ -f "$WORK_DIR/docker-compose.yml" ]; then
            echo -e "${YELLOW}Вы уверены, что хотите удалить DWG? (y/n): ${NC}"
            read confirm1
            if [ "$confirm1" != "y" ]; then
                echo -e "${GREEN}Удаление отменено${NC}"
                exit 0
            fi
            echo -e "${YELLOW}Подтвердите удаление DWG еще раз (y/n): ${NC}"
            read confirm2
            if [ "$confirm2" != "y" ]; then
                echo -e "${GREEN}Удаление отменено${NC}"
                exit 0
            fi
            echo -e "${GREEN}Удаление контейнеров и томов...${NC}"
            docker compose -f "$WORK_DIR/docker-compose.yml" down -v
            echo -e "${YELLOW}Удалить папку $WORK_DIR полностью? (y/n): ${NC}"
            read remove_dir
            if [ "$remove_dir" == "y" ]; then
                rm -rf "$WORK_DIR"
                echo -e "${GREEN}Папка $WORK_DIR удалена${NC}"
            else
                rm -f "$WORK_DIR/docker-compose.yml"
                echo -e "${GREEN}Только docker-compose.yml удален, папка $WORK_DIR сохранена${NC}"
            fi
            echo -e "${GREEN}Удаление завершено${NC}"
        else
            echo -e "${RED}Нечего удалять${NC}"
        fi
        ;;
    restart)
        if [ -f "$WORK_DIR/docker-compose.yml" ]; then
            echo -e "${GREEN}Перезапуск контейнеров...${NC}"
            docker compose -f "$WORK_DIR/docker-compose.yml" restart
            echo -e "${GREEN}Перезапуск завершен${NC}"
        else
            echo -e "${RED}Контейнеры не установлены${NC}"
        fi
        ;;
    up) up ;;
    down) down ;;
    logs) logs ;;
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
            docker compose -f "$WORK_DIR/docker-compose.yml" restart
            echo -e "${GREEN}Пароль для wg-easy обновлен${NC}"
        fi
        if [ "$VERSION" == "ui" ] || [ "$VERSION" == "dark" ] || [ "$VERSION" == "cli" ]; then
            echo -en "${YELLOW}Введите новый логин для AdGuardHome (Enter для сохранения текущего): ${NC}"
            read new_adguard_user
            echo -en "${YELLOW}Введите новый пароль для AdGuardHome: ${NC}"
            read -s new_adguard_password
            echo
            if [ -n "$new_adguard_user" ] || [ -n "$new_adguard_password" ]; then
                new_adguard_user=${new_adguard_user:-$(grep "name:" "$CONF_DIR/AdGuardHome.yaml" | awk '{print $2}')}
                new_adguard_password=${new_adguard_password:-$(grep "password:" "$CONF_DIR/AdGuardHome.yaml" | awk '{print $2}')}
                adguard_hash=$(htpasswd -nbB "$new_adguard_user" "$new_adguard_password" | cut -d ":" -f 2)
                sed -i "s/name: .*/name: $new_adguard_user/" "$CONF_DIR/AdGuardHome.yaml"
                sed -i "s/password: .*/password: $adguard_hash/" "$CONF_DIR/AdGuardHome.yaml"
                docker compose -f "$WORK_DIR/docker-compose.yml" restart adguardhome 2>/dev/null || docker compose -f "$WORK_DIR/docker-compose.yml" restart adwireguard
                echo -e "${GREEN}Пароль для AdGuardHome обновлен${NC}"
            fi
        fi
        if [ "$VERSION" == "cli" ] && [ -z "$new_adguard_user" ] && [ -z "$new_adguard_password" ]; then
            echo -e "${YELLOW}Для CLI версии смена пароля wg-easy не требуется${NC}"
        fi
        ;;
    peers) peers ;;
    edit) edit ;;
    update) update ;;
    version) version ;;
    *)
        echo -e "\e[48;5;202m\e[30m ================================ \e[0m"
        echo -e "\e[48;5;202m\e[30m          DWG CLI Help            \e[0m"
        echo -e "\e[48;5;202m\e[30m ================================ \e[0m"
        echo -e "Usage:"
        echo -e "  dwg [command]\n"
        echo -e "Commands:"
        echo -e "  script-install   – Install DWG script to /usr/local/bin"
        echo -e "  install          – Install DWG services"
        echo -e "  uninstall        – Uninstall DWG services"
        echo -e "  status           – Show detailed status of services"
        echo -e "  restart          – Restart all services"
        echo -e "  up               – Start services"
        echo -e "  down             – Stop services"
        echo -e "  logs             – Show logs of services"
        echo -e "  change-password  – Change passwords for wg-easy/AdGuardHome"
        echo -e "  peers            – Manage WireGuard peers (CLI version only)"
        echo -e "  edit             – Edit docker-compose.yml (via nano)"
        echo -e "  update           – Update DWG to latest version"
        echo -e "  version          – Show current DWG version"
        echo -e "\nDWG Information:"
        echo -e "  Config Path: $CONF_DIR/AdGuardHome.yaml"
        echo -e "  Node IP: $MYHOST_IP"
        echo -e "  Current Version: $(get_dwg_version)"
        echo -e "\e[48;5;202m\e[30m ================================ \e[0m"
        ;;
esac
