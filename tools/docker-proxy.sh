
#!/bin/bash

# Функция для установки прокси-конфигурации для Docker
function set_docker_proxy() {
    # Проверяем, установлен ли Docker
    if ! command -v docker &> /dev/null; then
        echo "Docker не установлен. Установите Docker перед установкой прокси-конфигурации."
        exit 1
    fi

    # Получаем значения прокси из пользователя
    read -p "Введите адрес прокси-сервера: " proxy_address
    read -p "Введите порт прокси-сервера: " proxy_port

    # Устанавливаем прокси-конфигурацию для Docker
    mkdir -p /etc/systemd/system/docker.service.d
    echo "[Service]
Environment=\"HTTP_PROXY=http://${proxy_address}:${proxy_port}/\" 
Environment=\"HTTPS_PROXY=http://${proxy_address}:${proxy_port}/\"" > /etc/systemd/system/docker.service.d/http-proxy.conf

    # Перезагружаем Docker
    systemctl daemon-reload
    systemctl restart docker

    echo "Прокси-конфигурация для Docker успешно установлена."
}

# Функция для отключения прокси-конфигурации для Docker
function unset_docker_proxy() {
    # Проверяем, установлен ли Docker
    if ! command -v docker &> /dev/null; then
        echo "Docker не установлен. Прокси-конфигурация не установлена."
        exit 1
    fi

    # Удаляем прокси-конфигурацию для Docker
    rm -rf /etc/systemd/system/docker.service.d/http-proxy.conf

    # Перезагружаем Docker
    systemctl daemon-reload
    systemctl restart docker

    echo "Прокси-конфигурация для Docker успешно отключена."
}

# Главное меню скрипта
echo "1. Установить прокси-конфигурацию для Docker"
echo "2. Отключить прокси-конфигурацию для Docker"
read -p "Введите номер действия: " choice

case $choice in
    1)
        set_docker_proxy
        ;;
    2)
        unset_docker_proxy
        ;;
    *)
        echo "Некорректный выбор."
        ;;
esac
