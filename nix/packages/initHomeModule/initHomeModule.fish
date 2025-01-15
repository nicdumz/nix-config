function initHomeModule -d "Create home module from template"
    if test (count $argv) -ne 1
        echo "Usage: initHomeModule <subpath>"
        echo "Creates the module under nix/modules/home/<subpath>"
    else
        nix flake new --template .#homemodule nix/modules/home/$argv[1]
    end
end
