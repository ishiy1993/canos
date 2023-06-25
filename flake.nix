{
  description = "canos";
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };
  outputs = { self, nixpkgs, flake-utils }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = import nixpkgs { inherit system; };
        toPkg = attrs: pkgs.stdenv.mkDerivation {
          inherit (attrs) name src;
          nativeBuildInputs = [ pkgs.makeWrapper ];
          phases = [ "installPhase" ];
          installPhase = ''
            mkdir -p $out/bin
            cp $src $out/bin/${attrs.name}
            wrapProgram $out/bin/${attrs.name} --prefix PATH : ${pkgs.lib.makeBinPath [ pkgs.cabal2nix pkgs.jq]}
          '';
        };
      in
      {

        packages.canos-global = toPkg {
          name = "canos-global";
          src = ./scripts/canos-global.bash;
        };
        packages.canos-local = toPkg {
          name = "canos-local";
          src = ./scripts/canos-local.bash;
        };
      }
    );
}
