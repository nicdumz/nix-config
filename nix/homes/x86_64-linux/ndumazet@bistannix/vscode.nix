{
  config,
  lib,
  osConfig ? { },
  namespace,
  pkgs,
  ...
}:
{
  # TODO: modularize
  # I use Go below
  home.packages = [
    pkgs.go
    pkgs.gopls
  ];

  programs.vscode = lib.optionalAttrs (osConfig.${namespace}.graphical or false) {
    enable = true;
    package = pkgs.vscodium;
    enableExtensionUpdateCheck = false;
    enableUpdateCheck = false;
    mutableExtensionsDir = false;
    extensions =
      with pkgs.vscode-extensions;
      [
        asvetliakov.vscode-neovim
        catppuccin.catppuccin-vsc
        catppuccin.catppuccin-vsc-icons
        continue.continue
        golang.go
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
      # Tricky to get enough information density and not tiny fonts.
      "editor.fontSize" = config.fontProfiles.monospace.size - 2;
      "window.zoomLevel" = 1;

      "editor.rulers" = [
        80
        100
      ];
      "editor.fontFamily" = config.fontProfiles.monospace.name + ", 'monospace', monospace";
      "files.insertFinalNewline" = true;
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
      "workbench.colorTheme" = "Catppuccin Mocha";
      "workbench.iconTheme" = "catppuccin-mocha";
      # BEGIN Catpuccin recs
      # we try to make semantic highlighting look good
      "editor.semanticHighlighting.enabled" = true;
      # prevent VSCode from modifying the terminal colors
      "terminal.integrated.minimumContrastRatio" = 1;
      # make the window's titlebar use the workbench colors
      "window.titleBarStyle" = "custom";
      # applicable if you use Go, this is an opt-in flag!
      "gopls" = {
        "ui.semanticTokens" = true;
      };
      # END Catpuccin recs
    };
  };
}
