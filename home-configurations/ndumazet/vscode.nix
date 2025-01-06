{ config, pkgs, ... }:
{
  programs.vscode = {
    enable = true;
    package = pkgs.vscodium;
    extensions = with pkgs.vscode-extensions; [
      asvetliakov.vscode-neovim
      jnoortheen.nix-ide
      stkb.rewrap
    ];
    userSettings = {
      "editor.fontSize" = 16;
      "editor.rulers" = [
        80
        100
      ];
      "editor.fontFamily" = config.fontProfiles.monospace.name + ", 'monospace', monospace";
      "rewrap.autoWrap.enabled" = true;
      "rewrap.wrappingColumn" = 100;
      "nix.formatterPath" = [
        "nix"
        "fmt"
        "--"
        "--"
      ];
      "nix.serverPath" = "nixd";
      "nix.enableLanguageServer" = true;
      "[nix]" = {
        "editor.formatOnSave" = true;
      };
      "extensions.experimental.affinity" = {
        "asvetliakov.vscode-neovim" = 1;
      };
      "nix.serverSettings" = {
        nixd = {
          options = {
            #default = {
            #  expr = "import <nixpkgs> { }";
            #};
            nixos = {
              expr = "(builtins.getFlake \"\${workspaceFolder}\").nixosConfigurations.bistannix.options";
            };
            home-manager = {
              expr = "(builtins.getFlake \"\${workspaceFolder}\").homeConfigurations.\"ndumazet@bistannix\".options";
            };
          };
        };
      };
    };
  };
}
