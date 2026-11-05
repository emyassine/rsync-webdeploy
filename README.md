# yas-webdeploy

Deploy a site with rsync over SSH. Run it from the source machine, or use a remote source profile to relay files through the machine running `yas-webdeploy` to the destination. JSON profiles retain the full multi-deployment workflow; simple `KEY=value` profiles need no `jq`.

## Install

```sh
curl -fsSL https://raw.githubusercontent.com/emyassine/rsync-webdeploy/main/install.sh | sh
```

The installer puts one command, `yas-webdeploy`, in `~/.local/bin` and adds that directory to the startup file for Bash or Zsh.

## Simple profile (no jq)

Create a private `webdeploy.conf` outside the source directory:

```ini
# Local source to remote destination
SERVER=destination.example
USER=deploy
SSH_PORT=22
SOURCE=/path/to/site
DEST=/home/deploy/public_html
SSH_PASSWORD=

# For a remote source, use this instead of SOURCE=/path/to/site:
# SOURCE=source-user@source.example:/home/source-user/site/
# SOURCE_SSH_PORT=22
# SOURCE_SSH_PASSWORD=
```

Run it with:

```sh
yas-webdeploy ~/.config/webdeploy.conf
```

`SOURCE` may be a local directory or `user@host:/path/` on another SSH server. For a remote source, the command downloads to a temporary directory on the machine running `yas-webdeploy`, then uploads to the destination. That machine needs enough temporary disk space for the source files and network access to both SSH servers. Temporary files are removed when the command exits.

`SSH_PASSWORD` is the destination SSH password. `SOURCE_SSH_PASSWORD` is used only for a remote source. Leave either empty to use SSH keys. Passwords are stored as plain text in the profile; keep it private. Connect to each SSH host once beforehand to accept its host key.

The simple profile uses Bash, `rsync`, and `ssh`; it does not use `jq` or apply file exclusions. It does not delete remote files that are absent from the source. Relative local `SOURCE` paths are resolved from the current directory.

## JSON profile

Use a JSON profile for multiple deployment targets, SFTP, Git ignore exclusions, remote permissions, and Laravel/WebKernel post-deploy steps. JSON mode requires `jq`; SSH transfers also require `ssh` and `rsync`.

```sh
yas-webdeploy web-sync.config.json
```

The JSON schema and configuration examples are documented in the project history. SSH and sudo password fields in JSON are used only when `unsafe_mode` is enabled.


## Immediate relay mode

Run a nested JSON profile with:

```sh
yas-webdeploy --sync-without-delai web-sync.config.json
```

It checks SSH access to both endpoints before transferring and keeps those SSH control connections open. If the destination can SSH to the source with a key and both endpoints have `rsync`, it pulls directly. If that probe fails, the tool explains the detected reason and offers to relay through this machine, stop to configure direct access, or cancel. SFTP access from this machine to the destination does not mean the destination can reach the source; it still uses this machine as a relay. The relay tracks fetched and sent files under `~/.local/state/yas-webdeploy/`. Batches contain up to 32 files or about 8 MiB. Partial files and state remain after interruption so rerunning resumes the transfer. The relay needs local disk for the current batch, plus any incomplete batch being resumed. Progress reports the combined download and upload work with a live ETA. Each connection check, inventory scan, and batch transfer is timestamped, its duration is shown, and its start/end records are appended to `operations.tsv` in that run's state directory.

The nested profile uses `"schema_version": 1` and supports one enabled deployment. Set `source.kind` to `remote` with `source.server` and `source.path`, or `this_machine` with a local `source.path`. The `destination` block describes the remote target. Password values stay in the ignored local profile.

## License

MPL-2.0
