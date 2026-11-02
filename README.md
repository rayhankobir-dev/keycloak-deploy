# Keycloak + Aiven for PostgreSQL

Keycloak 26 runs in Docker on your server and stores its data in a managed **Aiven for PostgreSQL** database.
Caddy sits in front and gets HTTPS certificates from Let's Encrypt automatically.

```
Internet ──443──> Caddy ──8080──> Keycloak ──SSL──> Aiven PostgreSQL
```

## 1. Create the database on Aiven

1. Aiven Console → **Create service** → **PostgreSQL** → pick a plan and region (choose a region close to your server).
2. When it is running, open the service → **Databases** → create a database named `keycloak`.
3. Copy the host, port, user and password from **Overview → Connection information**.
4. *(Recommended)* **Allowed IP addresses**: replace `0.0.0.0/0` with your server's public IP.

## 2. Prepare the server

You need a Linux VM with Docker plus the Compose plugin, ports 80 and 443 open,
and a DNS `A` record (for example `auth.example.com`) pointing at the VM.

```bash
git clone <this-repo> keycloak && cd keycloak   # or scp the folder
cp .env.example .env
nano .env                                       # fill in the domain, admin password and Aiven details
```

## 3. Deploy

```bash
docker compose up -d --build
docker compose logs -f keycloak    # first start creates the schema (~1 min)
```

Then open `https://<KC_DOMAIN>/admin` and log in with `KC_ADMIN_USER` / `KC_ADMIN_PASSWORD`.
**Create a permanent admin user and delete the bootstrap one.** Keycloak marks the bootstrap admin as temporary.

## Stricter TLS to Aiven (optional)

1. Aiven Console → service Overview → download the **CA certificate** to `./certs/ca.pem`.
2. In `.env`, set `AIVEN_PG_SSLMODE=verify-full` and `AIVEN_PG_SSLROOTCERT=1`.
3. Run `docker compose up -d`.

## Operations

| Task | Command |
|---|---|
| Upgrade Keycloak | Change the tag in `Dockerfile` (and `image:` in compose), then run `docker compose up -d --build` |
| Restart | `docker compose restart keycloak` |
| Logs | `docker compose logs -f keycloak` |
| Health | `docker compose ps` (shows `healthy`) |
| Backups | Handled by Aiven (automatic daily backups and PITR on paid plans) |

## Notes

- **No reverse proxy?** If you already have nginx or a load balancer that terminates TLS, remove the `caddy`
  service, add `ports: ["127.0.0.1:8080:8080"]` to `keycloak`, and make sure your proxy sends `X-Forwarded-*` headers.
- **Connection limits:** small Aiven plans allow few connections. `KC_DB_POOL_MAX_SIZE` × the number of Keycloak replicas
  must stay below the plan's `max_connections`.
- **Multiple replicas:** Keycloak's clustering cache needs the nodes to discover each other. Running more than one node
  needs extra cache configuration that this single-node setup leaves out.
