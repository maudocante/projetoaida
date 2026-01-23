#!/bin/bash
# Script de instalação do sistema de backup
# Executar como root

echo "=== Configuração do Sistema de Backup Access ==="

# Verificar se é root
if [ "$EUID" -ne 0 ]; then
    echo "Por favor, execute como root (sudo)"
    exit 1
fi

# Criar diretório de backups
sudo mkdir -p /backup/databases/{diario,semanal,mensal}
sudo chmod -R 755 /backup

# Copiar script principal
sudo cp backup_access.sh /usr/local/bin/
sudo chmod +x /usr/local/bin/backup_access.sh


# Criar arquivo de log
sudo touch /var/log/backup_access.log
sudo chmod 644 /var/log/backup_access.log

# Configurar crontab
echo "Configurando crontab..."
(crontab -l 2>/dev/null; echo "") | crontab -
sudo crontab -l > /tmp/crontab_backup 2>/dev/null
cat << 'EOF' | sudo crontab -
# Backup de arquivos Access - OpenSUSE Leap 15.6
0 2 * * * /usr/local/bin/backup_access.sh
0 3 * * 0 /usr/local/bin/backup_access.sh
0 4 1 * * /usr/local/bin/backup_access.sh
0 5 * * * find /var/log/backup_access.log* -mtime +90 -delete
EOF

echo "=== Instalação concluída ==="
echo ""
echo "Configurações:"
echo "1. Edite /usr/local/bin/backup_access.sh para ajustar:"
echo "   - SOURCE_DIR: Seu diretório com arquivos Access"
echo "   - BACKUP_ROOT: Local de armazenamento dos backups"
echo "   - RETENTION_*: Políticas de retenção"
echo ""
echo "2. Verifique o crontab: sudo crontab -l"
echo ""
echo "3. Teste manualmente: sudo /usr/local/bin/backup_access.sh"
echo ""
echo "Logs em: /var/log/backup_access.log"
