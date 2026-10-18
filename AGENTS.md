# Agent Guidance

Read before making changes.

## Git

- Do not commit automatically — wait until explicitly asked.
- One commit per concern — never batch unrelated changes.
- Title only, no body. Capitalize first letter after the prefix:
  - `[fix]` bug fix
  - `[feature]` new functionality
  - `[improve]` improvement to existing functionality
  - `[refactor]` formatting, renaming, structural-only
  - `[meta]` deployment, CI
  - `[docs]` documentation

## Renovate

Dependency PRs are merged as-is. Two exceptions:

- **NetBird** (`netbird/`) — PRs bump `netbird-server`, `reverse-proxy` and
  `dashboard` together. Before merging:
  1. Check the NetBird release notes for the bumped version.
  2. Keep `reverse-proxy` and `netbird-server` on the same version.
  3. Verify [netbird/compose.yml](netbird/compose.yml) still matches
     https://docs.netbird.io/selfhosted/maintenance/upgrade — the docs table is
     the source of truth for `traefik`, `crowdsecurity/crowdsec` and the bouncer
     plugin, which Renovate is disabled for (the root [traefik/](traefik/) stack
     tracks traefik separately and is intentionally allowed to run ahead).
  4. After a server upgrade, apply it with `docker compose up -d` (not
     `restart`) and check the stack still serves `200`.
