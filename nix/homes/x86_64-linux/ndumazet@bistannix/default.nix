# Overrides specific to bistannix
{ lib, ... }:
{
  programs.ssh = {
    enable = true;
    enableDefaultConfig = false;
    matchBlocks = {
      "*" = {
        # Only touch FIDO keys once every hour.
        controlMaster = "auto";
        controlPersist = "60m";
        controlPath = "~/.ssh/master-%r@%n:%p";
        # Key is out of .ssh to avoid auto-loading it into Gnome keyring/agent,
        # otherwise keypress prompts don't show reliably when they're required.
        # TODO: maybe version this private key.
        identityFile = "/home/ndumazet/.ssh/noauto/id_ed25519_sk";

        # defaults from 25.05
        forwardAgent = false;
        addKeysToAgent = "no";
        compression = false;
        serverAliveInterval = 0;
        serverAliveCountMax = 3;
        hashKnownHosts = false;
        userKnownHostsFile = "~/.ssh/known_hosts";
      };
      qemu = lib.hm.dag.entryAfter [ "*" ] {
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
