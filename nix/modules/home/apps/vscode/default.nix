{
  config,
  inputs,
  lib,
  pkgs,
  namespace,
  osConfig ? { },
  ...
}:
let
  cfg = config.${namespace}.vscode;
  exts =
    inputs.nix-vscode-extensions.extensions.${pkgs.stdenv.hostPlatform.system}.vscode-marketplace;
  # Needs patching to find libstdc++ and musl
  # This is similar to how continue.continue finds libstdc++
  jj-view = pkgs.vscode-utils.buildVscodeMarketplaceExtension {
    mktplcRef = {
      name = "jj-view";
      publisher = "jj-view";
      version = "1.20.0";
      sha256 = "sha256-3NRUHFYJdfx2YU/SgtUehsYSO6xdl9QpUJEnLcZV2iU=";
    };
    # Patch obtained from: https://github.com/NixOS/nixpkgs/blob/master/pkgs/applications/editors/vscode/extensions/continue.continue/default.nix
    nativeBuildInputs = [ pkgs.autoPatchelfHook ];
    buildInputs = [
      pkgs.stdenv.cc.cc.lib
      pkgs.musl
    ];
  };
in
{
  options.${namespace} = {
    vscode = {
      enable = lib.mkOption {
        type = lib.types.bool;
        default = false;
        description = "Enable vscode (well, vscodium) for this user.";
      };
      continue = lib.mkOption {
        type = lib.types.bool;
        default = config.${namespace}.ollama.enable;
        description = "Enable continue extension for local AI dev.";
      };
    };
    ollama = {
      enable = lib.mkOption {
        type = lib.types.bool;
        default = osConfig.${namespace}.ollama.enable or false;
        description = "Enable ollama integration";
      };
    };
  };

  config = lib.mkIf cfg.enable {
    # TODO: modularize
    # I use Go below
    home.packages = [
      pkgs.go
      pkgs.gopls
    ];

    programs.vscode = lib.optionalAttrs config.${namespace}.device.isGraphical {
      enable = true;
      package = pkgs.vscodium;
      mutableExtensionsDir = false;
      profiles.default = {
        enableExtensionUpdateCheck = false;
        enableUpdateCheck = false;
        extensions =
          with pkgs.vscode-extensions;
          [
            asvetliakov.vscode-neovim
            bierner.github-markdown-preview
            golang.go
            jnoortheen.nix-ide
            mkhl.direnv
            redhat.vscode-yaml
            stkb.rewrap
          ]
          ++ [
            jj-view
          ]
          ++ lib.lists.optional cfg.continue exts.continue.continue;
        userSettings = {
          # Tricky to get enough information density and not tiny fonts.
          "editor.fontSize" = config.fontProfiles.monospace.size;
          "editor.fontFamily" = config.fontProfiles.monospace.name + ", 'monospace', monospace";
          "window.zoomLevel" = 1;

          "editor.rulers" = [
            80
            100
          ];
          "files.insertFinalNewline" = true;
          "redhat.telemetry.enabled" = false;
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
          # BEGIN Catpuccin recs
          # applicable if you use Go, this is an opt-in flag!
          "gopls" = {
            "ui.semanticTokens" = true;
          };
          # END Catpuccin recs

          # BEGIN recommended mkdocs settings, https://squidfunk.github.io/mkdocs-material/creating-your-site/#configuration
          "yaml.schemas" = {
            "https://squidfunk.github.io/mkdocs-material/schema.json" = [ "mkdocs.yml" ];
          }
          // lib.optionalAttrs cfg.continue {
            "file://${config.home.homeDirectory}/.vscode-oss/extensions/continue.continue/config-yaml-schema.json" =
              [
                ".continue/**/*.yaml"
              ];
          };
          "yaml.customTags" = [
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
    home.file = lib.optionalAttrs cfg.continue {
      # TODO: if I were smarter we should verify that each model is in the ollama config.
      ".continue/config.yaml".source = (pkgs.formats.yaml { }).generate "continue-config" {
        name = "config";
        version = "0.1.1";
        schema = "v1";
        models = [
          {
            name = "Instinct";
            provider = "ollama";
            model = "nate/instinct";
            roles = [
              "autocomplete"
            ];
            autocompleteOptions.maxPromptTokens = 8192;
            defaultCompletionOptions = {
              temperature = 0;
              contextLength = 32768;
              stop = [ "<|im_end|>" ];
            };
          }
        ];
        context = [
          { provider = "diff"; }
          { provider = "file"; }
          { provider = "code"; }
        ];
      };
    };
  };
}
