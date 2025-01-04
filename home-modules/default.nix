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
    ];
    defaultEditor = true;
    vimAlias = true;
    vimdiffAlias = true;
    extraLuaConfig = ''
      require'lspconfig'.nixd.setup{}
    '';
  };
}
