#!/bin/sh

docker compose run --rm \
	-v ./.dbBackup.sql.gz:/backup/.dbBackup.sql.gz:ro \
	immich-db \
	bash -c "
    echo 'Starting PostgreSQL server...'
    docker-entrypoint.sh postgres &
    PG_PID=\$!
    
    echo 'Waiting for PostgreSQL to be ready...'
    until pg_isready -U user -d db; do 
      echo 'Waiting for database...'
      sleep 2
    done
    
    echo 'Restoring database backup...'
    gunzip -c /backup/.dbBackup.sql.gz \
    | sed 's/SELECT pg_catalog.set_config('\''search_path'\'', '\'''\'', false);/SELECT pg_catalog.set_config('\''search_path'\'', '\''public, pg_catalog'\'', true);/g' \
    | psql -U user -d db
    
    echo 'Database restore completed!'
    kill \$PG_PID
    wait \$PG_PID
  "
ƒ