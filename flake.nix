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
  let
  # Overriding GHC to use perf counters provided by linux perf tools
  ghc-overlay = self: super: {
    haskell = super.haskell // {
      compiler = super.haskell.compiler // {
        ghc8107-perf-events = (super.haskell.compiler.ghc8107.overrideAttrs (drv: {
          src = ./ghc-8.10.7-sdist.tar.xz;
          patches = drv.patches ++ [ ./ghc-patches/0001-Patch-primop-update.patch ./ghc-patches/0001-Add-a-perf-counters-RTS-flag-to-enable-linux-perf-co.patch ./ghc-patches/0001-Disable-LINUX_PERF_EVENTS-and-improve-the-compile-sp.patch ];
          preConfigure = ''
            echo ${drv.version} >VERSION
            patchShebangs boot
            ./boot
          '' + drv.preConfigure or "";
        })).override {
          bootPkgs = super.haskell.packages.ghc865Binary // {
            happy = super.haskell.packages.ghc865Binary.happy_1_19_12;
          };
        };
      };
      packages = super.haskell.packages // {
        ghc8107-perf-events = super.haskell.packages.ghc884.override {
          buildHaskellPackages = self.buildPackages.haskell.packages.ghc8107-perf-events;
          ghc = self.buildPackages.haskell.compiler.ghc8107-perf-events;
        };
      };
    };
  };
  in
    flake-parts.lib.mkFlake { inherit inputs; } {
      systems = import inputs.systems;
      imports = [ inputs.haskell-flake.flakeModule ];

      perSystem = { self',system, pkgs, ... }: {
        _module.args.pkgs = import inputs.nixpkgs {
          inherit system;
          overlays = [
            ghc-overlay
          ];
        };
        haskellProjects.default = {
          basePackages = pkgs.haskell.packages.ghc8107-perf-events.override { all-cabal-hashes = builtins.fetchurl { url = "https://github.com/commercialhaskell/all-cabal-hashes/archive/6e6d35424e43abfb19b1dc6a128d918229094354.tar.gz"; sha256 = "0661am7rjs4cm9zmfnnbfxwlax4a88a5x50812ffn570jlsixw6i"; }; };
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