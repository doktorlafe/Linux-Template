# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Purpose

This directory is a notes and configuration workspace for deploying **UniFi Network Application** via Docker on a Linux VPS. Work here is planning and config authoring — not executed locally (the user's machine is Windows; deployment happens on a remote Linux server).

## Key Context

- The target deployment is `lscr.io/linuxserver/unifi-network-application` paired with an external MongoDB container.
- MongoDB env vars (`MONGO_USER`, `MONGO_PASS`, `MONGO_DBNAME`, `MONGO_AUTHSOURCE`) are **only evaluated on first run** — changing them later requires recreating the containers with a clean volume.
- The `init-mongo.sh` script must be mounted into the MongoDB container's `/docker-entrypoint-initdb.d/` and only runs on a clean `/data/db` volume.

## Critical Setup Rules

- **Do not combine MongoDB and UniFi into a single service** — they must be separate containers sharing a Docker network.
- Pin the MongoDB image version (e.g. `mongo:7.0`) — never use `latest` for MongoDB; major version upgrades break data.
- MongoDB >4.4 on x86_64 requires AVX CPU support. Celeron/Pentium pre-Tiger-Lake CPUs cannot run MongoDB 5.0+; use 4.4 instead.
- Port `8080:8080` is **required** for device communication and must not be remapped.
- The `MONGO_AUTHSOURCE` must be `admin` (not the app database name).

## Correct docker-compose Structure

Two services sharing a network:

1. `unifi-db` — MongoDB with `init-mongo.sh` mounted at `/docker-entrypoint-initdb.d/init-mongo.sh:ro`
2. `unifi-network-application` — depends on `unifi-db`, with `MONGO_HOST` set to the db service name

The `init-mongo.sh` script creates a dedicated `unifi` user with `dbOwner` on `unifi`, `unifi_stat`, `unifi_audit`, and `unifi_restore` databases, authenticated against the `admin` authsource.

## Device Adoption

After deployment, go to **Settings > System > Advanced**, set **Inform Host** to the VPS's accessible IP/hostname, and check **Override**. This is required for access points and other devices to adopt correctly.
