# Edit this configuration file to define what should be installed on
# your system. Help is available in the configuration.nix(5) man page, on
# https://search.nixos.org/options and in the NixOS manual (`nixos-help`).

{
  config,
  lib,
  pkgs,
  self,
  inputs,
  ...
}:

let
  commonUserConfig = {
    # via mkpasswd
    # TODO this could use hashedPasswordFile
    hashedPassword = "$y$j9T$b6nmy2WZ6DxfKozDeSCM20$bs/3HW99ABTmjx/9gp62oDKIDzKn.MNOJv5VTa0Wj29";
    openssh.authorizedKeys.keys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIOcwoGu0XU3mowLSe+OwsiRwTEXGYtzOD52hRiGNznJe ndumazet@bistanclaque.local"
    ];
  };
in
{
  imports = [
    ./agenix-rekey.nix
    ./nix.nix
    inputs.impermanence.nixosModules.impermanence
  ];

  system.stateVersion = "24.11";

  boot.initrd = {
    # not very intuitively, this is actually _merged_ with the modules enabled in qemu-guest
    availableKernelModules = [
      "ata_piix"
      "floppy"
      "sd_mod"
      "sr_mod"
    ];

    systemd.enable = true;
  };

  # Enables DHCP on each ethernet and wireless interface. In case of scripted networking
  # (the default) this is the recommended approach. When using systemd-networkd it's
  # still possible to use this option, but it's recommended to use it in conjunction
  # with explicit per-interface declarations with `networking.interfaces.<interface>.useDHCP`.
  networking.useDHCP = lib.mkDefault true;

  boot.loader.efi.canTouchEfiVariables = true;
  # TODO: I would technically prefer refind (for prettiness), but no
  # declarative way to expose generations for now.
  boot.loader.grub.enable = false;
  boot.loader.systemd-boot = {
    enable = true;
    configurationLimit = 10;
    editor = false;
  };
  # highlight last booted
  boot.loader.systemd-boot.extraInstallCommands = ''
    ${pkgs.gnused}/bin/sed -i 's/default nixos-generation-[0-9][0-9].conf/default @saved/g' /boot/loader/loader.conf
  '';

  environment.persistence."/persist" = {
    hideMounts = true;
    directories = [
      # TODO: find some location for configs. With flake I have no reason to
      # have configs there.
      # "/etc/nixos"
      "/etc/ssh"
      # I originally only preserved the fish_history file in this directory but
      # this created noise due to
      # https://github.com/fish-shell/fish-shell/issues/10730
      "/root/.local/share/fish"
      "/var/cache"
      "/var/db/sudo"
      "/var/lib"
      "/var/log"
    ];
    files = [
      "/etc/machine-id"
      "/etc/nix/id_rsa"
    ];
  };

  environment.sessionVariables = {
    XDG_CACHE_HOME = "$HOME/.cache";
    XDG_CONFIG_HOME = "$HOME/.config";
    XDG_DATA_HOME = "$HOME/.local/share";
    XDG_STATE_HOME = "$HOME/.local/state";
  };

  time.timeZone = "Europe/Zurich";
  i18n.defaultLocale = "en_GB.UTF-8";

  services.xserver = {
    enable = true;
    displayManager.gdm.enable = true;
    desktopManager.gnome.enable = true;

    # Configure keymap in X11
    xkb.layout = "us";
    # xkb.options = "eurosign:e,caps:escape";
  };

  # Enable sound.
  # hardware.pulseaudio.enable = true;
  # OR
  services.pipewire = {
    enable = true;
    pulse.enable = true;
  };

  services.openssh.enable = true;
  # services.openssh.openFirewall is true by default.

  nixpkgs.hostPlatform = "x86_64-linux";
  # https://nixos.wiki/wiki/Automatic_system_upgrades
  system.autoUpgrade = {
    enable = true;
    flake = self.outPath;
    flags = [
      "--update-input"
      "nixpkgs"
      "-L" # print build logs
    ];
    dates = "02:00";
    randomizedDelaySec = "45min";
  };

  # I spent too much time on this but those are settings for the system integration of
  # home-manager, thus belong in nixconfiguration.
  home-manager = {
    useGlobalPkgs = true;
    useUserPackages = true;
    # Before overwriting a non-managed file, move it to .backup
    backupFileExtension = "backup";
  };

  users = {
    defaultUserShell = pkgs.fish;
    mutableUsers = false;

    users = {
      ndumazet = (
        commonUserConfig
        // {
          isNormalUser = true;
          extraGroups = [ "wheel" ]; # Enable ‘sudo’ for the user.
          createHome = true;
          uid = 1000; # Copy debian defaults so backups have same ids.
        }
      );
      root = commonUserConfig;
    };
  };
  # This is technically needed to not have assertions failing due to
  # defaultUserShell. But actual configuration happens in home-manager below.
  programs.fish.enable = true;

  # List packages installed in system profile. To search, run:
  # $ nix search wget
  environment.systemPackages = with pkgs; [
    efibootmgr
    eza
    git
    libfido2 # provides fido2-token utility
    nixd
    nixfmt-rfc-style
    tree
    wget
    # to make clipboard contents grabbable from neovim (on X. wl-copy should be
    # preferred if wayland)
    xsel
  ];
  fonts.packages = [
    pkgs.cascadia-code
  ];
  fonts.fontconfig.enable = true;

  services.pcscd.enable = true;

  age = {
    secrets = lib.mkIf config.me.foundPublicKey {
      # This is an OAuth Client (key) authorized to create auth_keys.
      tailscaleAuthKey.rekeyFile = self.outPath + "/secrets/tailscale_oauth.age";
      # TODO I cant use this because this is an encrypted (clear) passwd
      # passwd.rekeyFile = ./secrets/linux_passwd.age;
    };
  };

  services.tailscale = lib.optionalAttrs config.me.foundPublicKey {
    enable = true;
    openFirewall = true;
    # TODO: "server" or "both" for an exit node
    useRoutingFeatures = "client";
    extraUpFlags = [
      "--ssh"
      "--advertise-tags=tag:authkey-added"
    ];
    authKeyFile = config.age.secrets.tailscaleAuthKey.path;
    authKeyParameters = {
      ephemeral = false;
      preauthorized = true;
    };
  };
}
