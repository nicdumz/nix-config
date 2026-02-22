{
  lib,
  ...
}:
{
  programs.fish = {
    enable = true;
    # e.g. eza will setup abbrevations
    preferAbbrs = true;
    functions = {
      fish_greeting = ""; # bye greeting.
      # Merge history when pressing up
      up-or-search = lib.readFile ./up-or-search.fish;
      # Check stuff in PATH
      nix-inspect = # fish
        ''
          set -s PATH | grep "PATH\[.*/nix/store" | cut -d '|' -f2 |  grep -v -e "-man" -e "-terminfo" -e "imagemagick" -e "ncurses" | perl -pe 's:^/nix/store/\w{32}-([^/]*)/bin$:\1:' | sort | uniq
        '';
      __fish_complete_users = {
        body = # fish
          ''
            if test -r /etc/passwd
              string match -v -r '^\s*#' </etc/passwd | while read -l line
                string split -f 1,5 : -- $line | string join \t | string replace -r ',.*' ""
              end
            end
          '';
        description = "override user completion for systems with lots of net users -- only use local users";
      };
    };
    shellAbbrs = {
      kittydiff = "kitty +kitten diff";
      # fish for devshells
      develop = "nix develop --command fish";
      # NOTE: I used to have a weird alias downgrading TERMINFO before SSH (
      # https://sw.kovidgoyal.net/kitty/faq/#i-get-errors-about-the-terminal-being-unknown-or-opening-the-terminal-failing-or-functional-keys-like-arrow-keys-don-t-work)
      # but this sounds silly -- dropping it.
      #
      # TODO: maybe a chezmoi-google equivalent
      # TODO: maybe work specific abbrvs
    };
    # TODO: maybe work specific extensions
  };
  programs.starship = {
    enable = true;
    settings = lib.trivial.importTOML ./starship.toml;
  };
}
