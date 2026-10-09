# gnome-display-join

GNOME (Wayland) helpers to switch a **laptop + external display** between
**join (extend)** and **mirror**, each bound to a keyboard shortcut, with
per-monitor scaling.

Built and verified on GNOME Shell 50 (Wayland). Uses `gdctl` from
`mutter-common-bin`; no `xrandr` / `wmctrl`.

## Scripts

| Script | Shortcut | Layout | Scaling |
| --- | --- | --- | --- |
| `bin/display-join` | `Super+J` | Extend: external placed to the right of the built-in | built-in **100%** (primary), external **200%** |
| `bin/display-mirror` | `Super+M` | Mirror: both show the same image at 1920x1080 | default |

Both append a timestamped log (including the `gdctl` exit code) to
`/tmp/display-join.log` and `/tmp/display-mirror.log`, so a shortcut that
appears to "do nothing" can be verified.

## Requirements

- GNOME Shell on Wayland (tested: Shell 50.1).
- `gdctl`:

  ```bash
  command -v gdctl || sudo apt install mutter-common-bin
  ```

## Install

```bash
./install.sh
```

The installer:

1. Copies the scripts to `~/.local/bin` (override the prefix with
   `PREFIX=/some/prefix ./install.sh`).
2. Registers two GNOME custom keybindings: `Super+J` → join, `Super+M` → mirror.

It is idempotent: re-running updates the same entries, and it does **not**
create a duplicate entry if an accelerator is already used by another
shortcut — it prints `SKIP` and leaves the existing binding alone.

Manual install:

```bash
install -Dm755 bin/display-join   ~/.local/bin/display-join
install -Dm755 bin/display-mirror ~/.local/bin/display-mirror
```

Manual keybinding (GNOME Custom Shortcut):

```bash
BK=/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings
gsettings set org.gnome.settings-daemon.plugins.media-keys.custom-keybinding:$BK/display-join/ name    "Display Join"
gsettings set org.gnome.settings-daemon.plugins.media-keys.custom-keybinding:$BK/display-join/ command "$HOME/.local/bin/display-join"
gsettings set org.gnome.settings-daemon.plugins.media-keys.custom-keybinding:$BK/display-join/ binding "<Super>j"
```

After adding a new entry, register its path in the
`org.gnome.settings-daemon.plugins.media-keys` `custom-keybindings` list (the
`install.sh` script does this for you).

## Adjusting connectors and scales

The connector names (`eDP-1`, `HDMI-1`) and modes are machine-specific. List
yours with:

```bash
gdctl show          # current configuration
gdctl show --modes  # modes and supported scales per monitor
```

Then edit the `gdctl set` line in `bin/display-join` (or `bin/display-mirror`).

Scale note: in `gdctl`, omitting `--scale` uses the monitor's **preferred**
scale. Set `--scale` explicitly to pin it. The requested scale must be
supported by the monitor and its chosen mode (see `gdctl show --modes`).

## Verify

```bash
gdctl show | sed -n '/Logical monitors/,$p'
```

Expected after `Super+J` — two logical monitors:

- #1: `eDP-1`, primary, scale `1.0`
- #2: `HDMI-1`, scale `2.0`, positioned right of `eDP-1`

## Troubleshooting

Confirm the shortcut actually fired:

```bash
journalctl --user -b --no-pager | grep -a "launched by gsd-media-keys"
tail -n 20 /tmp/display-join.log
```

If the log shows `exit=0` but nothing changed visually, the layout was
probably already in that state — these commands are idempotent.

Check for conflicting accelerators:

```bash
gsettings list-recursively | grep -i "<Super>j"
```
