# NixCI in-repo configuration (https://nix-ci.com/documentation/configuration).
#
# Must be a single self-contained file: NixCI reads it straight out of the
# forge without cloning the repository, so it rejects a file that imports
# another one. This mirrors flake.nix's nixConfig restriction (plain literals
# only), so the cachix list below is repeated by hand just like there; an
# assertion in nix/modules/nixos/cli/nix/default.nix fails `nix flake check`
# if the two ever drift apart.
{
  cachix = [
    {
      name = "nix-community";
      public-key = "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs=";
      push = false;
    }
    {
      name = "numtide";
      public-key = "numtide.cachix.org-1:2ps1kLBUWjxIneOy1Ik6cQjb41X0iXVXeHigGmycPPE=";
      push = false;
    }
    {
      name = "noctalia";
      public-key = "noctalia.cachix.org-1:pCOR47nnMEo5thcxNDtzWpOxNFQsBRglJzxWPp3dkU4=";
      push = false;
    }
    {
      # herdr's own prebuilt-binary release cache.
      name = "herdr";
      public-key = "herdr.cachix.org-1:3nH7IStRsS0ASfdonA0DCRR2ZrSCeWitZ7Kwew0cR4I=";
      push = false;
    }
    {
      # lorenzorapetti/herdr-nix's plugin cache (unrelated project, similar name).
      name = "herdr-nix";
      public-key = "herdr-nix.cachix.org-1:UpdsQYx39PK0PToKQaa2EFq19Lsjs1M9Ho+X7VNt9gs=";
      push = false;
    }
  ];
}
