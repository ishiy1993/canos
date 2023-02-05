#!/usr/bin/env bash

set -e

cores=${CORES:-16}
plan_json=${1:-./dist-newstyle/cache/plan.json}
nix_dir=${2:-nix}
output_nix=${3:-haskell-overlay-local.nix}

mkdir -p ${nix_dir}

function generate() {
  nix_dir=$1
  nix_pkg_name=$2
  pkg_dir=$3

  pushd ${nix_dir} > /dev/null
  pkg_path=$(realpath --relative-to=$(pwd) ${pkg_dir})
  cabal2nix ${pkg_path} > ${nix_pkg_name}.nix
  echo "  ${nix_pkg_name} = build ./${nix_pkg_name}.nix (attrs.${nix_pkg_name} or { });"
  popd > /dev/null
}


export -f generate
libs=$(cat ${plan_json} |
  jq -r '."install-plan"[] | select(.style == "local") | ."pkg-name" + " " + ."pkg-src"."path"' |
  xargs -P 1 -I@ bash -c "generate ${nix_dir} @"
)

cat <<END_NIX > ${nix_dir}/${output_nix}
{ overrideCabal,
  attrs ? {},
  config ? {}, 
}:

final: prev:
let
  defaultConfig = { doCheck = false; doCoverage = false; doHaddock = false; doBenchmark = false; };
  cfg = defaultConfig // config;
  build = src: attrs: overrideCabal
    (final.callPackage src attrs)
    (old: { inherit (cfg) doCheck doCoverage doHaddock doBenchmark; });
in {
${libs}
}
END_NIX

