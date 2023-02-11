{
  description = "canos";
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-22.11";
    flake-utils.url = "github:numtide/flake-utils";
  };
  outputs = { self, nixpkgs, flake-utils }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = import nixpkgs { inherit system; };
      in
      {
        # packages.canos-global = pkgs.writeShellApplication {
        #   name = "canos-global";
        #   runtimeInputs = [ pkgs.cabal2nix pkgs.jq ];
        #   text = builtins.readFile ./scripts/canos-global.bash;
        # };
        packages.canos-global = pkgs.stdenv.mkDerivation {
          name = "canos-global";
          src = ./scripts/canos-global.bash;
          propagatedInputs = [
            pkgs.cabal2nix
            pkgs.jq
          ];
          phases = [ "installPhase" ];
          installPhase = ''
            mkdir -p $out/bin
            cp $src $out/bin/canos-global
          '';
        };
      }
    );
}
