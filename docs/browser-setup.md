---
title: Browser Setup
description: Chrome browser setup for OpenClaw on headless Linux servers
---

# Browser Setup

The playbook installs Google Chrome with a virtual display (Xvfb) and configures it as a systemd service so OpenClaw can use browser automation on headless servers.

## What Gets Installed

- **Google Chrome** (stable) from Google's apt repository
- **Xvfb** (X Virtual Framebuffer) — provides a virtual display for Chrome to render to
- **Supporting packages** — `libxss1`, `libappindicator3-1`, `fonts-liberation`, `xdg-utils`, `dbus-x11`
- **Two systemd services** — `xvfb` and `openclaw-chrome`, enabled on boot

## How It Works

On a headless server there is no physical display, so Chrome cannot start without one. Xvfb creates a virtual 1920x1080 display on `:99` that Chrome renders to. Chrome is launched with the Chrome DevTools Protocol (CDP) enabled on port 9222, which OpenClaw connects to for browser control.

```
Xvfb (:99) → Chrome (display :99, CDP on :9222) → OpenClaw (connects via CDP)
```

## Critical Chrome Flags

These flags are required for Chrome to work correctly on a headless server:

| Flag | Why |
|------|-----|
| `--user-data-dir=<path>` | **Required.** Chrome will not enable remote debugging on the default profile. Must use a separate data directory. |
| `--remote-debugging-address=0.0.0.0` | **Required.** Binds CDP to the network interface. Without this, port 9222 won't actually listen. |
| `--remote-debugging-port=9222` | CDP port that OpenClaw connects to. |
| `--no-sandbox` | Required on most Linux servers without a full desktop environment. |
| `--disable-gpu` | No GPU available on headless servers. |
| `--no-first-run` | Skips the first-run welcome dialog. |
| `--disable-default-apps` | Skips installing default Chrome apps. |

## Services

### Xvfb

```bash
sudo systemctl status xvfb
sudo systemctl restart xvfb
```

Runs `Xvfb :99 -screen 0 1920x1080x24` as the `openclaw` user.

### Chrome

```bash
sudo systemctl status openclaw-chrome
sudo systemctl restart openclaw-chrome
```

Depends on `xvfb.service` — systemd will start Xvfb first automatically.

Chrome user data is stored at `/home/openclaw/.config/openclaw-chrome`.

## Verifying the Setup

### 1. Check services are running

```bash
sudo systemctl status xvfb openclaw-chrome
```

### 2. Check port 9222 is listening

```bash
netstat -tuln | grep 9222
# Should show: tcp  0  0  0.0.0.0:9222  0.0.0.0:*  LISTEN
```

### 3. Test CDP endpoint

```bash
curl -s http://127.0.0.1:9222/json/version
# Should return JSON with Browser, Protocol-Version, webSocketDebuggerUrl
```

## Configuring OpenClaw

After Chrome is running, configure OpenClaw to use its CDP endpoint:

```bash
openclaw gateway config.patch --raw '{"browser":{"profiles":{"openclaw":{"cdpUrl":"http://127.0.0.1:9222","color":"#4285F4"}}}}'
```

Or add to your OpenClaw config directly:

```json
{
  "browser": {
    "profiles": {
      "openclaw": {
        "cdpUrl": "http://127.0.0.1:9222",
        "color": "#4285F4"
      }
    }
  }
}
```

## Testing

```bash
# Open a URL
openclaw browser open https://example.com --profile openclaw

# Take a screenshot
openclaw browser screenshot --profile openclaw

# Get page snapshot
openclaw browser snapshot --profile openclaw
```

## Troubleshooting

### Chrome CDP times out

Check that Chrome was started with a **custom `--user-data-dir`**. Chrome silently ignores `--remote-debugging-port` when using the default profile.

```bash
ps aux | grep google-chrome | grep user-data-dir
```

### Port 9222 not listening

Check that `--remote-debugging-address=0.0.0.0` is included in the Chrome flags. Without it, Chrome won't bind the port.

### Missing X server error

```
ERROR:ui/ozone/platform/x11/ozone_platform_x11.cc:256] Missing X server or $DISPLAY
```

Xvfb is not running or Chrome doesn't have `DISPLAY=:99` set:

```bash
sudo systemctl start xvfb
sudo systemctl restart openclaw-chrome
```

### Chrome crashes on startup

Check logs:

```bash
journalctl -u openclaw-chrome -f
```

Common causes:
- Missing `--no-sandbox` flag
- Insufficient memory (Chrome needs ~200MB minimum)
- Missing X11/font packages (reinstall with the playbook)
