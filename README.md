# Docker Compose Stacks

A collection of self-hosted Docker Compose stacks with automated dependency updates via Renovate.

## Automated Updates

This repository uses [Renovate](https://github.com/renovatebot/renovate) to automatically:

- Check for new Docker image versions daily
- Pin image digests for security and reproducibility

## Unraid Compatibility

All runtime services include the Unraid management label. Application services also include an icon and, where applicable, a WebUI URL:

- `net.unraid.docker.managed=composeman`
- `net.unraid.docker.webui=<service-url>` (where applicable)
- `net.unraid.docker.icon=<icon-url>` (where available)

## Reverse Proxy

The repository includes [Traefik](https://github.com/traefik/traefik) as a reverse proxy with:

- Automatic HTTPS via Let's Encrypt
- hetzner DNS challenge for certificate generation
- Docker-provider discovery for services with Traefik router labels

Only services with Traefik router labels are discovered automatically by its Docker provider; other services need router labels or separate Traefik file-provider configuration to be proxied.

Published application ports default to `127.0.0.1`. Set `HOST_BINDING` to a host binding such as `127.0.0.1:8081` to change the port while keeping it loopback-only. A value with only a port, such as `8081`, binds on all host interfaces. Seafile uses separate `SEAFILE_HOST_BINDING`, `SEADOC_HOST_BINDING`, and `NOTIFICATION_HOST_BINDING` variables for its published ports. Traefik's HTTP and HTTPS ports (`80` and `443`) and Forgejo's SSH port (`30:22`) are deliberate public-binding exceptions.

## Notes

- All PostgreSQL, Redis and MariaDB images use a pinned major version
- All images use digest pinning for reproducible deployments
- Dependencies have healthchecks where needed, and dependent services wait for them to become healthy

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
