#!/bin/bash

# ============================================
# SCRIPT INTERATIVO PARA CRIAR CONTAINERS
# ============================================

# Cores para output
VERDE='\033[0;32m'
AMARELO='\033[1;33m'
VERMELHO='\033[0;31m'
AZUL='\033[0;34m'
NC='\033[0m' # No Color

# Funções de exibição
mostrar_titulo() {
    clear
    echo -e "${AZUL}╔══════════════════════════════════════════════╗${NC}"
    echo -e "${AZUL}║    CRIADOR DE CONTAINERS PROXMOX - LXC       ║${NC}"
    echo -e "${AZUL}╚══════════════════════════════════════════════╝${NC}"
    echo ""
}

erro() {
    echo -e "${VERMELHO}❌ $1${NC}"
}

sucesso() {
    echo -e "${VERDE}✅ $1${NC}"
}

info() {
    echo -e "${AMARELO}ℹ️  $1${NC}"
}

aguardar() {
    echo ""
    read -p "Pressione ENTER para continuar..."
}

# ============================================
# FUNÇÕES PRINCIPAIS
# ============================================

verificar_root() {
    if [ "$EUID" -ne 0 ]; then 
        erro "Este script precisa ser executado como root!"
        echo "Use: sudo $0"
        exit 1
    fi
    sucesso "Executando como root"
}

listar_containers() {
    echo ""
    info "Containers existentes:"
    pct list | head -20
    echo ""
}

verificar_id_livre() {
    local id=$1
    if pct list | grep -q " $id "; then
        return 1  # ID já existe
    else
        return 0  # ID livre
    fi
}

