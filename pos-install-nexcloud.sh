#!/usr/bin/env bash
sudo -u www-data php /var/www/nextcloud/occ config:system:set maintenance_window_start --type=integer --value=1
sudo -u www-data php /var/www/nextcloud/occ maintenance:repair --include-expensive
sudo -u www-data php /var/www/nextcloud/occ db:add-missing-indices
sudo -u www-data php /var/www/nextcloud/occ config:system:set default_phone_region gw
sudo -u www-data php /var/www/nextcloud/occ config:system:get trusted_domains 
sudo -u www-data php /var/www/nextcloud/occ config:system:set trusted_domains 3 --value=192.168.1.200


# Scan arquivos para garantir que todos os arquivos sejam reconhecidos pelo Nextcloud
sudo -u www-data php -d memory_limit=512M /var/www/nextcloud/occ files:scan --all

# definir memória para 2G no PHP
cat << 'EOF' > /etc/php/8.2/conf.d/20-custom.ini
upload_max_filesize = 2G
post_max_size = 2G
memory_limit = 2G
EOF
systemctl restart apache2

# OUtro método para definir memória
# definir upload max size para 2048 M
sudo -u www-data php /var/www/nextcloud/occ config:system:set upload_max_filesize --value=2048M
sudo -u www-data php /var/www/nextcloud/occ config:system:set post_max_size --value=2048M

# Instala o Collabora Online server (como app do Nextcloud)
sudo -u www-data php /var/www/nextcloud/occ app:install richdocuments

# Instala o cliente Collabora Online (richdocumentscode)
sudo -u www-data php -d memory_limit=512M /var/www/nextcloud/occ app:install richdocumentscode

# Atualiza todas as apps
sudo -u www-data php -d memory_limit=512M /var/www/nextcloud/occ app:update --all
# Lista as apps instaladas
sudo -u www-data php /var/www/nextcloud/occ app:list

# Instala o Nextcloud Talk
sudo -u www-data php /var/www/nextcloud/occ app:install spreed


