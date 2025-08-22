#!/bin/bash

GRUPO="GU"
GRUPO_DISPLAY="Grupo de trabalho"

USUARIO_ANA="ana"
ANA_DISPLAY="Ana"
ANA_SENHA="Ana11223344"

USUARIO_SULEIMANE="suleimane"
SULEIMANE_DISPLAY="Suleimane"
SULEIMANE_SENHA="Suleimane1122"

criar_grupo() {
  # Cria o grupo com display name
  docker-compose exec -u www-data -T app php occ group:add --display-name "$GRUPO_DISPLAY" "$GRUPO"
}

criar_usuario_ana() {
  # Cria o usuário Ana no grupo com senha definida
  docker-compose exec -u www-data -T -e OC_PASS="$ANA_SENHA" app php occ user:add --display-name "$ANA_DISPLAY" --group "$GRUPO" --password-from-env "$USUARIO_ANA"
}

criar_usuario_suleimane() {
  # Cria o usuário Suleimane no grupo com senha definida
  docker-compose exec -u www-data -T -e OC_PASS="$SULEIMANE_SENHA" app php occ user:add --display-name "$SULEIMANE_DISPLAY" --group "$GRUPO" --password-from-env "$USUARIO_SULEIMANE"
}

echo "Escolha uma opção:"
echo "1) Criar grupo $GRUPO"
echo "2) Criar usuário $ANA_DISPLAY"
echo "3) Criar usuário $SULEIMANE_DISPLAY"
echo "4) Criar todos"
read -r -p "Opção: " opcao

case "$opcao" in
  1) criar_grupo ;;
  2) criar_usuario_ana ;;
  3) criar_usuario_suleimane ;;
  4)
    criar_grupo
    criar_usuario_ana
    criar_usuario_suleimane
    ;;
  *) echo "Opção inválida." ;;
esac