#!/bin/bash

# Script de backup para arquivos de banco de dados Access
# Autor: Sistema de Backup
# Data: $(date)

# Configurações
BACKUP_ROOT="/backup/databases"
SOURCE_DIR="/home/maudo/basedados/Dados" # "/caminho/para/seus/arquivos/access"
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
