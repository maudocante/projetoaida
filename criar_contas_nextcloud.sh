#!/bin/bash

# Cria o usuário 'ana' no Nextcloud via docker-compose com senha definida
OC_PASS=12345678 docker-compose exec -T app php occ user:add --password-from-env ana

