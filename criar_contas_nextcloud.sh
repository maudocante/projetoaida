#!/bin/bash

# Cria o grupo "GU" com display name "Grupo de trabalho"
docker-compose exec -u www-data -T app php occ group:add --display-name "Grupo de trabalho" "GU"

# Cria o usuário 'ana' no grupo "GU" com senha definida
docker-compose exec -u www-data -T -e OC_PASS=Ana11223344 app php occ user:add --display-name "Ana" --group "GU" --password-from-env ana

# Cria o usuário 'suleimane' no grupo "GU" com senha definida
docker-compose exec -u www-data -T -e OC_PASS=Suleimane1122 app php occ user:add --display-name "Suleimane" --group "GU" --password-from-env suleimane
