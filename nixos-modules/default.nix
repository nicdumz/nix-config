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

{
  imports = [
    ./agenix-rekey.nix
    ./graphical.nix
    ./nix.nix
    ./options.nix
    inputs.flake-programs-sqlite.nixosModules.programs-sqlite
    inputs.impermanence.nixosModules.impermanence
  ];

  system.stateVersion = "24.11";

  boot.initrd = {
    availableKernelModules = [
      "ata_piix"
      "sd_mod"
    ];

    systemd.enable = true;
  };

  # A strange one: embed the flake entire directory onto the produced system. This allows having
  # access to the input .nix files, and is convenient when building an .iso which then can be used
  # for deployment.
  environment.etc.nixos-sources = lib.mkIf config.nicdumz.embedFlake {
    source = self.outPath;
  };

  security.sudo.extraConfig = "Defaults insults,timestamp_timeout=30";

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

  time.timeZone = "Europe/Zurich";
  i18n.defaultLocale = "en_GB.UTF-8";

  services.openssh.enable = true;

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

    users =
      let
        initialAuth = {
          # via mkpasswd, this is a trivial / dummy PW for installs, since no key is available to
          # decrypt passwords then (using hashedPasswordFile is not feasible).
          hashedPassword = "$y$j9T$b6nmy2WZ6DxfKozDeSCM20$bs/3HW99ABTmjx/9gp62oDKIDzKn.MNOJv5VTa0Wj29";
        };
      in
      {
        ndumazet =
          let
            finalAuth = {
              hashedPasswordFile = config.age.secrets.ndumazetHashedPassword.path;
            };
            actual = if config.me.foundPublicKey then finalAuth else initialAuth;
          in
          {
            isNormalUser = true;
            extraGroups = [ "wheel" ]; # Enable ‘sudo’ for the user.
            createHome = true;
            uid = 1000; # Debian defaults.
            openssh.authorizedKeys.keys = [
              # TODO: formalize this.
              "sk-ssh-ed25519@openssh.com AAAAGnNrLXNzaC1lZDI1NTE5QG9wZW5zc2guY29tAAAAIIU3bA3q9/SlrUXzsApLaVkUDAlQY1c5PMmnoC+XnmjOAAAABHNzaDo= ndumazet@bistannix nano"
            ];
          }
          // actual;

        # TODO: add password
        giulia = {
          isNormalUser = true;
        } // initialAuth;

        root = {
          # NOTE: no passwd, no need for direct login.
          uid = 0;
        };
      };
  };
  # This is technically needed to not have assertions failing due to
  # defaultUserShell. But actual configuration happens in home-manager below.
  programs.fish.enable = true;

  # List packages installed in system profile. To search, run:
  # $ nix search wget
  environment.systemPackages = with pkgs; [
    colordiff
    efibootmgr
    git
    libfido2 # provides fido2-token utility
    nixd
    nixfmt-rfc-style
    unzip
    wget
  ];

  services.pcscd.enable = true;

  age = {
    secrets = lib.mkIf config.me.foundPublicKey {
      # This is an OAuth Client (key) authorized to create auth_keys.
      tailscaleAuthKey = {
        rekeyFile = self.outPath + "/secrets/tailscale-oauth.age";
        # Note: defaults are nicely restricted:
        # mode = "0400";
        # owner = "root";
        # group = "root";
      };
      ndumazetHashedPassword.rekeyFile = self.outPath + "/secrets/ndumazet-hashed-password.age";
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
    ];
    # The key is a reusable key from https://login.tailscale.com/admin/settings/keys
    # It unfortunately expires after 90d ..
    authKeyFile = config.age.secrets.tailscaleAuthKey.path;
  };
}
