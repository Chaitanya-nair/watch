{
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixpkgs-unstable";
    flake-parts.url = "github:hercules-ci/flake-parts";
    haskell-flake.url = "github:srid/haskell-flake";
    haskeline.url = "github:judah/haskeline/019e08f2c91b7cc45e5fb98189193a9f5c2d2d57";
    haskeline.flake = false;
  };
  outputs = inputs@{ self, nixpkgs, flake-parts, ... }:
    flake-parts.lib.mkFlake { inherit inputs; } {
      systems = nixpkgs.lib.systems.flakeExposed;
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
