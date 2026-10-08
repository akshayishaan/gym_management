#!/bin/bash
set -euo pipefail

# ---------------------------------------------------------------------------
# Single-node MongoDB replica set initializer (entrypoint wrapper).
#
# The backend requires a transaction-capable MongoDB (ADR-0001), which means a
# replica set — a standalone mongod will reject transactions. This script:
#
#   1. Starts mongod with the args passed from the compose `command`
#      (which must include `--replSet rs0 --bind_ip_all`).
#   2. Waits until mongod answers a ping.
#   3. Runs `rs.initiate()` idempotently (safe to re-run across restarts).
#   4. Waits until the node reports PRIMARY.
#   5. Keeps mongod in the foreground so the container stays alive.
#
# The replica set member host is pinned to the compose service name (`mongo`)
# so the backend's `mongodb://mongo:27017/...?replicaSet=rs0` connection string
# resolves correctly during replica-set discovery.
# ---------------------------------------------------------------------------

REPL_SET_NAME="${REPL_SET_NAME:-rs0}"
HOST_NAME="${MONGO_HOST_NAME:-mongo}"
PORT="${MONGO_PORT:-27017}"

# The official image runs mongod as the `mongodb` user (uid 999). We run as
# root here, so make sure the data volume is writable by that user first.
mkdir -p /data/db
chown -R mongodb:mongodb /data/db

echo "[mongo-init] starting mongod: $*"
gosu mongodb mongod "$@" &
MONGO_PID=$!

echo "[mongo-init] waiting for mongod to accept connections"
until mongosh --quiet --eval "db.adminCommand('ping').ok" 2>/dev/null | grep -q 1; do
  sleep 1
done

echo "[mongo-init] initiating replica set '${REPL_SET_NAME}' (idempotent)"
mongosh --quiet --eval "
  const initiated = (() => {
    try { return rs.status().ok === 1; } catch (e) { return false; }
  })();
  if (!initiated) {
    rs.initiate({
      _id: '${REPL_SET_NAME}',
      members: [{ _id: 0, host: '${HOST_NAME}:${PORT}' }],
    });
  }
"

echo "[mongo-init] waiting for node to become PRIMARY"
until mongosh --quiet --eval "rs.status().members.some(m => m.stateStr === 'PRIMARY')" 2>/dev/null | grep -q true; do
  sleep 1
done

echo "[mongo-init] replica set '${REPL_SET_NAME}' is PRIMARY — ready"

# Keep mongod in the foreground; if it exits, propagate its exit code.
wait "${MONGO_PID}"
