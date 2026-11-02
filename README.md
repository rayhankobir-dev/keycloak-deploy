# Keycloak (Docker) + managed PostgreSQL

Keycloak 26 in Docker. It works with any managed PostgreSQL (Aiven, Neon, etc.).
All configuration uses Keycloak's own `KC_*` environment variables, so the same values work in `.env`
or pasted into a hosting platform's environment settings.

```
Internet ──HTTPS──> platform / proxy ──HTTP :8000──> Keycloak ──SSL──> PostgreSQL
```

## Deploy

```bash
cp .env.example .env     # fill in the DB URL, credentials and hostname
docker compose up -d --build
docker compose logs -f keycloak    # first start creates the schema (~1 min)
```

Open `https://<KC_HOSTNAME>/admin` and log in with the bootstrap admin.
Create a permanent admin user, then delete the bootstrap one.

## Variables

| Variable | Purpose |
|---|---|
| `KC_BOOTSTRAP_ADMIN_USERNAME` / `_PASSWORD` | First admin; only used on the first boot |
| `KC_DB` | `postgres` |
| `KC_DB_URL` | `jdbc:postgresql://HOST:PORT/DB?sslmode=require` |
| `KC_DB_USERNAME` / `KC_DB_PASSWORD` | Database credentials |
| `KC_DB_POOL_MAX_SIZE` | Maximum DB connections (keep below your plan's limit) |
| `KC_HOSTNAME` | Public hostname users reach Keycloak on |
| `KC_HTTP_ENABLED`, `KC_HTTP_HOST`, `KC_HTTP_PORT` | Plain HTTP on `0.0.0.0:8000`; TLS is handled in front |
| `KC_PROXY_HEADERS` | `xforwarded`: trust `X-Forwarded-*` from the proxy so redirect URLs use `https` |

Health and metrics run on port 9000 inside the container, at `/health/ready` and `/metrics`.

## Upgrading

Change the version tag in `Dockerfile` (and `image:` in the compose file), then run `docker compose up -d --build`.
