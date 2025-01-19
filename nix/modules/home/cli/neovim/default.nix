{ pkgs, ... }:
{
  programs.neovim = {
    enable = true;
    extraPackages = with pkgs; [
      # both already in system packages, but just in case...
      nixd
      nixfmt-rfc-style
    ];
    plugins = with pkgs.vimPlugins; [
      (nvim-treesitter.withPlugins (ps: [ ps.nix ]))
      {
        plugin = nvim-cmp;
        type = "lua";
        config = # lua
          ''
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
          '';

      }
      {
        plugin = cmp-nvim-lsp;
        type = "lua";
        config = # lua
          ''
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
      }
      nvim-lspconfig
      {
        plugin = vim-airline;
        config = ''
          let g:airline_powerline_fonts = 1
          let g:airline_section_y = '''
        '';
      }
      vim-airline-themes
      vim-sensible
      {
        plugin = catppuccin-nvim;
        config = "colorscheme catppuccin-mocha";
      }
    ];
    defaultEditor = true;
    vimAlias = true;
    vimdiffAlias = true;
    # Keeping things quite basic compared to the sea of settings I used to have.
    extraConfig = ''
      set nomodeline " vulns
      set noswapfile
      set ff=unix fixeol

      set cmdheight=2
      set shortmess=atToOcCF

      set wildmode=longest,list,full
      set wildignore=*.swp,*.bak,*.pyc,*.class

      set fillchars=vert:┃,fold:- " Nicer vertical split
      set formatoptions+=rj " Remove comment characters and others on J

      set expandtab
      set tabstop=4
      set shiftwidth=4

      set number " Show line numbers

      " space to PageDown, similar to vimperator
      map <space> <C-f>

      " easier keyboard, when I accidentally hit F1 instead of Esc.
      map <F1> <Esc>
      imap <F1> <Esc>
      imap <M-Space> <Esc>

      " Show Git diff in window split when commiting
      autocmd FileType gitcommit DiffGitCached | wincmd L | wincmd p
    '';
  };

  home.sessionVariables.EDITOR = "nvim";
}
