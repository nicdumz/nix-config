# Module common to all homes / users.
{
  pkgs,
  lib,
  inputs,
  ...
}:
{
  programs.home-manager.enable = true;
  home.stateVersion = "24.11";
  # For nixd
  nix.nixPath = [ "nixpkgs=${inputs.nixpkgs}" ];

  programs.htop.enable = true;

  dconf.settings = {
    "org/gnome/desktop/interface" = {
      scaling-factor = lib.hm.gvariant.mkUint32 2;
      text-scaling-factor = lib.hm.gvariant.mkDouble 2.0;
      cursor-size = 36;
      color-scheme = "prefer-dark";
    };
    "org/gnome/desktop/background" = {
      picture-uri-dark = "file://" + ./nixos-wallpaper.png;
    };
    "org/gnome/desktop/screensaver" = {
      picture-uri = "file://" + ./nixos-wallpaper.png;
    };
  };

  xdg.enable = true;

  programs.fish = {
    enable = true;
    # eza below will setup abbrevations
    preferAbbrs = true;
    interactiveShellInit = ''
      set fish_greeting
    '';
    functions = {
      __fish_complete_users = {
        body = ''
          if test -r /etc/passwd
            string match -v -r '^\s*#' </etc/passwd | while read -l line
              string split -f 1,5 : -- $line | string join \t | string replace -r ',.*' ""
            end
          end
        '';
        description = "override user completion for systems with lots of net users -- only use local users";
      };
    };
  };
  programs.eza = {
    enable = true;
    icons = "auto";
    colors = "auto";
  };
  programs.git = {
    enable = true;
    aliases = {
      st = "status";
      ci = "commit";
    };
  };

  home.sessionVariables.EDITOR = "nvim";
  programs.neovim = {
    enable = true;
    extraPackages = with pkgs; [
      # both already in system packages, but just in case...
      nixd
      nixfmt-rfc-style
    ];
    plugins = with pkgs.vimPlugins; [
      (nvim-treesitter.withPlugins (ps: [ ps.nix ]))
      nvim-lspconfig
      cmp-nvim-lsp
      nvim-cmp
    ];
    defaultEditor = true;
    vimAlias = true;
    vimdiffAlias = true;
    extraLuaConfig = ''
      local cmp = require('cmp')

      cmp.setup({
        mapping = cmp.mapping.preset.insert({
          ['<C-b>'] = cmp.mapping.scroll_docs(-4),
          ['<C-f>'] = cmp.mapping.scroll_docs(4),
          ['<C-Space>'] = cmp.mapping.complete(),
          ['<C-e>'] = cmp.mapping.abort(),
          ['<CR>'] = cmp.mapping.confirm({ select = true }), -- Accept currently selected item. Set `select` to `false` to only confirm explicitly selected items.
        }),
        sources = cmp.config.sources({
          { name = 'nvim_lsp' },
        }, {
          { name = 'buffer' },
        })
      })

      local capabilities = require('cmp_nvim_lsp').default_capabilities()
      -- note that ./. below works because nixd starts in root_dir() (where .git or flake.nix is)
      require('lspconfig').nixd.setup({
        capabilities = capabilities,
        settings = {
          nixd = {
            options = {
              nixos = {
                expr = '(builtins.getFlake ("git+file://" + toString ./.)).nixosConfigurations.bistannix.options',
              },
              home_manager = {
                expr = '(builtins.getFlake ("git+file://" + toString ./.)).homeConfigurations."ndumazet@bistannix".options',
              },
            },
          },
        },
      })
    '';
  };
}
