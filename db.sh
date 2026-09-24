#!/bin/sh
set -eu

usage() {
	cat <<'EOF'
Usage: ./db.sh <backup|restore> [options]

Dumps or restores a database volume with plain Docker, so neither the compose
project nor the stack definition is needed. Plain .sql and gzip-compressed
.sql.gz dumps are both supported.

The database image, user and data directory are read from the container that owns
the volume, so they keep matching the stack. Backup reuses that container when it
is running, restore always starts a temporary server on the volume. Stop the
stack before restoring.

Options:
  --volume <name>                    Docker volume holding the data (required)
  --file <path>                      Dump file (required)
  --engine <postgres|mysql|mariadb>  Database engine (default: postgres)
  --image <ref>                      Database image (default: owning container image)
  --user <name>                      Database user (default: owning container env)
  --password <password>              Database password (default: owning container env)
  --datadir <path>                   Data directory inside the volume
  -h, --help                         Show this help

Examples:
  ./db.sh backup  --volume immich_db --file ./immich.sql.gz
  ./db.sh restore --volume immich_db --file ./immich.sql.gz
  ./db.sh restore --volume seafile_db --engine mariadb --file ./seafile.sql
EOF
}

fail() {
	echo "error: $*" >&2
	exit 1
}

# Runs inside the database container. ACTION selects backup or restore, the
# engine part below fills in the variables. Dumps are written to /tmp/dump.sql
# first, so a failed dump is reported instead of leaving a truncated backup.
container_helpers='
server_pid=
trap stop_server EXIT INT TERM

stop_server() {
	if [ -n "$server_pid" ]; then
		kill "$server_pid" 2>/dev/null
		wait "$server_pid" 2>/dev/null
	fi
}

start_server() {
	echo "starting a temporary $server server" >&2
	docker-entrypoint.sh "$server" >/tmp/server.log 2>&1 &
	server_pid=$!
	attempt=0
	until ready; do
		attempt=$((attempt + 1))
		if [ "$attempt" -ge 60 ]; then
			echo "timed out waiting for $server" >&2
			cat /tmp/server.log >&2
			exit 1
		fi
		sleep 1
	done
}

emit_dump() {
	if [ -n "${DB_COMPRESS:-}" ]; then
		gzip -c /tmp/dump.sql
	else
		cat /tmp/dump.sql
	fi
	rm -f /tmp/dump.sql
}

dump_failed() {
	echo "dump failed" >&2
	exit 1
}

restore_failed() {
	echo "restore failed" >&2
	exit 1
}
'

postgres_script="$container_helpers"'
server=postgres
ready() {
	pg_isready -q
}

if [ -n "${DB_USER:-}" ]; then
	PGUSER=$DB_USER
elif [ -n "${POSTGRES_USER:-}" ]; then
	PGUSER=$POSTGRES_USER
else
	PGUSER=postgres
fi
export PGUSER
if [ -n "${DB_PASSWORD:-}" ]; then
	PGPASSWORD=$DB_PASSWORD
elif [ -n "${POSTGRES_PASSWORD:-}" ]; then
	PGPASSWORD=$POSTGRES_PASSWORD
fi
if [ -n "${PGPASSWORD:-}" ]; then
	export PGPASSWORD
fi

case $ACTION in
backup)
	ready || start_server
	pg_dumpall --clean --if-exists >/tmp/dump.sql || dump_failed
	emit_dump
	;;
restore)
	cat >/tmp/dump.sql || dump_failed
	start_server
	psql -q --dbname=postgres < /tmp/dump.sql || restore_failed
	;;
*)
	echo "unknown action $ACTION" >&2
	exit 1
	;;
esac
'

mariadb_script="$container_helpers"'
server=mariadbd
ready() {
	mariadb-admin ping --host=127.0.0.1 >/dev/null 2>&1
}

if [ -n "${DB_USER:-}" ]; then
	db_user=$DB_USER
else
	db_user=root
fi
if [ -n "${DB_PASSWORD:-}" ]; then
	MYSQL_PWD=$DB_PASSWORD
	export MYSQL_PWD
fi

case $ACTION in
backup)
	ready || start_server
	mariadb-dump --all-databases --single-transaction --quick --lock-tables=false --user="$db_user" >/tmp/dump.sql || dump_failed
	emit_dump
	;;
restore)
	cat >/tmp/dump.sql || dump_failed
	start_server
	mariadb --host=127.0.0.1 --user="$db_user" < /tmp/dump.sql || restore_failed
	;;
*)
	echo "unknown action $ACTION" >&2
	exit 1
	;;
esac
'

mysql_script="$container_helpers"'
server=mysqld
ready() {
	mysqladmin ping --host=127.0.0.1 >/dev/null 2>&1
}

if [ -n "${DB_USER:-}" ]; then
	db_user=$DB_USER
else
	db_user=root
fi
if [ -n "${DB_PASSWORD:-}" ]; then
	MYSQL_PWD=$DB_PASSWORD
	export MYSQL_PWD
fi

