# Docker Compose Stacks

A collection of self-hosted Docker Compose stacks with automated dependency updates via Renovate.

## Automated Updates

This repository uses [Renovate](https://github.com/renovatebot/renovate) to automatically:

- Check for new Docker image versions daily
- Pin image digests for security and reproducibility

## Unraid Compatibility

Runtime services include the Unraid management label. Application services also include an icon and, where applicable, a WebUI URL:

- `net.unraid.docker.managed=composeman`
- `net.unraid.docker.webui=<service-url>` (where applicable)
- `net.unraid.docker.icon=<icon-url>` (where available)

The NetBird stack ([netbird/](netbird/)) is the exception: it runs its own Traefik instance and ships without Unraid labels.

## Reverse Proxy

Stacks are published in one of two ways:

- **Root Traefik** — [traefik/](traefik/) terminates TLS (Let's Encrypt via the Hetzner DNS challenge) and discovers stacks over the external `proxy` network. These stacks carry `traefik.*` router labels.
- **NetBird reverse proxy** — [netbird/](netbird/) runs its own Traefik instance with router labels in the `netbird` network. Stacks without Traefik labels are published through the NetBird proxy service instead.

Only services with Traefik router labels are discovered automatically by Traefik's Docker provider; every other service needs router labels or separate file-provider configuration to be proxied. Each stack's `compose.yml` shows which mode it uses: a `traefik.enable` label means the root Traefik handles it, while an unlabelled stack is routed by NetBird.

Published application ports default to `127.0.0.1`. Set `HOST_BINDING` to a host binding such as `127.0.0.1:8081` to change the port while keeping it loopback-only. A value with only a port, such as `8081`, binds on all host interfaces. Seafile uses separate `SEAFILE_HOST_BINDING`, `SEADOC_HOST_BINDING`, `NOTIFICATION_HOST_BINDING` and `ONLYOFFICE_HOST_BINDING` variables for its published ports. Traefik's HTTP and HTTPS ports (`80` and `443`), NetBird's WireGuard and relay ports (`3478/udp`, `51820/udp`) and Forgejo's SSH port (`30:22`) are deliberate public-binding exceptions.

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
