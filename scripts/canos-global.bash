#!/usr/bin/env bash

set -e

cores=${CORES:-16}
plan_json=${1:-./dist-newstyle/cache/plan.json}
nix_dir=${2:-nix}
output_nix=${3:-haskell-overlay.nix}

mkdir -p ${nix_dir}

nix_generated_dirname=generated
rm -rf ${nix_dir}/${nix_generated_dirname}
mkdir -p ${nix_dir}/${nix_generated_dirname}

function generate() {
  nix_dir=$1
  nix_generated_dirname=$2
  nix_pkg_name=$3
  nix_pkg_filename=$4
  nix_pkg_name_version=$5

  cabal2nix --no-check --no-haddock "cabal://${nix_pkg_name_version}" > ${nix_dir}/${nix_generated_dirname}/${nix_pkg_filename}
  echo "  ${nix_pkg_name} = buildGlobal ./${nix_generated_dirname}/${nix_pkg_filename} (attrs.${nix_pkg_name} or { });"
}


export -f generate
libs=$(cat ${plan_json} |
  jq -r -c '."install-plan"[] | select(.type == "configured" and .style == "global") | .style + " " + ."pkg-name" + " " + ."pkg-version"' |
  sort |
  uniq |
  awk '{print $2, $2 ".nix", $2 "-" $3}' |
  xargs -P ${cores} -I@ bash -c "generate ${nix_dir} ${nix_generated_dirname} @"
)


cat <<END_NIX > ${nix_dir}/${output_nix}
{ overrideCabal,
  attrs ? {},
  globalConfig ? { doCheck = false; doCoverage = false; doHaddock = false; doBenchmark = false; },
}:

final: prev:
let
  buildGlobal = src: attrs: overrideCabal
    (final.callPackage src attrs)
    (old: { inherit (globalConfig) doCheck doCoverage doHaddock doBenchmark; });
in {
${libs}
}
END_NIX
