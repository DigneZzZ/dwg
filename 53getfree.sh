 #!/bin/bash
 
 printf "Для корректной работы данной сборки необходимо освободить 53 порт. Сделать это автоматическим скриптом? Гарантий работоспособности на вашей операционной системе мы не даем!!! (Y/n) (по умолчанию - Y, можете нажать Enter): "
read choice_resolv

  if [[ $choice_resolv == "" || $choice_resolv == "Y" || $choice_resolv == "y" ]]; then
    sh -c 'echo DNSStubListener=no >> /etc/systemd/resolved.conf' && systemctl restart systemd-resolved.service
    systemctl stop systemd-resolved.service &&
    rm -f /etc/resolv.conf &&
    ln -s /run/systemd/resolve/resolv.conf /etc/resolv.conf &&
    systemctl start systemd-resolved.service
    printf "\e[42mИмзенения в систему внесены. НЕОБХОДИМО ПЕРЕЗАПУСТИТЬ СЕРВЕР! запустите скрипт ./dwg/set-up.sh после перезагрузки.\e[0m\n"
    printf "\e[42mВыполнение скрипта будет продолжено в любом случае через 5 секунд\e[0m\n"
    sleep 5
    reboot
  else
    printf "Скрипт не будет запущен.\n"
    exit 1
  fi
