# Dump do banco de dados PostgreSQL

## Executando o dump diretamente do container `db` via docker-compose

1. Execute o comando abaixo no diretório do projeto (onde está o docker-compose.yml):

   ```sh
   docker-compose exec db pg_dump -U nextcloud nextcloud > nextcloud_dump.sql
   ```

2. (Opcional) Comprimir o arquivo dump:
   ```sh
   gzip nextcloud_dump.sql
   ```

3. Para restaurar o dump no container:
   ```sh
   cat nextcloud_dump.sql | docker-compose exec -T db psql -U nextcloud nextcloud
   ```

---
