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
  jj-view = exts.jj-view.jj-view.override {
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
    home.packages = with pkgs; [
      claude-code
      nodejs_24 # for Claude
      go
      gopls
    ];

    programs.vscodium = lib.optionalAttrs config.${namespace}.device.isGraphical {
      enable = true;
      mutableExtensionsDir = false;
      profiles =
        let
          common = {
            enableExtensionUpdateCheck = false;
            enableUpdateCheck = false;
            extensions =
              with pkgs.vscode-extensions;
              [
                anthropic.claude-code # using exts. fails allowUnfree stuff.
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
              "editor.formatOnSave" = true;
              "files.autoSave" = "afterDelay";
              "files.autoSaveDelay" = 1000;
              "files.associations" = {
                "BUILD" = "starlark";
                "*.bzl" = "starlark";
                "*.bazel" = "starlark";
                "*.hujson" = "jsonc";
                "OWNERS" = "plaintext";
                "ALL_OWNERS" = "plaintext";
              };
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
              "workbench.trustedDomains" = [
                "https://accounts.google.com"
                "https://github.com"
              ];
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
        in
        {
          default = common;
          work = lib.mkMerge [
            common
            {
              extensions =
                with pkgs.vscode-extensions;
                [
                  bazelbuild.vscode-bazel
                  charliermarsh.ruff
                  ms-python.python # dependencies for others.
                  tamasfe.even-better-toml
                ]
                ++ [
                  exts.astral-sh.ty
                ];
              userSettings = {
                "python.defaultInterpreterPath" = "\${workspaceFolder}/.venv/bin/python";
                "python.languageServer" = "None";
                "ruff.configuration" = "\${workspaceFolder}/pyproject.toml";
                "[python]" = {
                  "editor.codeActionsOnSave" = {
                    "source.fixAll.ruff" = "explicit";
                    "source.organizeImports.ruff" = "explicit";
                  };
                  "editor.defaultFormatter" = "charliermarsh.ruff";
                };
                "[starlark]"."editor.formatOnSave" = false;
                "[jsonc]" = {
                  "editor.formatOnSave" = true;
                  "files.insertFinalNewline" = true;
                };
                "[toml]"."editor.defaultFormatter" = "tamasfe.even-better-toml";
                "files.exclude" = {
                  "**/__pycache__" = true;
                  "**/*.pyc" = true;
                };
                "bazel.executable" = "bazelisk";
                "search.exclude" = {
                  "**/__pycache__" = true;
                  "**/*.pyc" = true;
                };
                "files.watcherExclude"."**/__pycache__/**" = true;
                "git.enabled" = false; # jj everywhere
              };
            }
          ];

        };
    };

    # Catpuccin only enables thememing on the default profile usually.
    catppuccin.vscode.profiles = {
      default.enable = true;
      work.enable = true;
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
