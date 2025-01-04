Module configuring (NixOs) system configuration for bistannix.

Disks are encrypted via https://wiki.archlinux.org/title/Systemd-cryptenroll, but disko doesn't support fido2 directly so this wasn't a clean "pure" setup, I first setup with a password (support by disko) then enrolled fido tokens manually and removed the password.