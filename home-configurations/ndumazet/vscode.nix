{
  config,
  lib,
  osConfig,
  pkgs,
  ...
}:
{
  programs.vscode = lib.optionalAttrs osConfig.nicdumz.graphical {
    enable = true;
    package = pkgs.vscodium;
    enableExtensionUpdateCheck = false;
    enableUpdateCheck = false;
    mutableExtensionsDir = false;
    extensions =
      with pkgs.vscode-extensions;
      [
        asvetliakov.vscode-neovim
        jnoortheen.nix-ide
        stkb.rewrap
      ]
      ++ pkgs.vscode-utils.extensionsFromVscodeMarketplace [
        {
          name = "vscode-markdown-alert";
          publisher = "yahyabatulu";
          version = "0.0.4";
          sha256 = "sha256-dCaSMPSntYo0QLr2pcs9GfJxOshfyeXbs8IMCwd+lqw=";
        }
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
      "nix.formatterPath" = [ "nixfmt" ];
      "nix.serverPath" = "nixd";
      "nix.enableLanguageServer" = true;
      "[nix]" = {
        "editor.formatOnSave" = true;
        "editor.formatOnPaste" = true;
        "editor.formatOnType" = false;
      };
      "extensions.experimental.affinity" = {
        "asvetliakov.vscode-neovim" = 1;
        "jnoortheen.nix-ide" = 1;
      };
      "nix.serverSettings" = {
        nixd = {
          options = {
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
