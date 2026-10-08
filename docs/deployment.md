# Deployment

Continuous deployment of the NestJS backend to an Oracle Cloud Ampere A1 VM
(ARM64 / aarch64, Ubuntu 24.04).

## Architecture

```
push to main (backend/**)
        │
        ▼
GitHub Actions ── build linux/arm64 image (QEMU) ──► push to GHCR
        │                                              (ghcr.io/akshayishaan/gym_management/backend)
        ▼
SSH into VM ── git pull ── docker compose pull ── up -d ── health check
```

1. **build-and-push** builds the backend for `linux/arm64` (the VM is Ampere
   aarch64) using QEMU emulation on the amd64 runner, then pushes to GHCR
   tagged `latest` **and** the commit SHA (the SHA tag enables rollback).
2. **deploy** SSHes into the VM, pulls the latest code, pulls the new image,
   restarts the compose stack, and polls `/health` until it returns 200.

The repo is public, so Actions minutes are free and the VM can `git pull` over
HTTPS without auth.

## Required GitHub secrets

Configure these under **Settings → Secrets and variables → Actions**.

| Secret | Value |
| --- | --- |
| `SSH_HOST` | `80.225.251.105` (the VM's reserved public IP) |
| `SSH_USER` | `ubuntu` |
| `SSH_PRIVATE_KEY` | Full contents of the VM's private key (`~/.ssh/oci_second_account` on your machine) |
| `SSH_PORT` | `22` |

`GITHUB_TOKEN` is provided automatically by Actions — no secret needed.

## VM one-time setup

Run once on the VM before the first deploy:

1. **Install Docker** (Docker Engine + the compose plugin):
   ```bash
   curl -fsSL https://get.docker.com | sh
   sudo usermod -aG docker ubuntu   # then log out/in
   ```
2. **Clone the repo** (public, HTTPS, no auth):
   ```bash
   git clone https://github.com/akshayishaan/gym_management.git ~/gym_management
   ```
3. **Create the env file** with real secrets:
   ```bash
   cd ~/gym_management/backend
   cp .env.production.example .env
   chmod 600 .env
   # edit .env: MONGO_INITDB_ROOT_USERNAME/PASSWORD, JWT_SECRET, JWT_REFRESH_SECRET
   ```
4. **Confirm the OCI security list** allows inbound TCP **22** (SSH) and
   **3001** (API). Both are already open on this VM.

## How to trigger

- **Automatic**: push to `main` touching anything under `backend/**` (or the
  workflow file itself).
- **Manual**: **Actions → Build and Deploy → Run workflow**.

## How to roll back

Redeploy a previous image by pinning `BACKEND_IMAGE` to a SHA tag in the VM's
`backend/.env`, then restart:

```bash
cd ~/gym_management/backend
# set BACKEND_IMAGE=ghcr.io/akshayishaan/gym_management/backend:<sha> in .env
docker compose -f docker-compose.prod.yml up -d
```

Every push tags the image with its commit SHA, so any prior deploy is
recoverable.

## Troubleshooting

- **GHCR auth / pull failures**: the image is anonymously pullable for a
  public repo, but the deploy logs in with `GITHUB_TOKEN` to avoid rate limits.
  If pulls fail, confirm the package exists under the repo's **Packages** tab
  and that `permissions.packages: write` is set in the workflow.
- **Health check fails after deploy**: SSH in and inspect logs —
  `docker compose -f docker-compose.prod.yml logs backend`. Common causes:
  missing/incorrect `JWT_SECRET`/`JWT_REFRESH_SECRET` (the `:?` guard fails
  fast), or Mongo auth mismatch between `MONGO_INITDB_ROOT_*` and the embedded
  `MONGODB_URI`.
- **Mongo replica set not ready**: the `mongo-init.sh` entrypoint starts
  mongod, runs `rs.initiate()`, and waits for PRIMARY before the backend's
  `depends_on: service_healthy` gate passes. If it hangs, check
  `docker compose -f docker-compose.prod.yml logs mongo` and confirm
  `MONGO_HOST_NAME=mongo` (the service name) is set.
