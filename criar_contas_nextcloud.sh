#!/bin/bash

docker-compose exec -T app php occ group:add --display-name "Grupo de trabalho" "GU"
# Cria o usuário 'ana' no Nextcloud via docker-compose com senha definida
docker-compose exec -T app php occ user:add --display-name "Suleimane" --group "GU" suleimane
