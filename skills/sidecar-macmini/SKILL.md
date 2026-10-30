# Skill: Mac mini + iPad Sidecar Automation

> **Last updated:** 2026-10-27
> **Platform:** macOS 27.0.1 (Apple Silicon / M4 Pro)
> **Node:** Lam's Mac mini (Lam的Mac mini)

## Overview

This skill documents the complete setup for controlling macOS Sidecar on a **Mac mini WITHOUT physical display output**.

### Architecture

```
Mac mini (no HDMI)
  └── Crisp → Creates virtual display (HiDPI, 4:3 ratio)
        └── macOS recognizes virtual display → Allows Sidecar
              └── sidecar-connect → Connects iPad as Sidecar display
```

**Key insight:** macOS blocks Sidecar when no physical display is connected. **Crisp** creates a **virtual display** in memory, tricking macOS into allowing Sidecar. Crisp's virtual display **persists even when iPad disconnects** (unlike BetterDisplay).

## Installed Tools

### 1. `sidecar-connect` (v0.2.0)

- **Location:** `~/.local/bin/sidecar-connect`
- **Source:** https://github.com/say-michael/sidecar-connect (Swift CLI, MIT licensed)
- **Purpose:** Command-line control of macOS Sidecar (connect/disconnect/list/status/watch)
- **Build:** Requires Xcode CLI tools (Swift 6+). Build: `git clone; make; make install PREFIX="$HOME/.local"`

### 2. `crispctl` (from Crisp v1.7.1)

- **Location:** `~/.local/bin/crispctl`
- **Source:** https://github.com/didriksg/Crisp (Open Source, 100% free)
- **Purpose:** CLI control of Crisp for display management (list, brightness, presets, disconnect/reconnect)
- **Built into:** `/Applications/Crisp.app/Contents/MacOS/crispctl`
- **Features:** Sharp HiDPI scaling, DDC brightness, virtual displays, presets — **all free**

### 3. Crisp (v1.7.1)

- **Location:** `/Applications/Crisp.app`
- **Source:** https://github.com/didriksg/Crisp (Open Source, 100% free, no Pro tier)
- **Purpose:** Creates and manages virtual displays that macOS recognizes, enabling Sidecar on headless Mac mini
- **Process:** `/Applications/Crisp.app/Contents/MacOS/Crisp`
- **Key advantage over BetterDisplay:** Virtual display **persists when iPad disconnects** — Sidecar can reconnect without recreating the virtual display
- **Why chosen over BetterDisplay:** Free custom resolution support (BetterDisplay Pro required for this)

## Quick Reference Commands

| Command | Purpose |
|---------|---------|
| `sidecar-connect list` | List nearby/connected Sidecar devices |
| `sidecar-connect connect` | Connect iPad as Sidecar display |
| `sidecar-connect disconnect` | Disconnect Sidecar |
| `sidecar-connect toggle` | Connect/disconnect toggle |
| `sidecar-connect status` | Check connection state (exit 0 = connected, 3 = not) |
| `sidecar-connect status --json` | JSON output for scripting |
| `sidecar-connect watch [name]` | Auto-reconnect mode (runs forever) |
| `sidecar-connect connect --no-sidebar` | Connect without sidebar |
| `crispctl display list` | List displays managed by Crisp (JSON) |
| `crispctl brightness set <display> <value>` | Set display brightness |
| `crispctl preset apply <name>` | Apply a Crisp preset |

## Workflow: Full Connection

### Step 1: Verify Crisp is creating a virtual display

```bash
system_profiler SPDisplaysDataType 2>&1 | grep -A25 "Displays:" | head -30
```

Expected output: Two displays shown:
- **Main Display** — Mac mini built-in display (e.g., 1920 x 1080 or 2360 x 1640)
- **Sidecar Display** — iPad as AirPlay device

### Step 2: Verify Crisp is running

```bash
ps aux | grep -i "Crisp" | grep -v grep
```

Expected: Crisp process running (PID visible).

### Step 3: Connect iPad

```bash
~/.local/bin/sidecar-connect connect 2>&1
```

Expected: "Connected." (exit code 0)

### Step 4: Verify connection

```bash
~/.local/bin/sidecar-connect status 2>&1
# OR
~/.local/bin/sidecar-connect status --json 2>&1
```

Expected: `"connected" : true` (exit code 0)

### Step 5: Verify system state

```bash
# Check display list (should show 2 displays)
system_profiler SPDisplaysDataType 2>&1 | grep -A25 "Displays:" | head -30

# Check SidecarRelay socket (should show TCP connection)
for pid in $(pgrep -f SidecarRelay 2>/dev/null); do
    lsof -p $pid 2>/dev/null | grep -E "IPv4|IPv6|tcp" | head -10
done
```

