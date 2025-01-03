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
  ];

  # not very intuitively, this is actually _merged_ with the modules enabled in qemu-guest
  boot.initrd.availableKernelModules = [
    "ata_piix"
    "floppy"
    "sd_mod"
    "sr_mod"
  ];

  # Enables DHCP on each ethernet and wireless interface. In case of scripted networking
  # (the default) this is the recommended approach. When using systemd-networkd it's
  # still possible to use this option, but it's recommended to use it in conjunction
  # with explicit per-interface declarations with `networking.interfaces.<interface>.useDHCP`.
  networking.useDHCP = lib.mkDefault true;

  nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";

  boot.loader.efi.canTouchEfiVariables = true;
  boot.loader.grub.enable = false;
  boot.loader.systemd-boot.enable = true;
  boot.loader.systemd-boot.configurationLimit = 10;

  environment.sessionVariables = rec {
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
        }
      );
      root = commonUserConfig;
    };
  };

  programs.fish.enable = true;
  programs.git = {
    enable = true;
    config = {
      user = {
        email = "nicdumz.commits@gmail.com";
        name = "Nicolas Dumazet";
      };
      aliases = {
        st = "status";
        ci = "commit";
      };
      # TODO fix this later
      safe = {
        directory = "/media/host";
      };
    };
  };

  # List packages installed in system profile. To search, run:
  # $ nix search wget
  environment.systemPackages = with pkgs; [
    wget
    tree
    kitty
    librewolf
    vscodium
    nixfmt-rfc-style
    vimPlugins.none-ls-nvim
    vimPlugins.nvim-treesitter
  ];
  programs.neovim = {
    enable = true;
    # option doesnt exist
    # extraPackages = with pkgs; [
    #   nixfmt-rfc-style
    #   vimPlugins.none-ls-nvim
    #   vimPlugins.nvim-treesitter
    # ];
    defaultEditor = true;
    vimAlias = true;
    configure = {
      packages.all.start = with pkgs.vimPlugins; [
        (nvim-treesitter.withPlugins (ps: [ ps.nix ]))
        none-ls-nvim
      ];
      # TODO: I still have no idea on how to trigger this.
      customRC = ''
        local null_ls = require("null-ls")
        null_ls.setup({
            sources = {
                null_ls.builtins.formatting.nixfmt,
            },
        })
      '';
    };
  };

  services.pcscd.enable = true;

  age = {
    secrets = lib.mkIf config.me.foundPublicKey {
      # This is an OAuth Client (key) authorized to create auth_keys.
      tailscaleAuthKey.rekeyFile = ./secrets/tailscale_oauth.age;
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

  # This option defines the first version of NixOS you have installed on this particular machine,
  # and is used to maintain compatibility with application data (e.g. databases) created on older NixOS versions.
  #
  # Most users should NEVER change this value after the initial install, for any reason,
  # even if you've upgraded your system to a new NixOS release.
  #
  # This value does NOT affect the Nixpkgs version your packages and OS are pulled from,
  # so changing it will NOT upgrade your system - see https://nixos.org/manual/nixos/stable/#sec-upgrading for how
  # to actually do that.
  #
  # This value being lower than the current NixOS release does NOT mean your system is
  # out of date, out of support, or vulnerable.
  #
  # Do NOT change this value unless you have manually inspected all the changes it would make to your configuration,
  # and migrated your data accordingly.
  #
  # For more information, see `man configuration.nix` or https://nixos.org/manual/nixos/stable/options#opt-system.stateVersion .
  system.stateVersion = "24.11"; # Did you read the comment?

}
