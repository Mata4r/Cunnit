# Cunnit

Cunnit is a Debian Linux based operating system designed to function as a server.

A light, CLI-only server OS based on Debian 13 (trixie), with Docker and Kubernetes (k3s) already installed. Boot it live from USB or a VM, or install it to disk.

- Custom boot menus (BIOS and UEFI) with the Cunnit logo in light green
- At login the screen clears and shows the Cunnit logo in light green, a thick green bar under it, then the shell prompt
- SSH server with password login; a new password is required on first login
- Host firewall: only SSH (22), web (80, 443), Kubernetes API (6443) and NodePorts (30000-32767) are open
- Automatic security updates
- Docker + docker-compose run at boot; the `cunnit` user is in the `docker` group
- k3s (Kubernetes) is installed but starts only when you ask for it, so idle RAM use stays low
- `tdo` is the admin command, used in place of `sudo`, and asks for your password
- VMware guest tools included
- Wi-Fi with `EnableWiFi` / `StopWiFi`, plus `ifconfig` for those used to it

## Build

You need about 5 GB free disk space and an internet connection.

**Windows** (needs Docker Desktop running Linux containers):

```powershell
.\build.ps1
```

**Debian / Ubuntu / WSL**:

```bash
sudo bash build.sh
```

The ISO is written to `out/cunnit-trixie-amd64.iso`. Write it to a USB stick with Rufus (DD image mode), balenaEtcher or `dd`, or boot it in a VM.

## First login (live mode)

1. The console shows the server's IP address above the login prompt.
2. Log in as `cunnit` with password `live`, on the console or over SSH:
   ```bash
   ssh cunnit@<ip-address>
   ```
3. You are asked for the current password (`live`), then a new one twice.
4. Log in again with the new password.

In live mode everything runs from RAM, so the password goes back to `live` (and must be changed again) after every reboot.

## Install to disk

Pick **Install** in the boot menu. The installer asks for the disk, timezone and the `cunnit` user's password. After installing, the server keeps its data, Docker images and k3s cluster across reboots, and the password you chose is the one you use.

## Using it

```bash
docker run --rm hello-world
tdo systemctl start k3s      # start Kubernetes
kubectl get nodes            # ready after about 30 s
tdo systemctl enable k3s     # optional: start k3s at every boot
```

## Wi-Fi

Wired networks connect automatically. Wi-Fi is off until you turn it on:

```bash
EnableWiFi                    # turn Wi-Fi on and list nearby networks
EnableWiFi "My Network"       # connect; asks for the Wi-Fi password
StopWiFi                      # disconnect and switch the Wi-Fi radio off
```

Both ask for your password (they run through `tdo`). On an installed system, Wi-Fi and saved networks stay on across reboots until you run `StopWiFi`. In live mode they are lost on reboot.

## Firewall

To open another port in the firewall, edit `/etc/nftables.conf` and run `tdo systemctl reload nftables`.

## Layout

| Path | Purpose |
|---|---|
| `build.sh` | Runs live-build, adds the config and branding, writes the ISO |
| `build.ps1` | Runs `build.sh` inside a `debian:trixie` container |
| `branding/logo.txt` | The logo used by the boot menus |
| `branding/make-boot-theme.sh` | Draws the boot splash images and brands the ISOLINUX and GRUB menus |
| `config/package-lists/` | Packages installed (no recommended packages, to keep it small) |
| `config/hooks/normal/0500-cunnit.hook.chroot` | Installs k3s, sets up `tdo`, the prompt and services |
| `config/includes.chroot/etc/profile.d/zz-cunnit-banner.sh` | The green login logo |
| `config/includes.chroot/etc/nftables.conf` | Firewall rules |
| `config/includes.chroot/etc/ssh/sshd_config.d/cunnit.conf` | SSH policy |
| `config/includes.chroot/usr/local/sbin/cunnit-live-secure` | Live mode: removes password-less `tdo`, forces a new password |
| `config/includes.chroot/usr/local/bin/EnableWiFi`, `StopWiFi` | Wi-Fi on/off commands |
| `config/includes.installer/preseed.cfg` | Default answers for the disk installer |