## Troubleshooting

### Problem: `connect` returns "Connected." but status shows "not connected"

**Cause:** No virtual display exists. macOS blocks Sidecar when no display output is active.

**Fix:**
1. Check: `system_profiler SPDisplaysDataType 2>&1 | grep -A25 "Displays:" | head -30`
2. If only 1 display (Mac mini main): Crisp is NOT creating a virtual display
3. Launch Crisp via UI: `open /Applications/Crisp.app`
4. Manually create a virtual display (4:3, 1920x1080 or matching iPad)
5. Then run: `sidecar-connect connect`

### Problem: iPad connects then disconnects when resizing

**Cause:** Changing iPad's display aspect ratio in Crisp triggers an immediate re-setup. If the new ratio is wrong, Sidecar fails.

**Fix:**
- Keep iPad's aspect ratio at **4:3** in both Crisp virtual screen settings AND iPad display settings
- Match the virtual display resolution (e.g., 2360 x 1640 → 1060 x 714 @ 60Hz)

### Problem: Crisp returns error when managing displays

**Cause:** Crisp must be running and have proper permissions.

**Fix:**
1. Launch Crisp: `open /Applications/Crisp.app`
2. Ensure "Command Line Tool" is enabled in Crisp Settings (links `crispctl` to `/usr/local/bin`)
3. Check: `~/.local/bin/crispctl display list 2>&1`

### Problem: System restarts and tools disappear

**Note:** Crisp and sidecar-connect are installed on disk (`/Applications/Crisp.app` and `~/.local/bin/`). They **persist** across reboots. However:
- Crisp must be **launched** to create the virtual display
- SidecarRelay must be **running** (auto-starts on macOS)

**Ensure Crisp launches at startup:**
- Add Crisp to macOS Login Items (System Settings → General → Login Items)

## Emergency Recovery

If everything is broken after a system restart:

```bash
# 1. Launch Crisp
open /Applications/Crisp.app
sleep 5

# 2. Verify virtual display exists
system_profiler SPDisplaysDataType 2>&1 | grep -A25 "Displays:" | head -30

# 3. Check Crisp is running
ps aux | grep -i "Crisp" | grep -v grep

# 4. Check SidecarRelay
pgrep -f SidecarRelay 2>/dev/null && echo "SidecarRelay: running" || echo "SidecarRelay: NOT running"

# 5. Create virtual display (manual, through Crisp UI if needed)
# 6. Connect iPad
~/.local/bin/sidecar-connect connect 2>&1

# 7. Verify
~/.local/bin/sidecar-connect status 2>&1
```

## Historical Context

**2026-10-27:** Set up by Lam (Alexlammm) for headless Mac mini (Apple M4 Pro, macOS 27.0.1, build 26A434). iPad: "Alex的iPad" (Pro, ~12.9-inch). Resolution: 2120 x 1428 (UI 1060 x 714 @ 60Hz), 4:3 aspect ratio.

**2026-10-28:** Fixed `web_search` tool not found error by removing broken `"openaiCodex": {}` from `tools.web.search` in `openclaw.json`. See below for details.

### Why Crisp over BetterDisplay?

BetterDisplay was the initial choice, but:
- BetterDisplay's custom resolution feature requires **Pro tier** (paid)
- Crisp is **100% free** with all features including custom resolution
- Crisp's virtual display **persists when iPad disconnects** (BetterDisplay's vanished)
- BetterDisplay has been completely removed from this setup

## References

- sidecar-connect: https://github.com/say-michael/sidecar-connect
- Crisp: https://github.com/didriksg/Crisp
- sidecarctl (alternative): https://github.com/tsilenzio/sidecarctl
- SidecarKeeper (auto-reconnect): https://github.com/EMOEMOJAI/SidecarKeeper

## Additional Notes: web_search Fix

**Problem:** `web_search` tool returns "Tool web_search not found" repeatedly.

**Root Cause:** An empty `"openaiCodex": {}` in `openclaw.json`'s `tools.web.search` breaks tool registration (OpenClaw source code: `codex-native-web-search.shared` reads `config?.tools?.web?.search?.openaiCodex`; empty object causes registration failure).

**Fix (applied 2026-10-28):**
```json
// Before (broken):
"web": {
  "search": {
    "provider": "searxng",
    "enabled": true,
    "openaiCodex": {}
  }
}

// After (fixed):
"web": {
  "search": {
    "provider": "searxng",
    "enabled": true
  }
}
```
After editing, restart the OpenClaw Gateway for the change to take effect.
