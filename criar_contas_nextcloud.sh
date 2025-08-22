#!/bin/bash

criar_grupo() {
  # Cria o grupo "GU" com display name "Grupo de trabalho"
  docker-compose exec -u www-data -T app php occ group:add --display-name "Grupo de trabalho" "GU"
}

criar_usuario_ana() {
  # Cria o usuário 'ana' no grupo "GU" com senha definida
  docker-compose exec -u www-data -T -e OC_PASS=Ana11223344 app php occ user:add --display-name "Ana" --group "GU" --password-from-env ana
}

criar_usuario_suleimane() {
  # Cria o usuário 'suleimane' no grupo "GU" com senha definida
  docker-compose exec -u www-data -T -e OC_PASS=Suleimane1122 app php occ user:add --display-name "Suleimane" --group "GU" --password-from-env suleimane
}

echo "Escolha uma opção:"
echo "1) Criar grupo GU"
echo "2) Criar usuário Ana"
echo "3) Criar usuário Suleimane"
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