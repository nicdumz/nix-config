{
  lib,
  pkgs,
  ...
}:

let
  # customize as needed
  homeDir = "/home/ndumazet";

  auto-hm-update = pkgs.writeShellApplication {
    name = "auto-hm-update";
    runtimeInputs = with pkgs; [
      git
      nix
      home-manager
    ];
    # TODO: fix host
    text = ''
      if /usr/bin/gcertstatus -quiet; then
        home-manager switch --flake "git+https://sso-internal/user/ndumazet/home-manager"
      fi
    '';
  };
in
{
  assertions = [
    {
      assertion = pkgs.google-chrome.version == "corp-syslink";
      message = "pkgs.google-chrome corp overlay was overridden: ${pkgs.google-chrome.version}";
    }
  ];

  nix.settings = {
    substituters = [
      "https://cache.nixos.org"
      "https://cache.garnix.io"
      "https://nix-community.cachix.org"
      "https://numtide.cachix.org"
      "https://noctalia.cachix.org"
    ];

    trusted-public-keys = [
      "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
      "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
      "numtide.cachix.org-1:2ps1kLBUWjxIneOy1Ik6cQjb41X0iXVXeHigGmycPPE="
      "cache.garnix.io:CTFPyKSLcx5RMJKfLo5EEPUObbA78b0YQ2DTCJXqr9g="
      "noctalia.cachix.org-1:pCOR47nnMEo5thcxNDtzWpOxNFQsBRglJzxWPp3dkU4="
    ];
  };

  home = {
    packages = [
      pkgs.nix # avoid readline linkage mess which breaks `nix repl`
      auto-hm-update
    ];

    username = "ndumazet";
    homeDirectory = homeDir;

    # Remember to be quite careful if and when changing this, read release notes etc.
    stateVersion = "25.11";
  };

  news.display = "silent"; # no notifications

  # Tell it to add the right vars to shell configs.
  targets.genericLinux.enable = true;

  systemd.user.services."auto-hm-update" = {
    Unit.Description = "Auto-update home-manager configuration from remote";
    Service = {
      Type = "oneshot";
      ExecStart = lib.getExe auto-hm-update;
    };
  };

  systemd.user.timers."auto-hm-update" = {
    Unit.Description = "Auto-update home-manager timer";
    Timer = {
      OnBootSec = "15m";
      OnUnitActiveSec = "4h";
      Persistent = true;
    };
    Install.WantedBy = [ "timers.target" ];
  };

  # TODO: upstream
  services.hypridle = {
    enable = true;
    settings = {
      general = {
        before_sleep_cmd = lib.mkForce "loginctl lock-session";
      };
      listener = lib.mkForce [
        {
          timeout = 900;
          on-timeout = "loginctl lock-session";
        }
        {
          timeout = 1200;
          on-timeout = "hyprctl dispatch dpms off";
          on-resume = "hyprctl dispatch dpms on";
        }
      ];
    };
  };
  programs = {
    # TODO: upstream
    hyprlock = {
      enable = true;
    };
    swaylock.enable = true;
    swaylock.settings = {
      show-failed-attempts = true;
      font = "CaskaydiaCove Nerd Font";
    };

    # Just use the system-wide chrome I dont need this.
    google-chrome.enable = lib.mkForce false;
    # TODO: broken overlays.
    # Ideally the overlay should pass through upstreams' pkgs. Doesn't work, not sure why yet.
    google-chrome.package = pkgs.google-chrome;

    # Let Home Manager install and manage itself.
    home-manager.enable = true;

    # Keep system-wide packages
    git = {
      settings = {
        user.email = lib.mkForce "ndumazet@google.com";
        core.excludesfile = "~/.config/git/ignore";
        # allows to pull "https://sso-internal/user/ndumazet/home-manager" and this gets translated to sso://user/ndumazet/home-manager
        # This is because Nix doesn't recognize sso:// urls natively.
        url."sso://".insteadOf = "https://sso-internal/";
      };
    };

    ssh = {
      enable = true;
      enableDefaultConfig = false;
      # TODO: add any relevant overrides
    };

    # TODO: add any relevant overrides.
    neovim.extraConfig = "";

    fish = {
      shellAbbrs = {
        # TODO: add any relevant aliases
      };
      # TODO: add any relevant custom inits
      interactiveShellInit = "";
    };
  };

  wayland.windowManager.hyprland = {
    # TODO: broken overlays.
    # Ideally the overlay should pass through upstreams' pkgs. Doesn't work, not sure why yet.
    package = pkgs.hyprland;
    portalPackage = pkgs.xdg-desktop-portal-hyprland;
    settings = {
      windowrule = [
        "match:initial_title (Cider|Visual.Studio.Code).*, workspace 3"
      ];
    };
  };

  home.file.".blazerc".text = ''
    test --test_output=errors --color=auto

    build --color=auto
  '';

  home.file."nix-config.code-workspace".source =
    (pkgs.formats.json { }).generate "nix-config.code-workspace"
      {
        folders = [
          # Be aware that right now only the first root shows up, sadly
          # See https://github.com/brychanrobot/jj-view/issues/307
          { path = "${homeDir}/.config/home-manager"; }
          { path = "${homeDir}/code/nix-config"; }
        ];
        settings = {
          "git.ignoredRepositories" = [
            "${homeDir}/code/nix-config"
            "${homeDir}/.config/home-manager"
          ];
        };
      };

  # TODO: upstream
  programs.kitty.extraConfig = ''
    copy_on_select clipboard
    mouse_map middle release ungrabbed paste_from_clipboard
  '';
}
