# cascade-xclone-v34q-deploy

Orchestration repository for the xclone v34q stack. Owns compose topology and acceptance probes only — application source lives in the sibling repos.

## Quick Start

```bash
# 1. Clone sibling repos into ./db ./api ./web
bash bootstrap.sh

# 2. Set the host port (default 8080)
export HOST_PORT=8080

# 3. Build and start all services
docker compose up -d --build

# 4. Verify the stack is healthy
curl http://localhost:${HOST_PORT}/healthz

# 5. Run end-to-end acceptance probe (all 14 steps)
bash acceptance/probe.sh
```

## Services

| Service | Build Context | Exposed |
|---------|--------------|---------|
| db      | ./db         | internal only (postgres:5432) |
| api     | ./api        | internal only (port 8080) |
| web     | ./web        | ${HOST_PORT}:80 |

The web service proxies `/api/*` requests to the api service. The db service runs a `pg_isready` healthcheck; the api waits for it before starting.

## Acceptance Probe

`acceptance/probe.sh` runs a 14-step user journey:
1. Signup alice + get session token
2. GET / returns HTML nav
3. GET /post returns compose form
4. alice posts 'alice-said-hello'
5. Signup bob + bob posts 'bob-said-hello'
6. GET /users lists bob
7. alice follows bob
8. alice's timeline contains 'bob-said-hello'
9. GET /users/bob shows bob's profile
10. GET /profile shows editable fields
11. PATCH /api/users/me updates display_name + bio
12. GET /api/users/me reflects the update
13. alice unfollows bob
14. alice's timeline no longer contains 'bob-said-hello'
