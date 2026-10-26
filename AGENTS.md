# Agent Guidance

Read before making changes.

## Git

- Do not commit automatically — wait until explicitly asked.
- Never add a `Co-authored-by` trailer, including for Copilot or any other agent.
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

- **NetBird** (`netbird/`) — Renovate bumps `netbird-server`, `reverse-proxy`
  and `dashboard` together; merge the images as-is.

  Then compare `traefik`, `crowdsecurity/crowdsec` and the bouncer plugin flag
  in [netbird/compose.yml](netbird/compose.yml) with the validated table on
  https://docs.netbird.io/selfhosted/maintenance/upgrade. If one differs, set it
  to the table value; otherwise leave the file unchanged. The root
  [traefik/](traefik/) stack is tracked separately and may run ahead.

  That comparison is the whole task. Do not deploy or test the stack.
