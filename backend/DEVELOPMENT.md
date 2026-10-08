# Backend Development Workflow

This document covers the **hybrid** local development setup: infrastructure
(MongoDB + Redis) runs in Docker, while the NestJS app runs natively on the
host for fast hot reload.

## Prerequisites

- **Node.js 24.x** (see `engines.node` in `package.json`).
- **Docker Desktop** running.

## The hybrid model

`docker-compose.dev.yml` runs **only** the infrastructure — a single-node
MongoDB replica set and Redis. The NestJS app itself is **not** containerized
in dev; you run it natively with `npm run start:dev` (`nest start --watch`).

**Why:** on macOS, Docker bind-mounts are slow, so rebuilding a container on
every change is sluggish. Running the app natively gives you fast hot reload
while still getting a real, transaction-capable MongoDB and Redis from Docker.

## Quick start

```bash
cd backend
npm run start:dev   # starts Mongo + Redis (waits for healthy), then the hot-reload app
```

`start:dev` runs `docker compose -f docker-compose.dev.yml up -d --wait` first,
so the app never starts against a Mongo that is not yet ready. `backend/.env`
already points at the local Docker infra (empty Mongo credentials, local Redis),
so no env copying is needed.

## Stopping

```bash
npm run stop:dev    # stops the infra containers (keeps data volumes)
```

- `npm run stop:dev` — stops the containers but **keeps** the data volumes
  (`mongo-dev-data`, `redis-dev-data`).
- `docker compose -f docker-compose.dev.yml down -v` — stops the containers
  **and wipes** the data volumes.

## Mongo credentials

The local Docker Mongo runs with **no auth**, so `backend/.env` sets
`MONGODB_USERNAME` and `MONGODB_PASSWORD` to empty. If you ever set them to
non-empty values while pointing at local Mongo, requests fail with
`AuthenticationFailed` (HTTP 500).

## Ports

| Service | Host port |
| --- | --- |
| MongoDB | `localhost:27017` |
| Redis | `localhost:6379` |
| App | `localhost:3001` |

## Replica set note

MongoDB runs as a single-node replica set (`rs0`) because transactions require
a replica set (ADR-0001). The replica-set member host is pinned to
`localhost` (not the compose service name `mongo`) so the native app's driver
can complete replica-set discovery over `localhost`.

## Data isolation

Dev uses the compose project `gym-backend-dev` with volumes `mongo-dev-data`
and `redis-dev-data`, fully separate from the production compose project and
its data.

## Troubleshooting

- **Mongo not ready yet:** wait for the `mongo` service to report `healthy`:
  `docker compose -f docker-compose.dev.yml ps`.
- **Port 27017 or 6379 already in use:** another MongoDB/Redis is already
  running locally. Stop it or change the published ports.
- **"out of host capacity" errors:** not relevant here — that message comes
  from the cloud VM, not Docker Desktop.
