{
  config,
  lib,
  pkgs,
  namespace,
  osConfig ? { },
  ...
}:
let
  cfg = config.${namespace}.vscode;
in
{
  options.${namespace}.vscode = {
    enable = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Enable vscode (well, vscodium) for this user.";
    };
  };

  config = lib.mkIf cfg.enable {
    # TODO: modularize
    # I use Go below
    home.packages = [
      pkgs.go
      pkgs.gopls
    ];

    programs.vscode = lib.optionalAttrs (osConfig.${namespace}.graphical or false) {
      enable = true;
      package = pkgs.vscodium;
      mutableExtensionsDir = false;
      profiles.default = {
        enableExtensionUpdateCheck = false;
        enableUpdateCheck = false;
        extensions = with pkgs.vscode-extensions; [
          asvetliakov.vscode-neovim
          bierner.github-markdown-preview
          catppuccin.catppuccin-vsc
          catppuccin.catppuccin-vsc-icons
          golang.go
          jnoortheen.nix-ide
          mkhl.direnv
          redhat.vscode-yaml
          stkb.rewrap
          visualjj.visualjj
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
                  expr = "(builtins.getFlake \"\${workspaceFolder}\").homeConfigurations.ndumazet.options";
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

          # BEGIN recommended mkdocs settings, https://squidfunk.github.io/mkdocs-material/creating-your-site/#configuration
          yaml.schemas = {
            "https://squidfunk.github.io/mkdocs-material/schema.json" = "mkdocs.yml";
          };
          yaml.customTags = [
            "!ENV scalar"
            "!ENV sequence"
            "!relative scalar"
            "tag:yaml.org,2002:python/name:material.extensions.emoji.to_svg"
            "tag:yaml.org,2002:python/name:material.extensions.emoji.twemoji"
            "tag:yaml.org,2002:python/name:pymdownx.superfences.fence_code_format"
            "tag:yaml.org,2002:python/object/apply:pymdownx.slugs.slugify mapping"
          ];
          # END mkdocs
        };
      };
    };
  };
}