case $ACTION in
backup)
	ready || start_server
	mysqldump --all-databases --single-transaction --quick --lock-tables=false --user="$db_user" >/tmp/dump.sql || dump_failed
	emit_dump
	;;
restore)
	cat >/tmp/dump.sql || dump_failed
	start_server
	mysql --host=127.0.0.1 --user="$db_user" < /tmp/dump.sql || restore_failed
	;;
*)
	echo "unknown action $ACTION" >&2
	exit 1
	;;
esac
'

container_env() {
	docker inspect -f '{{range .Config.Env}}{{println .}}{{end}}' "$1" | sed -n "s/^$2=//p" | head -n 1
}

command=${1:-}
[ $# -gt 0 ] && shift

engine=postgres
volume=
file=
image=
user=
password=
datadir=

while [ $# -gt 0 ]; do
	case $1 in
		--engine) engine=$2; shift 2 ;;
		--volume) volume=$2; shift 2 ;;
		--file) file=$2; shift 2 ;;
		--image) image=$2; shift 2 ;;
		--user) user=$2; shift 2 ;;
		--password) password=$2; shift 2 ;;
		--datadir) datadir=$2; shift 2 ;;
		-h | --help)
			usage
			exit 0
			;;
		*) fail "unknown argument '$1'" ;;
	esac
done

case $command in
	backup | restore) ;;
	-h | --help | '')
		usage
		exit 0
		;;
	*) fail "unknown command '$command' (expected backup or restore)" ;;
esac

[ -n "$volume" ] || fail "--volume is required"
[ -n "$file" ] || fail "--file is required"
docker volume inspect "$volume" >/dev/null 2>&1 || fail "no such docker volume '$volume'"

owner=$(docker ps -aq --filter "volume=$volume" | head -n 1)
running=
if [ -n "$owner" ]; then
	docker ps -q --filter "id=$owner" | grep -q . && running=$owner
	[ -n "$image" ] || image=$(docker inspect -f '{{.Config.Image}}' "$owner")
	if [ -z "$datadir" ]; then
		datadir=$(docker inspect -f '{{range .Mounts}}{{.Name}} {{.Destination}}{{println}}{{end}}' "$owner" | sed -n "s/^$volume //p" | head -n 1)
	fi
fi

case $engine in
	postgres)
		image=${image:-postgres:17}
		datadir=${datadir:-/var/lib/postgresql/data}
		if [ -n "$owner" ]; then
			[ -n "$user" ] || user=$(container_env "$owner" POSTGRES_USER)
			[ -n "$password" ] || password=$(container_env "$owner" POSTGRES_PASSWORD)
		fi
		script=$postgres_script
		;;
	mariadb)
		image=${image:-mariadb:latest}
		datadir=${datadir:-/var/lib/mysql}
		if [ -n "$owner" ]; then
			[ -n "$password" ] || password=$(container_env "$owner" MARIADB_ROOT_PASSWORD)
		fi
		script=$mariadb_script
		;;
	mysql)
		image=${image:-mysql:latest}
		datadir=${datadir:-/var/lib/mysql}
		if [ -n "$owner" ]; then
			[ -n "$password" ] || password=$(container_env "$owner" MYSQL_ROOT_PASSWORD)
		fi
		script=$mysql_script
		;;
	*) fail "unknown engine '$engine' (expected postgres, mysql or mariadb)" ;;
esac
mount_path=$datadir

case $file in
	/*) ;;
	*) file="$(pwd)/$file" ;;
esac

env_args=
[ -n "$user" ] && env_args="$env_args -e DB_USER=$user"
[ -n "$password" ] && env_args="$env_args -e DB_PASSWORD=$password"
if [ "$engine" != postgres ] && [ -z "$password" ]; then
	env_args="$env_args -e MYSQL_ALLOW_EMPTY_PASSWORD=1"
fi
[ "${file%.gz}" = "$file" ] || env_args="$env_args -e DB_COMPRESS=1"

run_script() {
	if [ -n "$running" ]; then
		# shellcheck disable=SC2086
		docker exec -i -e "ACTION=$1" $env_args "$running" sh -c "$script"
	else
		# shellcheck disable=SC2086
		docker run --rm -i -v "$volume:$mount_path" -e "ACTION=$1" $env_args --entrypoint sh "$image" -c "$script"
	fi
}

if [ "$command" = backup ]; then
	if [ -n "$running" ]; then
		echo "Dumping '$volume' through running container $running"
	else
		echo "Dumping '$volume' through a temporary $image container"
	fi
	if run_script backup >"$file"; then
		echo "Backup written to $file"
	else
		rm -f "$file"
		fail "backup failed, removed '$file'"
	fi
	exit 0
fi

[ -z "$running" ] || fail "'$volume' is still used by container $running; stop the stack first"
[ -f "$file" ] || fail "no such file '$file'"
echo "Restoring '$file' into '$volume' with a temporary $image container"

if [ "${file%.gz}" = "$file" ]; then
	cat "$file"
else
	gunzip -c "$file"
fi | run_script restore || fail "restore failed"

echo "Restore completed"
