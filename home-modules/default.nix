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
      nixfmt-rfc-style
      vimPlugins.none-ls-nvim
      vimPlugins.nvim-treesitter
    ];
    plugins = [
      (pkgs.vimPlugins.nvim-treesitter.withPlugins (ps: [ ps.nix ]))
    ];
    defaultEditor = true;
    vimAlias = true;
    vimdiffAlias = true;
    extraLuaConfig = ''
      local null_ls = require("null-ls")
      null_ls.setup({
          sources = {
              null_ls.builtins.formatting.nixfmt,
          },
      })
    '';
  };
}
