 #!/bin/bash
 
 printf "Для корректной работы данной сборки необходимо освободить 53 порт. Сделать это автоматическим скриптом? Гарантий работоспособности на вашей операционной системе мы не даем!!! (Y/n) (по умолчанию - Y, можете нажать Enter): "
read choice_resolv

  if [[ $choice_resolv == "" || $choice_resolv == "Y" || $choice_resolv == "y" ]]; then
    echo "DNSStubListener=no" >>/etc/systemd/resolved.conf
    ln -sf /run/systemd/resolve/resolv.conf /etc/resolv.conf
        printf "Теперь желательно перезапустить контейнер/сервер.. но это не всегда обязательно"
  else
    printf "Скрипт не будет запущен.\n"
    exit 1
  fi
