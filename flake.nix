{
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/43e3b6af08f29c4447a6073e3d5b86a4f45dd420";
    flake-parts.url = "github:hercules-ci/flake-parts";
    haskell-flake.url = "github:srid/haskell-flake";
    haskeline.url = "github:judah/haskeline/019e08f2c91b7cc45e5fb98189193a9f5c2d2d57";
    haskeline.flake = false;
    systems.url = "github:nix-systems/default";
  };
  outputs = inputs@{ self,systems, nixpkgs, flake-parts, ... }:
    flake-parts.lib.mkFlake { inherit inputs; } {
      systems = import inputs.systems;
      imports = [ inputs.haskell-flake.flakeModule ];

      perSystem = { self', pkgs, ... }: {
        haskellProjects.default = {

          basePackages = pkgs.haskell.packages.ghc8107;
          packages = {
            haskeline.source = inputs.haskeline;
          };
          settings = { 
            haskeline = {
              haddock = false;
              check = false;
              jailbreak = true;
            };
          };
        };

        packages.default = self'.packages.fswatch;
      };
    };
}