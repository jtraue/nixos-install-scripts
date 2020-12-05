#! /usr/bin/env bash

# Script to install NixOS from the Hetzner Cloud NixOS bootable ISO image.
# (tested with Hetzner's `NixOS 20.03 (amd64/minimal)` ISO image).
# 
# This script wipes the disk of the server!
#
# Instructions:
#
# 1. Mount the above mentioned ISO image from the Hetzner Cloud GUI
#    and reboot the server into it; do not run the default system (e.g. Ubuntu).
# 2. To be able to SSH straight in (recommended), you must replace hardcoded pubkey
#    further down in the section labelled "Replace this by your SSH pubkey" by you own,
#    and host the modified script way under a URL of your choosing
#    (e.g. gist.github.com with git.io as URL shortener service).
# 3. Run on the server:
#
#       # Replace this URL by your own that has your pubkey in
#       curl -L https://raw.githubusercontent.com/jtraue/nixos-install-scripts/master/hosters/hetzner-cloud/nixos-install-hetzner-cloud.sh | sudo bash
# 4. Unmount the ISO image from the Hetzner Cloud GUI.
# 5. Reboot.
#
# To run it from the Hetzner Cloud web terminal without typing it down,
# you can either select it and then middle-click onto the web terminal, (that pastes
# to it), or use `xdotool` (you have e.g. 3 seconds to focus the window):
#
#     sleep 3 && xdotool type --delay 50 'curl YOUR_URL_HERE | sudo bash'
#
# (In the xdotool invocation you may have to replace chars so that
# the right chars appear on the US-English keyboard.)
#
# If you do not replace the pubkey, you'll be running with my pubkey, but you can
# change it afterwards by logging in via the Hetzner Cloud web terminal as `root`
# with empty password.

set -e

# Hetzner Cloud OS images grow the root partition to the size of the local
# disk on first boot. In case the NixOS live ISO is booted immediately on
# first powerup, that does not happen. Thus we need to grow the partition
# by deleting and re-creating it.
sgdisk -d 1 /dev/sda
sgdisk -N 1 /dev/sda
partprobe /dev/sda

mkfs.ext4 -F /dev/sda1 # wipes all data!

mount /dev/sda1 /mnt

nixos-generate-config --root /mnt

# Delete trailing `}` from `configuration.nix` so that we can append more to it.
sed -i -E 's:^\}\s*$::g' /mnt/etc/nixos/configuration.nix

# Extend/override default `configuration.nix`:
echo '
  boot.loader.grub.devices = [ "/dev/sda" ];

  # Initial empty root password for easy login:
  users.users.root.initialHashedPassword = "";
  services.openssh.permitRootLogin = "prohibit-password";

  services.openssh.enable = true;

  # Replace this by your SSH pubkey
  users.users.root.openssh.authorizedKeys.keys = [
    "ssh-rsa
    AAAAB3NzaC1yc2EAAAADAQABAAACAQC3aaJrBJCJQIQ0nqU9qxcrqSm9aKMcOo4kc7DG66RtzVvHFtFhuRPBWxxeF4Qz2+syFvjtXf1VjuiAFDx0PH29jAbjHZct8EjEaIPcczDxz2xR/zREqgjUKzk5mvK8vv01LHHmJc5wnc5G8WhqZDfi+MG5sfQ/noGe6AartulB0lqP3dhZNSXM+7rI+R51HwKtrUI6ryIcqrDyLliCx35k/1K0gZhDpmjD1EVkxHuHg8pbarGTTw+vZYqMO3GYrDMmGslFx65GpAujj++fOenzpAy4q5Uc5mxiYXG/DEwxr+rsaLKdCjSwSApVcdRaOQX2+FN2MQoxpPXzaM2Ynf3/AcbYqR7XlxcMAW1Wy4xcJXeXyDryu1NzyenupojbkCqo1+xPPh2cUDvEpZ5Lk5U5x9cl2vhrSVqqfQCdbhSfcq8aReNvGPo6e+PkxaMorbXOAeylVpPxhH+VMWD9tGUMK6kjOOavi86vy8L4i/C2rsyiGUNlsv1PxY7ek6jj3Rk3+hHbu5dNk/IUfZDHksVvrlMLwm/Et8cW8HqwUTQ+qTIs05ZK0+rnv5PRrKxUKPuwCDN+ngU5yyY7T3D/dZNWTVHU/PLmSCVL+QvWKv877qX5QDwrfoRPzTpIYWdEbfy5cq9dqxVmpiAVBqoDbJyd23wQ8MJups18lHZu8kkxeQ==
    cardno:000607407593"
  ];
}
' >> /mnt/etc/nixos/configuration.nix

nixos-install --no-root-passwd

reboot
