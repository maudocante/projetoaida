#!/bin/bash

GRUPO="GU"
GRUPO_DISPLAY="Grupo de trabalho"

USUARIO="ana"
DISPLAY="Ana"
SENHA="Ana11223344"


criar_grupo() {
  # Cria o grupo com display name
  docker-compose exec -u www-data -T app php occ group:add --display-name "$GRUPO_DISPLAY" "$GRUPO"
}

criar_usuario() {
  # Cria o usuário Ana no grupo com senha definida
  docker-compose exec -u www-data -T -e OC_PASS="$SENHA" app php occ user:add --display-name "$DISPLAY" --group "$GRUPO" --password-from-env "$USUARIO"
}


echo "Escolha uma opção:"
echo "1) Criar grupo $GRUPO"
echo "2) Criar usuário $DISPLAY"
echo "4) Criar todos"
echo "0) Sair"
read -r -p "Opção: " opcao

case "$opcao" in
  1) criar_grupo ;;
  2) criar_usuario ;;
  4)
    criar_grupo
    criar_usuario
    ;;
  0) echo "Saindo..."; exit 0 ;;
  *) echo "Opção inválida." ;;
esac