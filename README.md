# DWG - Docker WireGuard (DWG) - Проект одного скрипта v2
<img src="https://user-images.githubusercontent.com/50312583/231138618-750b4b04-ade0-4e67-852e-f103030684a9.png" width="400">

# Долгожданное обновление DWG.
## Теперь dwg создается как сервис с возможность управления им. 
## После установки вводите: `dwg help` для получения информации.

### Представляю вам лучшую сборку для самой быстрой настройки VPN сервера на WireGuard.
### Во время установки можно выбрать, что установить: 
### **DWG-UI** = AdGuard with DoH DNS +  Wireguard with UI (wg-easy) 
### **DWG-CLI** = AdGuard with DoH DNS +  Wireguard CLI + Unbound 
### **DWG-DARK** = AdGuard with DoH DNS +  Wireguard with UI (WG-easy)  (Контроль каждого пользователя в AdGuardHome)
### **DWG-A** = **AMNEZIA WG-EASY** + AdGuard with DoH DNS +  Wireguard with UI (WG-easy) 

Тема поддержки на моём форуме:
https://openode.ru/topic/370-dwg-multi/


Скрипт устанавливает все автоматически.
Все комментарии по скрипту внутри в комментариях

### [4VPS.su](https://4vps.su/account/r/18170) Рекомендую - однозначно! Скорость до 2ГБ\с. В моих тестах самый быстрый был сервер в Швейцарии и Дании!
1. Очень хорошая скорость (до 2гб/с)
2. Посуточные тарифы
3. Доступные тарифы мощных сборок.
4. Лояльность к VPN использованию серверов.
### [AEZA.net](https://aeza.net/?ref=377137)  -  бонус +15% к пополнению

# Самая быстрая установка - 1 минута

Запусти команду на чистом сервере

```bash
bash <(wget -qO- https://raw.githubusercontent.com/DigneZzZ/dwg/main/set-up.sh) install
```



## Описание скриптов в папке tools
* *agh.sh* - смена логина и пароля к AGH 
* *docker.sh* - установка docker и docker-compose
* *nano.sh* -  установка редактора
* *ssh.sh* - скрипт смены стандартного порта ssh. (может поменять любой порт)
* *swap.sh* -  скрипт добавления файла подкачки (актуально всем)
* *ufw-docker.sh* - скрипт установки ufw-docker - актуально для WG-easy. Скрипт с пресетом для сборки dwg-ui.
* *ufw.sh* - установка firewall UFW, с автоматическим определением порта SSH и добавлением в исключение.

## Автор:

👤 ** Alexey **
* Git: [DigneZzZ](https://github.com/DigneZzZ)
* Site: [OpeNode.XYZ](https://openode.xyz)
* Blog: [NeoNode.cc](https://neonode.cc)


## После установки

### WG-Easy web-ui:
yo.ur.ip.xx:51821 
И останется ввести пароль который задавали на момент установки


### AdGuard HOME 
#### Заходим после установки:
http://10.2.0.100/  

### Login: **admin** 
### Password: **admin**



## Предустановленный Adlists для Рунета в том числе:
* RU-Adlist
https://easylist-downloads.adblockplus.org/advblock.txt
* BitBlock
https://easylist-downloads.adblockplus.org/bitblock.txt
* Cntblock
https://easylist-downloads.adblockplus.org/cntblock.txt
* EasyList
https://easylist-downloads.adblockplus.org/easylist.txt
* Доп список от Шакала
https://schakal.ru/hosts/alive_hosts_ru_com.txt
* файл с разблокированными r.mail.ru и graph.facebook.com
https://schakal.ru/hosts/hosts_mail_fb.txt
---
* All DNS Servers
https://adguard-dns.io/kb/general/dns-providers/#cloudflare-dns
* DNS Perfomance list:
https://www.dnsperf.com/#!dns-resolvers

# Почему именно AdGuardHome, а не PiHole?
![image](https://user-images.githubusercontent.com/50312583/229718610-cfa5dc9b-08a6-4761-b8e7-f54315afab57.png)
