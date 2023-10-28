#!/bin/bash

# Добавление строк в конец файла /etc/ssh/sshd_config
echo "PubkeyAuthentication yes" >> /etc/ssh/sshd_config
echo "AuthorizedKeysFile %h/.ssh/authorized_keys" >> /etc/ssh/sshd_config
echo "RhostsRSAAuthentication no" >> /etc/ssh/sshd_config
echo "HostbasedAuthentication no" >> /etc/ssh/sshd_config
echo "PermitEmptyPasswords no" >> /etc/ssh/sshd_config
echo "PasswordAuthentication no" >> /etc/ssh/sshd_config
echo "PubkeyAcceptedAlgorithms +ssh-rsa" >> /etc/ssh/sshd_config

# Изменение разрешений для папки ~/.ssh/ и файла ~/.ssh/authorized_keys
chmod 700 ~/.ssh/
chmod 600 ~/.ssh/authorized_keys

# Перезапуск службы sshd
service sshd restart
