#!/bin/bash

docker-compose -u www-data exec -T app php occ group:add --display-name "Grupo de trabalho" "GU"
# Cria o usuário 'ana' no Nextcloud via docker-compose com senha definida
docker-compose -u www-data exec -T app php occ user:add --display-name "Ana" --group "GU" ana
# Cria o usuário 'suleimane' no Nextcloud via docker-compose com senha definida
docker-compose -u www-data exec -T app php occ user:add --display-name "Suleimane" --group "GU" suleimane
