# Releases

Release-driven CI/CD. A release is the single trigger that builds the Android
APK, builds the backend image, and deploys the backend to the VM.

## Flow

```
PR merged to main
        │
        ▼
draft-release.yml ── auto-bump version tag ──► create DRAFT GitHub release
        │
        ▼  (you review + click "Publish release")
release.yml ──┬─ build-backend-image ──► push ARM64 image to GHCR
              ├─ build-apk ────────────► attach repix_<tag>.apk to the release
              └─ deploy-backend ───────► SSH to VM, pull image, restart, /health
```

1. **Merge a PR to `main`** → `.github/workflows/draft-release.yml` creates a
   **draft** release with an auto-bumped version tag.
2. **Review the draft** (title, generated notes, tag) and click
   **Publish release**.
3. Publishing triggers `.github/workflows/release.yml`, which builds the APK
   and backend image in parallel, then deploys the backend and attaches the
   APK to the release.

Nothing deploys on push anymore — deployment happens only when you publish a
release.

## Versioning

- The base version comes from `mobile/pubspec.yaml` (`version: 1.0.0+1` →
  base `1.0.0`; the `+build` suffix is stripped).
- The draft workflow finds the highest existing `vX.Y.Z` tag. If `v<base>` is
  already taken, it bumps the patch until an unused tag is found (e.g.
  `v1.0.0` exists → `v1.0.1`).
- **To set a specific version**, edit `version:` in `mobile/pubspec.yaml`
  before merging the PR.

## APK signing

The release APK is signed with a real keystore **only if** the Android signing
secrets are configured. Without them, the APK is **debug-signed** and is not
suitable for the Play Store (it will still install for internal testing).

### Generate a keystore (once)

```bash
keytool -genkey -v \
  -keystore keystore.jks \
  -alias repix \
  -keyalg RSA -keysize 2048 -validity 10000
```

Keep the keystore and its passwords safe — losing them means you can never
update the app on the Play Store.

### Add the secrets

Base64-encode the keystore and add these four repository secrets under
**Settings → Secrets and variables → Actions → Secrets**:

```bash
base64 -i keystore.jks   # copy the output
```

| Secret | Value |
| --- | --- |
| `ANDROID_KEYSTORE_BASE64` | `base64 -i keystore.jks` output |
| `ANDROID_KEYSTORE_PASSWORD` | keystore password |
| `ANDROID_KEY_ALIAS` | key alias (e.g. `repix`) |
| `ANDROID_KEY_PASSWORD` | key password |

The workflow decodes `ANDROID_KEYSTORE_BASE64` to
`mobile/android/app/keystore.jks` and writes `mobile/android/key.properties`
before building. If `ANDROID_KEYSTORE_BASE64` is unset, the build falls back to
debug signing.

## Required secrets

| Secret | Purpose |
| --- | --- |
| `SSH_HOST` | VM public IP (e.g. `203.0.113.10`) |
| `SSH_USER` | VM SSH user (e.g. `ubuntu`) |
| `SSH_PRIVATE_KEY` | VM private key contents |
| `SSH_PORT` | SSH port (e.g. `22`) |
| `MONGO_INITDB_ROOT_USERNAME` | Mongo root user |
| `MONGO_INITDB_ROOT_PASSWORD` | Mongo root password |
| `JWT_SECRET` | Access-token signing secret |
| `JWT_REFRESH_SECRET` | Refresh-token signing secret |
| `ANDROID_KEYSTORE_BASE64` | *(optional)* base64 keystore for APK signing |
| `ANDROID_KEYSTORE_PASSWORD` | *(optional)* keystore password |
| `ANDROID_KEY_ALIAS` | *(optional)* key alias |
| `ANDROID_KEY_PASSWORD` | *(optional)* key password |

`GITHUB_TOKEN` is provided automatically by Actions.

## Rollback

- **Re-publish an older release**: publishing any release re-runs the deploy
  job, which pulls the image tagged with that release's tag. The backend image
  is tagged with the release tag **and** the commit SHA, so any prior release
  is recoverable.
- **Pin a specific image**: on the VM, set `BACKEND_IMAGE` in
  `backend/.env` to a SHA tag and restart:

  ```bash
  cd ~/gym_management/backend
  # set BACKEND_IMAGE=ghcr.io/akshayishaan/gym_management/backend:<sha> in .env
  docker compose -f docker-compose.prod.yml up -d
  ```

See `docs/deployment.md` for VM setup and troubleshooting.
