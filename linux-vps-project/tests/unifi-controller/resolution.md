# UniFi Network Application — Correct Docker Setup

## The Problem

The "wrong password" error happens when MongoDB and the UniFi app are misconfigured together — usually because:
- The init script never ran (MongoDB was started without a clean `/data/db`)
- `MONGO_AUTHSOURCE` was set incorrectly
- The env vars were changed after UniFi's first run (they are only read once)
- `MONGO_USER` / `MONGO_PASS` in the init script don't match what the UniFi container expects

---

## File Structure on the VPS

```
/opt/docker-data/unifi/
├── mongo/          ← MongoDB data volume
└── config/         ← UniFi config volume

~/unifi/            ← your compose project directory
├── docker-compose.yml
└── init-mongo.js
```

Create the data directories first:

```bash
sudo mkdir -p /opt/docker-data/unifi/mongo
sudo mkdir -p /opt/docker-data/unifi/config
```

---

## Step 1 — Create `init-mongo.js`

This JavaScript file runs **once** when MongoDB starts on a **clean** `/data/db`. It creates the dedicated UniFi user with the correct roles.

> **Important:** The credentials here must exactly match `MONGO_USER` and `MONGO_PASS` in your `docker-compose.yml`.

```js
db = db.getSiblingDB("admin");
db.auth("root", "StrongRootPassword");   // must match MONGO_INITDB_ROOT_PASSWORD

db = db.getSiblingDB("unifi");
db.createUser({
  user: "unifi",
  pwd: "CHANGE_ME_UNIFI_PASS",           // must match MONGO_PASS in unifi-network-application
  roles: [
    { role: "dbOwner", db: "unifi" },
    { role: "dbOwner", db: "unifi_stat" },
    { role: "dbOwner", db: "unifi_audit" },
    { role: "dbOwner", db: "unifi_restore" },
    { role: "clusterMonitor", db: "admin" }
  ]
});
```

---

## Step 2 — Create `docker-compose.yml`

Replace `StrongRootPassword` and `CHANGE_ME_UNIFI_PASS` with real passwords. Keep them consistent between the two services.

```yaml
services:

  unifi-db:
    image: mongo:7.0                    # pin version — never use latest
    container_name: unifi-db
    environment:
      MONGO_INITDB_ROOT_USERNAME: root
      MONGO_INITDB_ROOT_PASSWORD: StrongRootPassword    # change this
    volumes:
      - /opt/docker-data/unifi/mongo:/data/db
      - ./init-mongo.js:/docker-entrypoint-initdb.d/init-mongo.js:ro
    restart: unless-stopped
    healthcheck:
      test: ["CMD", "mongosh", "--quiet", "--eval", "db.adminCommand('ping').ok"]
      interval: 30s
      timeout: 10s
      retries: 5
      start_period: 60s

  unifi-network-application:
    image: lscr.io/linuxserver/unifi-network-application:latest
    container_name: unifi-network-application
    depends_on:
      unifi-db:
        condition: service_healthy      # waits for MongoDB to be ready
    environment:
      PUID: 1000
      PGID: 1000
      TZ: Europe/Warsaw                 # set your timezone
      MONGO_USER: unifi
      MONGO_PASS: CHANGE_ME_UNIFI_PASS  # must match init-mongo.js
      MONGO_HOST: unifi-db              # service name, not an IP
      MONGO_PORT: 27017
      MONGO_DBNAME: unifi
      MONGO_AUTHSOURCE: admin
    volumes:
      - /opt/docker-data/unifi/config:/config
    ports:
      - "8443:8443"       # web UI (HTTPS)
      - "8080:8080"       # device communication — do NOT remap this port
      - "3478:3478/udp"   # STUN
      - "10001:10001/udp" # AP discovery
    restart: unless-stopped
```

---

## Step 3 — Deploy

```bash
cd ~/unifi

# Start both — UniFi will wait automatically until MongoDB is healthy
docker compose up -d
```

Check logs:

```bash
docker logs unifi-db --tail 30
docker logs unifi-network-application --tail 30
```

Access the web UI at: **`https://<your-vps-ip>:8443`**

Use the first-run wizard to finish setup (or restore a backup here).

---

## Step 4 — Device Adoption (Access Points etc.)

By default UniFi advertises an internal Docker IP that your devices cannot reach. Fix this:

1. Go to **Settings > System > Advanced**
2. Set **Inform Host** to your VPS's public/LAN IP or hostname
3. Check the **Override** box
4. Save

For manual adoption via SSH on the device:

```bash
ssh ubnt@<AP-IP>          # default password: ubnt
set-inform http://<VPS-IP>:8080/inform
```

---

## If You Already Started MongoDB Without the Init Script

The init script only runs on a **clean** volume. If you started MongoDB before mounting `init-mongo.js`, you must reset:

```bash
docker compose down
sudo rm -rf /opt/docker-data/unifi/mongo/*
docker compose up -d
```

This wipes the MongoDB data. If you also have UniFi config data you want to keep, you can restore it from a backup through the first-run wizard.

---

## Common Pitfalls

| Symptom | Cause | Fix |
|---|---|---|
| "Wrong password" on startup | Init script never ran, or passwords mismatched | Wipe `mongo/`, restart — see section above |
| Init script ran but user missing | `db-data/` was not empty on first start | Same fix: wipe volume, restart |
| UniFi ignores changed `MONGO_*` vars | Only read on first run | Wipe `/opt/docker-data/unifi/config/` too, redo wizard |
| Devices can't adopt | Inform Host still points to internal Docker IP | Set Inform Host override (Step 4) |
| MongoDB won't start (x86) | CPU lacks AVX — older Celeron/Pentium | Use `mongo:4.4` instead |
| Port conflict on `8080` | Another service using it | Free the port — UniFi hardcodes `8080` internally |
