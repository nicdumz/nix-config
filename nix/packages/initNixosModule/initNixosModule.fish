function initNixosModule -d "Create Nixos module from template"
    if test (count $argv) -ne 1
        echo (count $argv)
        echo "Usage: initNixosModule <subpath>"
        echo "Creates the module under nix/modules/nixos/<subpath>"
    else
        nix flake new --template .#nixosmodule nix/modules/nixos/$argv[1]
    end
end
