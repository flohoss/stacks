# Docker Compose Stacks

A collection of self-hosted Docker Compose stacks with automated dependency updates via Renovate.

## Automated Updates

This repository uses [Renovate](https://github.com/renovatebot/renovate) to automatically:

- Check for new Docker image versions daily
- Pin image digests for security and reproducibility

## Unraid Compatibility

All services include Unraid Docker labels for easy management in Unraid's Docker UI:

- `net.unraid.docker.managed=composeman`
- `net.unraid.docker.webui=https://[IP]:[PORT:PORT]`
- `net.unraid.docker.icon=<icon-url>`

## Reverse Proxy

All services are configured to work with [Traefik](https://github.com/traefik/traefik) as a reverse proxy with:

- Automatic HTTPS via Let's Encrypt
- hetzner DNS challenge for certificate generation
- Automatic service discovery via Docker labels

## Notes

- All PostgreSQL, Redis and MariaDB images use a pinned major version
- All images use digest pinning for reproducible deployments
- Healthchecks are configured with `depends_on` for proper startup ordering

## Database Backups

[db.sh](db.sh) dumps or restores a database volume using plain Docker, so the compose project and the stack definition are not needed:

```sh
./db.sh backup  --volume immich_db --file ./immich.sql.gz
./db.sh restore --volume immich_db --file ./immich.sql.gz
./db.sh restore --volume seafile_db --engine mariadb --file ./seafile.sql
```

The database image, user and data directory are read from the container that owns the volume, so they keep matching the stack. Backup reuses that container when it is running, restore starts a temporary server on the volume. Stop the stack before restoring. See `./db.sh --help` for all options.

## License

This repository contains configuration files for various open-source projects. Each service is subject to its own license.
