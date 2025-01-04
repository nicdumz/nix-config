# Module common to all homes / users.
{ pkgs, ... }:
{
  programs.home-manager.enable = true;
  home.stateVersion = "24.11";

  programs.htop.enable = true;

  programs.fish = {
    enable = true;
    shellAbbrs = {
      # ls = lib.mkIf eza ...
    };
  };

  programs.git = {
    enable = true;
    aliases = {
      st = "status";
      ci = "commit";
    };
    # config = {
    #   # TODO fix this later
    #   safe = {
    #     directory = "/media/host";
    #   };
    # };
  };

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
      local cmp = require'cmp'

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
      require'lspconfig'.nixd.setup{
        capabilities = capabilities
      }
    '';
  };
}
