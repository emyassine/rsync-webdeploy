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
