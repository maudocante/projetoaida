#!/usr/bin/env bash

# Exwcute como root !
#____________________

# Verificar se é root
if [ "$EUID" -ne 0 ]; then
    echo "Por favor, execute como root (sudo)"
    exit 1
fi
sudo chown -R $USER:$USER /usr/local/bin/backup_access.sh
sudo chown -R $USER:$USER /backup
sudo chown $USER:$USER /var/log/backup_access.log


