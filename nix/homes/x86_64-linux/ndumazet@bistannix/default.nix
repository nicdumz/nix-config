# Overrides specific to bistannix
{ lib, ... }:
{
  programs.ssh = {
    enable = true;
    enableDefaultConfig = false;
    settings = {
      "*" = {
        # Only touch FIDO keys once every hour.
        ControlMaster = "auto";
        ControlPersist = "60m";
        ControlPath = "~/.ssh/master-%r@%n:%p";
        # Key is out of .ssh to avoid auto-loading it into Gnome keyring/agent,
        # otherwise keypress prompts don't show reliably when they're required.
        # TODO: maybe version this private key.
        IdentityFile = "/home/ndumazet/.ssh/noauto/id_ed25519_sk";

        # defaults from 25.05
        ForwardAgent = false;
        AddKeysToAgent = "no";
        Compression = false;
        ServerAliveInterval = 0;
        ServerAliveCountMax = 3;
        HashKnownHosts = false;
        UserKnownHostsFile = "~/.ssh/known_hosts";
      };
      qemu = lib.hm.dag.entryAfter [ "*" ] {
        HostName = "localhost";
        Port = 2222;
        # VM, reinstalled often.
        StrictHostKeyChecking = "no";
        UserKnownHostsFile = "/dev/null";
      };
    };
  };
}
