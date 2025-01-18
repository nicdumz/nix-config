{
  pkgs,
  osConfig ? { },
  lib,
  inputs,
  namespace,
  ...
}:
{

  home.packages = [
    # useful for (shell) color diagnosis.
    pkgs.neofetch
  ];

  # A strange one: embed the flake entire directory onto the produced system. This allows having
  # access to the input .nix files, and is convenient when building an .iso which then can be used
  # for deployment.
  home.file.nixos-sources = lib.mkIf (osConfig.${namespace}.embedFlake or false) {
    source = inputs.self;
    target = "nixos-sources";
  };

  programs.ssh = {
    enable = true;
    # Only touch FIDO keys once every hour.
    controlMaster = "auto";
    controlPersist = "60m";
    # TODO: maybe version this private key.
    extraConfig = ''
      # Key is out of .ssh to avoid auto-loading it into Gnome keyring/agent,
      # otherwise keypress prompts don't show reliably when they're required.
      IdentityFile /home/ndumazet/.ssh/noauto/id_ed25519_sk
    '';
    matchBlocks = {
      # TODO: should this be a hostconfiguration somewhere.
      jonsnow.hostname = "192.168.1.1";
      lethargyfamily.hostname = "192.168.1.232";
      qemu = {
        hostname = "localhost";
        port = 2222;
        extraOptions = {
          # VM, reinstalled often.
          StrictHostKeyChecking = "no";
          UserKnownHostsFile = "/dev/null";
        };
      };
    };
  };
}
