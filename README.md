# yas-webdeploy

Deploy static sites and web applications to a remote web server over SSH with rsync. SFTP is available for basic transfers.

## Install

```sh
curl -fsSL https://raw.githubusercontent.com/emyassine/rsync-webdeploy/main/install.sh | sh
```

The installer puts `yas-webdeploy` in `~/.local/bin` and adds that directory to the startup file for Bash or Zsh. Open a new terminal, or source the file reported by the installer.

Requirements: Bash, `jq`, `ssh`, and `rsync` for SSH deployments. SFTP deployments require `sftp`.

## Configure

Create `web-sync.config.json` in the project directory, then run `yas-webdeploy`. To use a named profile, pass its path:

```sh
yas-webdeploy earth_and_sky-web-sync.config.json
```

Relative config and source paths are resolved from the config file's directory. Config files are added to that directory's `.gitignore` when the tool runs.

Example:

```json
{
  "server": "example.com",
  "user": "deploy",
  "ssh_port": 22,
  "method": "ssh",
  "unsafe_mode": false,
  "ssh_password": "",
  "sudo_password": "",
  "remote_chown": "",
  "remote_dir_mode": "755",
  "remote_file_mode": "644",
  "remote_sudo": false,
  "remote_staging_root": "/home/deploy/.web-sync-staging",
  "deploys": {
    "site": {
      "enable": true,
      "source": "public",
      "dest": "/home/deploy/public_html",
      "type": "static"
    }
  }
}
```

`ssh_port` sets the SSH, rsync and SFTP port; it defaults to `22`. Supported deployment types are `static`, `laravel`, and `webkernel`. All enabled deployments run when invoked. Laravel and WebKernel deployments run the configured Composer and Artisan commands after transfer.

SSH keys are recommended. Password fields are ignored unless `unsafe_mode` is enabled; stored passwords are plain text. Keep credentials out of version control.

## License

MPL-2.0

**El Moumen Yassine**

## Lite mode (no `jq`)

Use `yas-webdeploy-lite` for a single SSH/rsync deployment with no JSON parser or other runtime utilities. It reads a plain text `KEY=value` profile and does not execute or source that file. Bash, `rsync`, and `ssh` are the only runtime requirements.

Earth & Sky example profile: [`earth_and_sky-web-sync.conf`](earth_and_sky-web-sync.conf). Copy it into the directory you want to deploy, or download it there from this repository. Example contents:

```ini
SERVER=145.223.39.21
USER=u320478370
SSH_PORT=65002
SOURCE=.
DEST=/home/u320478370/domains/earthandskycorp.com/public_html
```

Run it from the project directory:

```sh
curl -fsSL https://raw.githubusercontent.com/emyassine/rsync-webdeploy/main/earth_and_sky-web-sync.conf -o earth_and_sky-web-sync.conf
yas-webdeploy-lite earth_and_sky-web-sync.conf
```

The source path is relative to the profile file. Lite mode excludes `.git`, `.env`, and `.env.*`. It does not delete remote files that are absent locally.
