#!/bin/sh
# Install the yas-webdeploy command. Deployment logic is in yas-webdeploy.
set -eu

RAW_BASE='https://raw.githubusercontent.com/emyassine/rsync-webdeploy/main'
INSTALL_DIR="${YAS_WEBDEPLOY_INSTALL_DIR:-$HOME/.local/bin}"
DEST="$INSTALL_DIR/yas-webdeploy"
LITE_DEST="$INSTALL_DIR/yas-webdeploy-lite"
say() { printf '%s\n' "yas-webdeploy installer: $*"; }
fail() { say "Error: $*" >&2; exit 1; }

mkdir -p "$INSTALL_DIR" || fail "could not create $INSTALL_DIR"
tmp_file=$(mktemp "${TMPDIR:-/tmp}/yas-webdeploy.XXXXXX") || fail 'could not create a temporary file'
trap 'rm -f "$tmp_file"' EXIT HUP INT TERM

if command -v curl >/dev/null 2>&1; then
    curl -fsSL "$RAW_BASE/yas-webdeploy" -o "$tmp_file" || fail 'download failed'
elif command -v wget >/dev/null 2>&1; then
    wget -q "$RAW_BASE/yas-webdeploy" -O "$tmp_file" || fail 'download failed'
else
    fail 'curl or wget is required'
fi
[ -s "$tmp_file" ] || fail 'downloaded command is empty'
install -m 0755 "$tmp_file" "$DEST" || fail "could not install to $DEST"
say "Installed $DEST"

lite_tmp=$(mktemp "${TMPDIR:-/tmp}/yas-webdeploy-lite.XXXXXX") || fail 'could not create a temporary file for the lite command'
if command -v curl >/dev/null 2>&1; then
    curl -fsSL "$RAW_BASE/yas-webdeploy-lite" -o "$lite_tmp" || fail 'lite command download failed'
else
    wget -q "$RAW_BASE/yas-webdeploy-lite" -O "$lite_tmp" || fail 'lite command download failed'
fi
[ -s "$lite_tmp" ] || fail 'downloaded lite command is empty'
install -m 0755 "$lite_tmp" "$LITE_DEST" || fail "could not install to $LITE_DEST"
rm -f "$lite_tmp"
say "Installed $LITE_DEST"

add_path_setup() {
    target=$1
    path_line='case ":$PATH:" in *:"$HOME/.local/bin":*) ;; *) export PATH="$HOME/.local/bin:$PATH" ;; esac'
    : >> "$target" || fail "could not update $target"
    if ! grep -Fq "$path_line" "$target"; then
        printf '\n# Added by yas-webdeploy installer\n%s\n' "$path_line" >> "$target" || fail "could not update $target"
        say "Added ~/.local/bin to PATH in $target"
    fi
}

shell_name=$(basename "${SHELL:-sh}")
case "$shell_name" in
    zsh)
        add_path_setup "$HOME/.zshrc"
        reload_hint='. "$HOME/.zshrc"'
        ;;
    bash)
        add_path_setup "$HOME/.bashrc"
        if [ "$(uname -s 2>/dev/null || true)" = Darwin ] || [ -f "$HOME/.bash_profile" ]; then
            add_path_setup "$HOME/.bash_profile"
            reload_hint='. "$HOME/.bash_profile"'
        else
            reload_hint='. "$HOME/.bashrc"'
        fi
        ;;
    *)
        add_path_setup "$HOME/.profile"
        reload_hint='. "$HOME/.profile"'
        ;;
esac
say "Open a new terminal or run: $reload_hint"
say 'Run JSON profiles with: yas-webdeploy [config.json]'
say 'Run simple KEY=value profiles with: yas-webdeploy-lite [config.conf]'
