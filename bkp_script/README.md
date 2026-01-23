# Script de backup db

## 1. Script Principal de Backup (/usr/local/bin/backup_access.sh):  

```bash
# Script de backup para arquivos de banco de dados Access
# Autor: Sistema de Backup
# Data: $(date)

# Configurações
BACKUP_ROOT="/backup/databases"
SOURCE_DIR="$HOME/basedados/Dados/" # "/caminho/para/seus/arquivos/access"
LOG_FILE="/var/log/backup_access.log"
RETENTION_DAYS=30
RETENTION_WEEKS=8
RETENTION_MONTHS=12

# Extensões de arquivos Access
FILE_EXTENSIONS=("*.mdb" "*.accdb" "*.mde" "*.accde")

# Função para logging
log_message() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" | tee -a "$LOG_FILE"
}

# Criar diretórios se não existirem
create_directories() {
    mkdir -p "$BACKUP_ROOT/diario"
    mkdir -p "$BACKUP_ROOT/semanal"
    mkdir -p "$BACKUP_ROOT/mensal"
    mkdir -p "$(dirname "$LOG_FILE")"
    
    # Verificar permissões
    chmod 755 "$BACKUP_ROOT"
    chmod 755 "$BACKUP_ROOT"/*
}

# Backup diário
backup_diario() {
    local timestamp=$(date '+%Y%m%d_%H%M%S')
    local backup_dir="$BACKUP_ROOT/diario"
    
    log_message "Iniciando backup diário..."
    
    for ext in "${FILE_EXTENSIONS[@]}"; do
        for file in "$SOURCE_DIR"/$ext; do
            if [ -f "$file" ]; then
                local filename=$(basename "$file")
                local backup_file="${backup_dir}/${filename%.*}_diario_${timestamp}.${filename##*.}"
                
                # Criar cópia do arquivo
                cp -p "$file" "$backup_file"
                
                # Compactar opcionalmente
                # tar -czf "${backup_file}.tar.gz" "$backup_file" && rm "$backup_file"
                
                log_message "Backup diário criado: $backup_file"
            fi
        done
    done
    
    # Limpeza de backups antigos (mantém últimos 30 dias)
    find "$backup_dir" -type f -name "*_diario_*" -mtime +$RETENTION_DAYS -delete
    log_message "Backup diário concluído e limpeza executada."
}

# Backup semanal
backup_semanal() {
    local timestamp=$(date '+%Y%m%d')
    local backup_dir="$BACKUP_ROOT/semanal"
    
    # Executar apenas aos domingos
    if [ $(date '+%u') -eq 7 ]; then
        log_message "Iniciando backup semanal..."
        
        for ext in "${FILE_EXTENSIONS[@]}"; do
            for file in "$SOURCE_DIR"/$ext; do
                if [ -f "$file" ]; then
                    local filename=$(basename "$file")
                    local backup_file="${backup_dir}/${filename%.*}_semanal_${timestamp}.${filename##*.}"
                    
                    cp -p "$file" "$backup_file"
                    log_message "Backup semanal criado: $backup_file"
                fi
            done
        done
        
        # Limpeza (mantém últimos 8 semanas)
        find "$backup_dir" -type f -name "*_semanal_*" -mtime +$((RETENTION_WEEKS * 7)) -delete
        log_message "Backup semanal concluído e limpeza executada."
    fi
}

# Backup mensal
backup_mensal() {
    local timestamp=$(date '+%Y%m')
    local backup_dir="$BACKUP_ROOT/mensal"
    
    # Executar apenas no primeiro dia do mês
    if [ $(date '+%d') -eq 1 ]; then
        log_message "Iniciando backup mensal..."
        
        for ext in "${FILE_EXTENSIONS[@]}"; do
            for file in "$SOURCE_DIR"/$ext; do
                if [ -f "$file" ]; then
                    local filename=$(basename "$file")
                    local backup_file="${backup_dir}/${filename%.*}_mensal_${timestamp}.${filename##*.}"
                    
                    cp -p "$file" "$backup_file"
                    log_message "Backup mensal criado: $backup_file"
                fi
            done
        done
        
        # Limpeza (mantém últimos 12 meses)
        find "$backup_dir" -type f -name "*_mensal_*" -mtime +$((RETENTION_MONTHS * 30)) -delete
        log_message "Backup mensal concluído e limpeza executada."
    fi
}

# Verificar se o diretório fonte existe
check_source() {
    if [ ! -d "$SOURCE_DIR" ]; then
        log_message "ERRO: Diretório fonte não existe: $SOURCE_DIR"
        exit 1
    fi
}

# Função principal
main() {
    log_message "=== Início do processo de backup ==="
    
    # Criar diretórios
    create_directories
    
    # Verificar fonte
    check_source
    
    # Executar backups
    backup_diario
    backup_semanal
    backup_mensal
    
    log_message "=== Fim do processo de backup ==="
    echo "" >> "$LOG_FILE"
}

# Executar script
main
```

