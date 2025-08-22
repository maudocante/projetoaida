#!/bin/bash

echo "Escolha o que deseja cadastrar primeiro:"
echo "1) Grupo"
echo "2) Usuário"
read -r -p "Digite 1 para grupo ou 2 para usuário: " ordem

if [[ "$ordem" == "1" ]]; then
  read -r -p "Nome do grupo: " GRUPO
  read -r -p "Display name do grupo: " GRUPO_DISPLAY
  read -r -p "Nome do usuário: " USUARIO
  read -r -p "Display name do usuário: " DISPLAY
  read -r -s -p "Senha do usuário: " SENHA
  echo
elif [[ "$ordem" == "2" ]]; then
  read -r -p "Nome do usuário: " USUARIO
  read -r -p "Display name do usuário: " DISPLAY
  read -r -s -p "Senha do usuário: " SENHA
  echo
  read -r -p "Nome do grupo: " GRUPO
  read -r -p "Display name do grupo: " GRUPO_DISPLAY
else
  echo "Opção inválida."
  exit 1
fi


criar_grupo() {
  # Verifica se o grupo já existe
  if docker-compose exec -u www-data -T app php occ group:list | grep -wq "$GRUPO"; then
    echo "Grupo '$GRUPO' já existe."
  else
    # Cria o grupo com display name
    docker-compose exec -u www-data -T app php occ group:add --display-name "$GRUPO_DISPLAY" "$GRUPO"
  fi
}

criar_usuario() {
  # Verifica se o usuário já existe
  if docker-compose exec -u www-data -T app php occ user:list | grep -wq "$USUARIO"; then
    echo "Usuário '$USUARIO' já existe."
  else
    # Cria o usuário no grupo com senha definida
    docker-compose exec -u www-data -T -e OC_PASS="$SENHA" app php occ user:add --display-name "$DISPLAY" --group "$GRUPO" --password-from-env "$USUARIO"
  fi
}


echo "Escolha uma opção:"
echo "1) Criar grupo $GRUPO"
echo "2) Criar usuário $DISPLAY"
echo "3) Criar todos"
echo "0) Sair"
read -r -p "Opção: " opcao

case "$opcao" in
  1) criar_grupo ;;
  2) criar_usuario ;;
  3)
    criar_grupo
    criar_usuario
    ;;
  0) echo "Saindo..."; exit 0 ;;
  *) echo "Opção inválida." ;;
esac