upd 28.10.23:
* `secure.sh` - Добавляет полезные настройки безопасности для SSHD и закрывает доступ по паролю! У вас должны быть прописаны ваши ключи в системе.
```bash
bash <(wget -qO- https://raw.githubusercontent.com/DigneZzZ/dwg/main/tools/secure.sh)
```

upd 30.06.23:
* `ufw_rules.sh` - Закрывает доступ ко всем сервисам снаружи сервера, и открывать доступ ко всем сервисами только из сети WG. Конечно, нужно не забыть оставить доступ для SSH. И конечно можно в индивидуальном порядке открыть доступ для конкретного порта наружу.
```bash
bash <(wget -qO- https://raw.githubusercontent.com/DigneZzZ/dwg/main/tools/ufw_rules.sh)
```

upd 22.06.23:
* закрытие доступа к торрентам `block_torrent.sh`
```bash
bash <(wget -qO- https://raw.githubusercontent.com/DigneZzZ/dwg/main/tools/block_torrent.sh)
```
* Открытие доступа к торрентам `open_torrent.sh`
* `dns_close_53_port.sh` - закрытие использование 53 порта
* `dns_open_53_port.sh` - возврат "в зад" использование 53 порта

upd xx.06.23:
* `agh.sh` - смена логина и пароля к AGH
```bash
bash <(wget -qO- https://raw.githubusercontent.com/DigneZzZ/dwg/main/tools/agh.sh)
```
* `docker.sh` - установка docker и docker-compose
```bash
bash <(wget -qO- https://raw.githubusercontent.com/DigneZzZ/dwg/main/tools/docker.sh)
```
* `nano.sh` - установка редактора
```bash
bash <(wget -qO- https://raw.githubusercontent.com/DigneZzZ/dwg/main/tools/nano.sh)
```
* `ssh.sh` - скрипт смены стандартного порта ssh. (может поменять любой порт)
```bash
bash <(wget -qO- https://raw.githubusercontent.com/DigneZzZ/dwg/main/tools/ssh.sh)
```
* `swap.sh` - скрипт добавления файла подкачки (актуально всем)
```bash
bash <(wget -qO- https://raw.githubusercontent.com/DigneZzZ/dwg/main/tools/swap.sh)
```
* `ufw-docker.sh` - скрипт установки ufw-docker - актуально для WG-easy. Скрипт с пресетом для сборки dwg-ui.
```bash
bash <(wget -qO- https://raw.githubusercontent.com/DigneZzZ/dwg/main/tools/ufw-docker.sh)
```
* `ufw.sh` - установка firewall UFW, с автоматическим определением порта SSH и добавлением в исключение. Плюс предлагает рекомендуемые службы
```bash
bash <(wget -qO- https://raw.githubusercontent.com/DigneZzZ/dwg/main/tools/ufw.sh)
```
* `wg-ru-d.sh` - русский для DWG-dark интерфейса
```bash
bash <(wget -qO- https://raw.githubusercontent.com/DigneZzZ/dwg/main/tools/wg-ru-d.sh)
```
* `wg-ru.sh` - русский для DWG-UI интерфейса
```bash
bash <(wget -qO- https://raw.githubusercontent.com/DigneZzZ/dwg/main/tools/wg-ru.sh)
```
* `wg-pass.sh` - скрипт с автоматичесим поиском файла docker-compose.yml и сменой пароля к WG админке.
```bash
bash <(wget -qO- https://raw.githubusercontent.com/DigneZzZ/dwg/main/tools/wg-pass.sh)
```
* `cert.sh` - скрипт автоматизирует получение letsEncrypt сертификата по домену который вы введете в нем. И покажет путь куда сохранил.
```bash
bash <(wget -qO- https://raw.githubusercontent.com/DigneZzZ/dwg/main/tools/cert.sh)
```

### Установка по скрипту:
`bash <(wget -qO- RAW-АДРЕС)`
