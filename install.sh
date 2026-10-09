#!/usr/bin/env bash
set -euo pipefail

SCHEMA="org.gnome.settings-daemon.plugins.media-keys"
BK="/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings"

repo_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
bin_dir="${PREFIX:-$HOME/.local}/bin"

install -Dm755 "$repo_dir/bin/display-join"   "$bin_dir/display-join"
install -Dm755 "$repo_dir/bin/display-mirror" "$bin_dir/display-mirror"
echo "Installed: $bin_dir/display-join"
echo "Installed: $bin_dir/display-mirror"

entries() {
    gsettings get "$SCHEMA" custom-keybindings 2>/dev/null \
        | grep -o "/[^']*/" | sed 's:/$::' || true
}

binding_of() {
    gsettings get "$SCHEMA.custom-keybinding:$1/" binding 2>/dev/null | tr -d "'"
}

owner_of() {
    local p
    for p in $(entries); do
        if [ "$(binding_of "$p")" = "$1" ]; then
            printf '%s\n' "$p"
            return 0
        fi
    done
    return 1
}

append_entry() {
    local path="$1" cur new
    cur="$(gsettings get "$SCHEMA" custom-keybindings)"
    cur="${cur/@as []/[]}"
    if [ "$cur" = "[]" ]; then
        new="['$path']"
    else
        new="$(printf '%s' "$cur" | sed "s|]\$|, '$path']|")"
    fi
    gsettings set "$SCHEMA" custom-keybindings "$new"
}

bind() {
    local key="$1" label="$2" cmd="$3" accel="$4" path="$BK/$1" owner
    if ! entries | grep -qxF "$path"; then
        if owner="$(owner_of "$accel")"; then
            echo "SKIP  $label: $accel already used by $owner"
            return 0
        fi
        append_entry "$path"
    fi
    gsettings set "$SCHEMA.custom-keybinding:$path/" name "$label"
    gsettings set "$SCHEMA.custom-keybinding:$path/" command "$cmd"
    gsettings set "$SCHEMA.custom-keybinding:$path/" binding "$accel"
    echo "OK    $label -> $accel ($cmd)"
}

bind "display-join"   "Display Join"   "$bin_dir/display-join"   "<Super>j"
bind "display-mirror" "Display Mirror" "$bin_dir/display-mirror" "<Super>m"

echo
echo "Done. Test with Super+J (join) and Super+M (mirror)."
