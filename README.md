# canos
cabal's plan.json to nix overlay scripts

## Note
This project is experimental and inspired by [stacklock2nix](https://github.com/cdepillabout/stacklock2nix).

The scripts of canos depend [cabal2nix](https://github.com/NixOS/cabal2nix) command and [jq](https://github.com/stedolan/jq) command.
And this project does not use [haskell.nix](https://github.com/input-output-hk/haskell.nix).

## Usage
1. Add canos to the inputs of `flake.nix`.

```nix
{
  description = "...";
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-22.11";
    flake-utils.url = "github:numtide/flake-utils";
    canos.url = "github:ishiy1993/canos";
    canos.inputs.nixpkgs.follows = "nixpkgs";
    canos.inputs.flake-utils.follows = "flake-utils";
  };
  outputs = { self, nixpkgs, flake-utils, canos }:
    flake-utils.lib.eachDefaultSystem (system:
      let
          pkgs = import nixpkgs { inherit system; };
          hsPkgs = pkgs.haskell.packages.ghc902;
      in
      {
        devShells.default = pkgs.mkShell {
          buildInputs = [
            hsPkgs.ghc
            hsPkgs.cabal-install
            hsPkgs.haskell-language-server

            pkgs.zlib
            canos.packages.${system}.canos-global
            canos.packages.${system}.canos-local
          ];
        };
      }
    );
}
```

2. Generate `nix/` by `canos-global` and `canos-local` in `nix develop`.

```
$ nix develop -c $SHELL
$ cabal build
$ canos-global
$ canos-local
$ exa --tree nix
nix
├── generated
│  ├── aeson.nix
│  ├── ...
│  └── zlib.nix
├── your-pkg-name.nix
├── haskell-overlay-global.nix
└── haskell-overlay-local.nix
$ git add nix
$ git commit
```

3. Use overlays in `flake.nix` and build by `nix build '.#your-pkg-name'`.

```nix
    let
        pkgs = import nixpkgs { inherit system; };
        hsPkgs = pkgs.haskell.packages.ghc902;
        hsCustomPkgs = hsPkgs.override (old: {
          overrides = pkgs.lib.composeManyExtensions [
            (import ./nix/haskell-overlay-local.nix {
              inherit (pkgs.haskell.lib) overrideCabal;
            })
            (import ./nix/haskell-overlay-global.nix {
              inherit (pkgs.haskell.lib) overrideCabal;
              attrs = {
                splitmix = { testu01 = null; };
                zlib = { inherit (pkgs) zlib; };
              };
            })
            (old.overrides or (final: prev: { }))
          ];
        });
    in
    {
      packages.your-pkg-name = hsCustomPkgs.your-pkg-name;
    }
```



