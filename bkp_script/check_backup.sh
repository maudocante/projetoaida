#!/bin/bash
# Verifica status dos backups

LOG_FILE="/var/log/backup_access.log"
BACKUP_ROOT="/backup/databases"

echo "=== Status do Sistema de Backup ==="
echo "Data/Hora: $(date)"
echo ""

# Verificar última execução
echo "Últimas execuções no log:"
tail -20 "$LOG_FILE" 2>/dev/null || echo "Log não encontrado"
echo ""

# Verificar espaço em disco
echo "Uso de disco nos backups:"
du -sh "$BACKUP_ROOT" 2>/dev/null || echo "Diretório não encontrado"
echo ""

# Listar backups existentes
echo "Backups diários:"
find "$BACKUP_ROOT/diario" -type f -name "*_diario_*" 2>/dev/null | wc -l
echo ""

echo "Backups semanais:"
find "$BACKUP_ROOT/semanal" -type f -name "*_semanal_*" 2>/dev/null | wc -l
echo ""

echo "Backups mensais:"
find "$BACKUP_ROOT/mensal" -type f -name "*_mensal_*" 2>/dev/null | wc -l