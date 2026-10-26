{
  mkHerdrPlugin,
  fetchFromGitHub,
  buildNpmPackage,
  git,
  nodejs,
}:
# Not packaged in lorenzorapetti/herdr-nix; built here following that repo's
# conventions (see its herdr-heeler.nix) so the plugin is linked from the nix
# store like the other programs.herdr.plugins, via callPackage on its
# herdrPlugins scope (for mkHerdrPlugin).
let
  version = "0.3.0";

  src = fetchFromGitHub {
    owner = "tdi";
    repo = "herdr-worktree-setup";
    rev = "v${version}";
    hash = "sha256-mJSAPpkMU5Qk2tDX5M2094HQBR3swJzCgkHyEuJV3Ro=";
  };

  # Upstream's [[build]] step runs `npm ci`, which `herdr plugin link` doesn't
  # run; install the dependencies here instead.
  node-modules = buildNpmPackage {
    pname = "herdr-worktree-setup-node-modules";
    inherit version src;
    npmDepsHash = "sha256-Xe1fxM25SGlp3BCx7cwfv6aJyptR+bnLCpfC/fDMW/8=";

    dontNpmBuild = true;

    doCheck = true;
    nativeCheckInputs = [ git ];
    checkPhase = ''
      runHook preCheck
      export HOME=$(mktemp -d)
      node --test
      runHook postCheck
    '';

    installPhase = ''
      runHook preInstall
      mkdir -p $out
      cp -r node_modules $out/
      runHook postInstall
    '';
  };
in
mkHerdrPlugin {
  pname = "herdr-worktree-setup";
  inherit version src;

  # git derives the main repo/branch of the new worktree; setup steps run via
  # /bin/sh with the rest of the herdr server's PATH.
  wrapCommands = [ "node" ];
  runtimeInputs = [
    git
    nodejs
  ];

  settingsFile = "config.toml";

  postInstall = ''
    find $out -mindepth 1 -maxdepth 1 \
      ! -name herdr-plugin.toml ! -name package.json ! -name src \
      ! -name config.example.toml ! -name README.md \
      -exec rm -rf {} +
    ln -s ${node-modules}/node_modules $out/node_modules
  '';

  passthru = { inherit node-modules; };

  # Upstream ships no license.
  meta.homepage = "https://github.com/tdi/herdr-worktree-setup";
}
