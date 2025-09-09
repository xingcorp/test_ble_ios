# Beacon Attendance (iOS) — Project Docs

This repository contains the planning, prompts, architecture, and sprint backlog to build a production‑grade **Beacon Attendance** app on iOS using **Core Location (iBeacon Region Monitoring)** with strong guarantees for **background/terminated** operation when user **grants Always Location** and **Background App Refresh**.

**Hardware inputs (given):**
- iBeacon UUID: `FDA50693-0000-0000-0000-290995101092`
- Major: fixed per physical beacon
- Minor: **rotates** (non‑stable)
- A site can have **multiple beacons** broadcasting simultaneously.

**Key constraints & strategy:**
- Use **Region Monitoring** (iBeacon) for reliable **enter/exit** wakeups, even when the app is **not running** (not force‑quit).
- Treat presence at **site/zone level** by UUID (+major). **Do not bind logic to `minor`** if it rotates.
- Use short **ranging bursts (5–10s)** on enter / on display wake to identify *nearest* and strengthen confidence.
- Add **"soft‑exit" prediction** (RSSI moving average + no‑packet window), but **commit** on proven exit or grace timeout.
- Add **SLCS** (Significant‑Change), optional **geofence**, server‑side **TTL/heartbeat** as fail‑safes.

See `docs/phase-1-overview.md` and `docs/phase-2-core-architecture.md` for details.