listar_templates() {
    local templates=()
    echo ""
    info "Templates disponíveis:"
    echo ""
    
    # Procura templates no diretório padrão
    if [ -d "/var/lib/vz/template/cache" ]; then
        local count=1
        for template in /var/lib/vz/template/cache/*; do
            if [ -f "$template" ]; then
                nome_template=$(basename "$template")
                templates+=("$nome_template")
                echo "  $count) $nome_template"
                ((count++))
            fi
        done
    fi
    
    if [ ${#templates[@]} -eq 0 ]; then
        echo "  Nenhum template encontrado!"
        echo ""
        info "Para baixar templates, use: pveam available"
        info "Exemplo: pveam download local ubuntu-22.04-standard_22.04-1_amd64.tar.gz"
    fi
    
    echo ""
}

baixar_template() {
    echo ""
    info "Templates disponíveis para download:"
    echo "1) Ubuntu 24.04"
    echo "2) Alpine 3.22"
    echo "3) Debian 12"
    echo "4) CentOS 8"
    echo "5) Outro"
    echo ""
    read -p "Escolha uma opção (1-5): " opcao_template
    
    case $opcao_template in
        1)
            TEMPLATE="ubuntu-24.04-standard_24.04-2_amd64*"
            ;;
        2)
            TEMPLATE="alpine-3.22-default_20250617_amd64*"
            ;;
        3)
            TEMPLATE="debian-12-standard_12.12-1_amd64*"
            ;;
        4)
            TEMPLATE="centos-9-stream-default_20240828_amd64*"
            ;;
        5)
            read -p "Digite o nome exato do template: " TEMPLATE
            ;;
        *)
            erro "Opção inválida!"
            return 1
            ;;
    esac
    
    info "Baixando template $TEMPLATE..."
    pveam download local "$TEMPLATE"
    
    if [ $? -eq 0 ]; then
        sucesso "Template baixado com sucesso!"
        return 0
    else
        erro "Falha ao baixar template!"
        return 1
    fi
}

selecionar_template() {
    while true; do
        listar_templates
        
        if [ $(ls /var/lib/vz/template/cache/* 2>/dev/null | wc -l) -eq 0 ]; then
            read -p "Nenhum template local. Deseja baixar um? (s/n): " baixar
            if [[ "$baixar" =~ ^[Ss]$ ]]; then
                baixar_template
                if [ $? -eq 0 ]; then
                    continue
                fi
            else
                erro "É necessário ter um template para continuar!"
                exit 1
            fi
        else
            read -p "Digite o número do template ou o nome completo: " escolha
            
            # Se for número
            if [[ "$escolha" =~ ^[0-9]+$ ]]; then
                local templates=(/var/lib/vz/template/cache/*)
                if [ "$escolha" -gt 0 ] && [ "$escolha" -le ${#templates[@]} ]; then
                    TEMPLATE=$(basename "${templates[$((escolha-1))]}")
                    sucesso "Template selecionado: $TEMPLATE"
                    break
                else
                    erro "Número inválido!"
                fi
            # Se for nome
            else
                if [ -f "/var/lib/vz/template/cache/$escolha" ]; then
                    TEMPLATE="$escolha"
                    sucesso "Template selecionado: $TEMPLATE"
                    break
                else
                    erro "Template não encontrado!"
                fi
            fi
        fi
    done
}

configurar_container() {
    mostrar_titulo
    info "CONFIGURAÇÃO DO CONTAINER"
    echo ""
    
    # ID do container
    while true; do
        read -p "ID do container (ex: 100, 101): " CT_ID
        
        if ! [[ "$CT_ID" =~ ^[0-9]+$ ]]; then
            erro "ID deve ser um número!"
            continue
        fi
        
        if verificar_id_livre "$CT_ID"; then
            sucesso "ID $CT_ID disponível"
            break
        else
            erro "ID $CT_ID já está em uso!"
            listar_containers
        fi
    done
    
    # Hostname
    read -p "Hostname do container: " CT_HOSTNAME
    if [ -z "$CT_HOSTNAME" ]; then
        CT_HOSTNAME="ct-$CT_ID"
        info "Usando hostname padrão: $CT_HOSTNAME"
    fi
    
    # Senha
    while true; do
        read -s -p "Senha do root do container: " CT_PASSWORD
        echo
        if [ -z "$CT_PASSWORD" ]; then
            erro "A senha não pode ser vazia!"
            continue
        fi
        read -s -p "Confirme a senha: " CT_PASSWORD_CONFIRM
        echo
        if [ "$CT_PASSWORD" != "$CT_PASSWORD_CONFIRM" ]; then
            erro "As senhas não coincidem!"
        else
            sucesso "Senha definida"
            break
        fi
    done
    
    # Configurações de hardware
    echo ""
    info "Configurações de Hardware (pressione ENTER para padrão)"
    
    read -p "Memória RAM (MB) [1024]: " MEMORIA
    MEMORIA=${MEMORIA:-1024}
    
    read -p "Número de cores CPU [1]: " CORES
    CORES=${CORES:-1}
    
    read -p "Tamanho do disco (GB) [8]: " DISCO
    DISCO=${DISCO:-8}
    
    # Storage
    echo ""
    info "Storages disponíveis:"
    pvesm status | grep -E 'local|nfs' || echo "  local-lvm"
    read -p "Storage [local-lvm]: " STORAGE
    STORAGE=${STORAGE:-local-lvm}
    
    # Rede
    read -p "Bridge de rede [vmbr0]: " BRIDGE
    BRIDGE=${BRIDGE:-vmbr0}
    
    read -p "Configuração de IP (dhcp/static) [dhcp]: " TIPO_IP
    TIPO_IP=${TIPO_IP:-dhcp}
    
    if [ "$TIPO_IP" = "static" ]; then
        read -p "IP (ex: 192.168.1.100/24): " IP_ADDR
        read -p "Gateway (ex: 192.168.1.1): " GATEWAY
        CONFIG_REDE="name=eth0,bridge=$BRIDGE,ip=$IP_ADDR,gw=$GATEWAY"
    else
        CONFIG_REDE="name=eth0,bridge=$BRIDGE,ip=dhcp"
    fi
    
    # Selecionar template
    selecionar_template
    
    # Resumo
    mostrar_resumo
}

mostrar_resumo() {
    mostrar_titulo
    info "RESUMO DA CONFIGURAÇÃO"
    echo "══════════════════════════════════════════════"
    echo "ID do Container:      $CT_ID"
    echo "Hostname:             $CT_HOSTNAME"
    echo "Template:             $TEMPLATE"
    echo ""
    echo "Recursos:"
    echo "  Memória:            ${MEMORIA}MB"
    echo "  CPUs:               $CORES"
    echo "  Disco:              ${DISCO}GB"
    echo "  Storage:            $STORAGE"
    echo ""
    echo "Rede:"
    echo "  Bridge:             $BRIDGE"
    if [ "$TIPO_IP" = "static" ]; then
        echo "  IP:                 $IP_ADDR"
        echo "  Gateway:            $GATEWAY"
    else
        echo "  IP:                 DHCP"
    fi
    echo "══════════════════════════════════════════════"
    echo ""
    
    while true; do
        read -p "As configurações estão corretas? (s/n): " confirmar
        case $confirmar in
            [Ss]*)
                sucesso "Continuando com a criação..."
                return 0
                ;;
            [Nn]*)
                info "Vamos reconfigurar..."
                configurar_container
                return 0
                ;;
            *)
                erro "Opção inválida!"
                ;;
        esac
    done
}

criar_container() {
    mostrar_titulo
    info "CRIANDO CONTAINER..."
    echo ""
    
    # Monta o comando
    COMANDO="pct create $CT_ID /var/lib/vz/template/cache/$TEMPLATE \\
    --hostname $CT_HOSTNAME \\
    --password \"$CT_PASSWORD\" \\
    --memory $MEMORIA \\
    --cores $CORES \\
    --storage $STORAGE \\
    --rootfs $STORAGE:${DISCO}G \\
    --net0 $CONFIG_REDE \\
    --unprivileged 1 \\
    --features nesting=1 \\
    --onboot 1"
    
    echo "Comando a ser executado:"
    echo "$COMANDO"
    echo ""
    
    read -p "Executar criação? (s/n): " executar
    
    if [[ "$executar" =~ ^[Ss]$ ]]; then
        echo "Executando..."
        echo ""
        
        # Executa o comando
        pct create $CT_ID /var/lib/vz/template/cache/$TEMPLATE \
            --hostname "$CT_HOSTNAME" \
            --password "$CT_PASSWORD" \
            --memory $MEMORIA \
            --cores $CORES \
            --storage $STORAGE \
            --rootfs $STORAGE:${DISCO} \
            --net0 "$CONFIG_REDE" \
            --unprivileged 1 \
            --features nesting=1 \
            --onboot 1
        
        if [ $? -eq 0 ]; then
            sucesso "Container criado com sucesso!"
        else
            erro "Erro ao criar container!"
            aguardar
            return 1
        fi
    else
        info "Criação cancelada."
        aguardar
        return 1
    fi
}

iniciar_container() {
    echo ""
    read -p "Deseja iniciar o container agora? (s/n): " iniciar
    
    if [[ "$iniciar" =~ ^[Ss]$ ]]; then
        info "Iniciando container $CT_ID..."
        pct start $CT_ID
        
        sleep 3
        
        if pct status $CT_ID | grep -q "running"; then
            sucesso "Container iniciado!"
            
            # Tenta obter IP
            echo ""
            info "Obtendo informações do container..."
            pct exec $CT_ID -- hostname
            pct exec $CT_ID -- ip addr show eth0 | grep "inet " | head -1
        else
            erro "Não foi possível iniciar o container!"
        fi
    fi
}

menu_principal() {
    while true; do
        mostrar_titulo
        info "MENU PRINCIPAL"
        echo ""
        echo "1) Criar novo container"
        echo "2) Listar containers existentes"
        echo "3) Listar templates disponíveis"
        echo "4) Baixar novo template"
        echo "5) Sair"
        echo ""
        read -p "Escolha uma opção (1-5): " opcao
        
        case $opcao in
            1)
                configurar_container
                if criar_container; then
                    iniciar_container
                fi
                aguardar
                ;;
            2)
                mostrar_titulo
                listar_containers
                aguardar
                ;;
            3)
                mostrar_titulo
                listar_templates
                aguardar
                ;;
            4)
                baixar_template
                aguardar
                ;;
            5)
                echo ""
                info "Saindo..."
                exit 0
                ;;
            *)
                erro "Opção inválida!"
                sleep 1
                ;;
        esac
    done
}

# ============================================
# EXECUÇÃO PRINCIPAL
# ============================================

mostrar_titulo
info "Script interativo para criação de containers LXC"
echo ""
verificar_root
menu_principal
