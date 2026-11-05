#!/bin/sh
# Install the yas-webdeploy command. Deployment logic is in yas-webdeploy.
set -eu

RAW_BASE='https://raw.githubusercontent.com/emyassine/rsync-webdeploy/bf31ec8491914662ce83b14f1e48b0df66cfd2f1'
EXPECTED_VERSION='2026.11.05-6'
INSTALL_DIR="${YAS_WEBDEPLOY_INSTALL_DIR:-$HOME/.local/bin}"
DEST="$INSTALL_DIR/yas-webdeploy"
say() { printf '%s\n' "yas-webdeploy installer: $*"; }
fail() { say "Error: $*" >&2; exit 1; }

mkdir -p "$INSTALL_DIR" || fail "could not create $INSTALL_DIR"
tmp_file=$(mktemp "$INSTALL_DIR/.yas-webdeploy.XXXXXX") || fail 'could not create a temporary file'
trap '[ -z "$tmp_file" ] || rm -f "$tmp_file"' EXIT HUP INT TERM

if command -v curl >/dev/null 2>&1; then
    curl -fsSL "$RAW_BASE/yas-webdeploy?v=$EXPECTED_VERSION" -o "$tmp_file" || fail 'download failed'
elif command -v wget >/dev/null 2>&1; then
    wget -q "$RAW_BASE/yas-webdeploy?v=$EXPECTED_VERSION" -O "$tmp_file" || fail 'download failed'
else
    fail 'curl or wget is required'
fi
[ -s "$tmp_file" ] || fail 'downloaded command is empty'
grep -Fqx "YAS_WEBDEPLOY_VERSION='$EXPECTED_VERSION'" "$tmp_file" || fail 'downloaded command version does not match installer'
chmod 0755 "$tmp_file" || fail 'could not make downloaded command executable'
mv -f "$tmp_file" "$DEST" || fail "could not replace $DEST"
tmp_file=''
say "Installed $DEST (version $EXPECTED_VERSION)"

if [ -e "$INSTALL_DIR/yas-webdeploy-lite" ]; then
    unlink "$INSTALL_DIR/yas-webdeploy-lite"
    say 'Removed the separate legacy yas-webdeploy-lite command'
fi

add_path_setup() {
    target=$1
    path_line='case ":$PATH:" in *:"$HOME/.local/bin":*) ;; *) export PATH="$HOME/.local/bin:$PATH" ;; esac'
    : >> "$target" || fail "could not update $target"
    if ! grep -Fq "$path_line" "$target"; then
        printf '\n# Added by yas-webdeploy installer\n%s\n' "$path_line" >> "$target" || fail "could not update $target"
        say "Added ~/.local/bin to PATH in $target"
    fi
    if ! grep -Fqx 'hash -r 2>/dev/null || true' "$target"; then
        printf '%s\n' 'hash -r 2>/dev/null || true' >> "$target" || fail "could not update $target"
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
say 'Run JSON or KEY=value profiles with: yas-webdeploy [profile]'
