#!/bin/bash

# Проверить, установлена ли утилита qrencode
if ! command -v qrencode &> /dev/null; then
    echo "Утилита qrencode не установлена. Устанавливаю..."
    sudo apt-get update
    sudo apt-get install qrencode -y
fi

# Путь к файлу конфигурации
wg_conf_path="wireguard/wg_confs/wg0.conf"

# Получаем список пиров из файла конфигурации и присваиваем им порядковые номера
peers=$(grep -oP '(?<=#).*$' $wg_conf_path | nl)

# Выводим список пиров с порядковыми номерами
printf "\e[48;5;3mСписок пиров в файле конфигурации %s: \e[0m \n%s\n " "$wg_conf_path" "$peers"

# Запрашиваем у пользователя номер пира
printf "\e[48;5;3mВведите номер пира, для которого нужно вывести информацию: \e[0m"
read peer_number

# Получаем имя пира по номеру
peer=$(echo "$peers" | awk -v n=$peer_number '$1 == n {print $2}')

# Путь к файлу конфигурации пира
peer_conf_path="wireguard/$peer/$peer.conf"

# Проверяем, что файл конфигурации пира существует
if [ -f $peer_conf_path ]; then
    # Выводим содержимое файла конфигурации пира
    printf "Содержимое файла конфигурации %s:\n" "$peer_conf_path"
    printf "\e[48;5;12mЧтобы подключиться по файлу, создайте файл \e[48;5;1mpeer.conf\e[48;5;12m со следующим содержимым и импортируйте его в WireGuard \e[0m \n"
    printf "\e[48;5;208m=========================================\e[0m\n"
    cat $peer_conf_path
     printf "\e[48;5;208m=========================================\e[0m\n"
    # Сгенерировать QR-код на основе выбранного файла конфигурации
qrencode -t ansiutf8 < "$peer_conf_path"
else
    # Выводим сообщение об ошибке, если файл конфигурации пира не найден
    printf "\e[48;5;1mФайл конфигурации %s не найден\e[0m\n" "$peer_conf_path"
fi
     printf "\e[48;5;208mhttps://openode.ru\e[0m\n"
