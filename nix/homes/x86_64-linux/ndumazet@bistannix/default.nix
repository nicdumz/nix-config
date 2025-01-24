# Overrides specific to bistannix
_: {
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
