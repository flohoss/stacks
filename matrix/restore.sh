#!/bin/sh

docker compose run --rm \
	-v ./.dbBackup.sql.gz:/backup/.dbBackup.sql.gz:ro \
	matrix-db \
	bash -c "
    echo 'Starting PostgreSQL server...'
    docker-entrypoint.sh postgres &
    PG_PID=\$!
    
    echo 'Waiting for PostgreSQL to be ready...'
    until pg_isready -U user -d postgres; do 
      echo 'Waiting for database...'
      sleep 2
    done
    
    echo 'Restoring Matrix database backup...'
    gunzip -c /backup/.dbBackup.sql.gz | psql -U user -d postgres
    
    echo 'Matrix database restore completed!'
    kill \$PG_PID
    wait \$PG_PID
  "
