{
  lib,
  ...
}:
{
  programs.fish = {
    enable = true;
    # e.g. eza will setup abbrevations
    preferAbbrs = true;
    interactiveShellInit = ''
      set -x tide_nix3_shell_bg_color "normal"
      set -x tide_nix3_shell_color "brblue"
      set -x tide_nix3_shell_icon ""
    ''; # maybe extend later
    functions = {
      fish_greeting = ""; # bye greeting.
      # Merge history when pressing up
      up-or-search = lib.readFile ./up-or-search.fish;
      # Check stuff in PATH
      nix-inspect = # fish
        ''
          set -s PATH | grep "PATH\[.*/nix/store" | cut -d '|' -f2 |  grep -v -e "-man" -e "-terminfo" | perl -pe 's:^/nix/store/\w{32}-([^/]*)/bin$:\1:' | sort | uniq
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
      # Improved nix shell (define a prompt item that I can use in e.g. tide_right_prompt_items)
      _tide_item_nix3_shell = # fish
        ''
          set packages (nix-inspect)
          if test -n "$IN_NIX_SHELL"
            set -q name; or set name nix-shell
            set -p packages $name
          end
          if set -q packages[1] &>/dev/null
            _tide_print_item nix3_shell $tide_nix3_shell_icon' ' " $(string shorten -m 40 "$packages")"
          end
        '';
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
}
