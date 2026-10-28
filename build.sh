#!/usr/bin/env bash
# Build the Cunnit live ISO. Run as root on Debian/Ubuntu (or via build.ps1).
set -euo pipefail
SRC=${SRC:-$(cd "$(dirname "$0")" && pwd)}
WORK=${WORK:-/var/tmp/cunnit-build}
OUT=${OUT:-$SRC/out}
DIST=${DIST:-trixie}

[ "$(id -u)" -eq 0 ] || { echo "build.sh must run as root" >&2; exit 1; }

export DEBIAN_FRONTEND=noninteractive
DEPS="debootstrap debian-archive-keyring imagemagick fonts-dejavu-core curl ca-certificates
  xz-utils xorriso squashfs-tools grub-efi-amd64-bin grub-pc-bin mtools dosfstools
  syslinux syslinux-common isolinux cpio rsync"
MISSING=$(for p in $DEPS; do dpkg -s "$p" >/dev/null 2>&1 || echo "$p"; done)
if [ -n "$MISSING" ]; then
  apt-get update
  apt-get install -y --no-install-recommends $MISSING
fi

# Ubuntu ships an old live-build fork (3.0~a57) without --bootloaders etc.
# Debian's live-build is architecture-independent shell, so use that instead.
case "$(dpkg-query -W -f='${Version}' live-build 2>/dev/null)" in
  1:*) ;;
  *)
    LB_DEB=$(curl -fsSL "https://deb.debian.org/debian/dists/$DIST/main/binary-amd64/Packages.xz" \
      | xz -dc | awk '$0 == "Package: live-build" { f = 1 } f && /^Filename:/ { print $2; f = 0 }' | head -n1)
    curl -fsSLo /tmp/live-build.deb "https://deb.debian.org/debian/$LB_DEB"
    apt-get install -y /tmp/live-build.deb
    ;;
esac

# Start clean, but keep live-build's download cache so rebuilds are faster.
CACHE=${WORK}.cache
if [ -d "$WORK/cache" ]; then
  rm -rf "$CACHE"
  mv "$WORK/cache" "$CACHE"
fi
rm -rf "$WORK"
mkdir -p "$WORK" "$OUT"
[ -d "$CACHE" ] && mv "$CACHE" "$WORK/cache"
cd "$WORK"

lb config \
  --mode debian \
  --distribution "$DIST" \
  --architectures amd64 \
  --archive-areas "main contrib non-free-firmware" \
  --binary-images iso-hybrid \
  --bootloaders "syslinux,grub-efi" \
  --debian-installer live \
  --debian-installer-gui false \
  --apt-recommends false \
  --apt-indices false \
  --memtest none \
  --iso-application Cunnit \
  --iso-publisher Cunnit \
  --iso-volume CUNNIT \
  --image-name cunnit \
  --bootappend-live "boot=live components hostname=cunnit username=cunnit noautologin quiet loglevel=3"

# Our config on top of the generated one (CRLF-safe for checkouts made on Windows).
cp -r "$SRC/config/." config/
find config -type f -exec sed -i 's/\r$//' {} +
# Files copied from Windows arrive marked executable; set proper modes.
find config/includes.chroot config/includes.installer -type d -exec chmod 0755 {} +
find config/includes.chroot config/includes.installer -type f -exec chmod 0644 {} +
chmod 0755 config/includes.chroot/usr/local/sbin/* config/includes.chroot/usr/local/bin/*
chmod +x config/hooks/normal/*.hook.*

# Start from live-build's stock boot menus, then brand them.
mkdir -p config/bootloaders/isolinux
cp -rL /usr/share/live/build/bootloaders/syslinux_common/. config/bootloaders/isolinux/
cp -rL /usr/share/live/build/bootloaders/isolinux/. config/bootloaders/isolinux/
cp -rL /usr/share/live/build/bootloaders/grub-pc config/bootloaders/
tr -d '\r' < "$SRC/branding/logo.txt" > "$WORK/logo.txt"
tr -d '\r' < "$SRC/branding/make-boot-theme.sh" | bash -s -- config "$WORK/logo.txt"

lb build 2>&1 | tee "$WORK/build.log"

ISO=$(ls "$WORK"/cunnit*.iso | head -n1)
cp "$ISO" "$OUT/cunnit-$DIST-amd64.iso"
echo "Done: $OUT/cunnit-$DIST-amd64.iso"