### 2. Configuração do Crontab:  

Para configurar as execuções automáticas, edite o crontab com ```sudo crontab -e:```  

```bash
# Backup de arquivos Access - OpenSUSE Leap 15.6

# Backup diário às 02:00
0 2 * * * /usr/local/bin/backup_access.sh

# Backup semanal aos domingos às 03:00
0 3 * * 0 /usr/local/bin/backup_access.sh

# Backup mensal no primeiro dia do mês às 04:00
0 4 1 * * /usr/local/bin/backup_access.sh

# Limpeza de logs antigos (mantém 90 dias)
0 5 * * * find /var/log/backup_access.log* -mtime +90 -delete
```

### 3. Script de Instalação (setup_backup.sh):  

```bash
#!/bin/bash
# Script de instalação do sistema de backup

echo "=== Configuração do Sistema de Backup Access ==="

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
```

### 4. Script de Verificação (check_backup.sh):

```bash
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

```
### Instalação e Configuração:

1. Salve os scripts:

    ```bash
    sudo nano /usr/local/bin/backup_access.sh
    # Cole o conteúdo do script principal

    ```
2. Torne executável:

    ```bash
    sudo chmod +x /usr/local/bin/backup_access.sh
    ```

1. Configure as variáveis no script:

    - SOURCE_DIR: Caminho onde estão seus arquivos Access
    - BACKUP_ROOT: Local onde serão salvos os backups
    - Ajuste extensões se necessário

4. Configure o crontab:

    ```bash
    sudo crontab -e
    # Cole as configurações do crontab
    ```

5. Teste manualmente:

    ```bash
    sudo /usr/local/bin/backup_access.sh
    tail -f /var/log/backup_access.log
    ```

### Características do Sistema:

✅ Backup diário: Executa diariamente, mantém 30 dias

✅ Backup semanal: Executa aos domingos, mantém 8 semanas

✅ Backup mensal: Executa no 1º dia do mês, mantém 12 meses

✅ Log detalhado: Registra todas as operações

✅ Limpeza automática: Remove backups antigos

✅ Estrutura organizada: Diretórios separados por periodicidade

### Notas Importantes:

1. Arquivos Access no Linux: Este script assume que você tem arquivos .mdb ou .accdb armazenados no sistema

2. Compactação: O script inclui opção comentada para compactar backups (remova os comentários se necessário)

3 Monodesk/Mono: Se estiver usando Access via Mono, considere parar o serviço durante o backup

4 Testes: Sempre teste em ambiente não produtivo primeiro

5 Monitoramento: Configure alertas se o arquivo de log não for atualizado

### Para ambientes críticos, considere adicionar:

- Verificação de integridade dos backups

- Notificações por email em caso de falha

- Backup remoto para outro servidor ou cloud

