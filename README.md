# Docker Compose Stacks

A collection of self-hosted Docker Compose stacks with automated dependency updates via Renovate.

## Automated Updates

This repository uses [Renovate](https://github.com/renovatebot/renovate) to automatically:

- Check for new Docker image versions daily at 15:00 UTC
- Pin image digests for security and reproducibility

Renovate configuration: [renovate.js](renovate.js)

## Unraid Compatibility

All services include Unraid Docker labels for easy management in Unraid's Docker UI:
- `net.unraid.docker.managed=composeman`
- `net.unraid.docker.webui=https://[IP]:[PORT:PORT]`
- `net.unraid.docker.icon=<icon-url>`

## Reverse Proxy

All services are configured to work with [Traefik](traefik/) as a reverse proxy with:
- Automatic HTTPS via Let's Encrypt
- deSEC DNS challenge for certificate generation
- Automatic service discovery via Docker labels

## Notes

- All PostgreSQL databases use version 17.x (Alpine)
- Redis services use version 7.x (Alpine)
- MariaDB services use version 10.x
- All images use digest pinning for reproducible deployments
- Healthchecks are configured with `depends_on` for proper startup ordering

## Restore Scripts

Some services include restore scripts for database backups:
- [matrix/restore.sh](matrix/restore.sh) - Restore Matrix Synapse database
- [immich/restore.sh](immich/restore.sh) - Restore Immich database

Stop the stack before running restore scripts.

## License

This repository contains configuration files for various open-source projects. Each service is subject to its own license.
