#!/bin/sh
set -e

# --- CHANGE HERE -- 
OCAMLHOST_PATH=/Users/keigoi/.opam/4.00.1+annot/bin
CAMLP5HOST_PATH=/Users/keigoi/.opam/4.00.1+annot/lib/camlp5
OCAMLXARM_PATH=/usr/local/ocamlxsim/bin
CAMLP5XARM_PATH=/usr/local/ocamlxsim/lib/ocaml/camlp5
# --- CHANGE HERE

ORIG_PATH=$PATH

cd `dirname $0`/coq-src

config1 () {
  echo '-- coq-arm configure phase 1 --'
  export PATH=$OCAMLHOST_PATH:$ORIG_PATH
  ./configure -local -with-doc no -coqide no -natdynlink no -with-geoproof no -camlp5dir $CAMLP5HOST_PATH
}

build1 () {
  echo '-- coq-arm build phase 1 --'
  time make VERBOSE:=1 world
  putaside
}

putaside ()
{
  # put aside all host-version cmx 
  rm -rf ../phase1-obj
  mkdir -p ../phase1-obj
  find . -type d -exec mkdir -p ../phase1-obj/{} \;
  find -E . \( -regex '.*\.cmxa?$' -or -name '*.[ao]' \) -exec mv {} ../phase1-obj/{} \;
}

config2 () {
  echo '-- coq-arm configure phase 2 --'
  export PATH=$OCAMLXARM_PATH:$ORIG_PATH
  ./configure -local -with-doc no -coqide no -natdynlink no -with-geoproof no -camlp5dir $CAMLP5XARM_PATH
  rm -rf _build myocamlbuild_config.ml
}

build2 () {
  echo '-- coq-arm build phase 2 --'
  time make -j8 -f ../Makefile.coqarm VERBOSE:=1 buildcmx
  make tools/coqdep_common.cmx
}

phase1 () {
    config1 && build1
}

phase2 () {
    config2 && build2
}

all () {
    phase1 && phase2
}

case "$1" in
config1) config1 ;;
build1) build1 ;;
config2) config2 ;;
build2) build2 ;;
phase1) phase1 ;;
phase2) phase2 ;;
putaside) putaside ;;
all) all ;;
*) echo "usage: $(basename $0) {all|phase1|phase2|config1|build1|config2|build2}" >&2;
   exit 1
   ;;
esac
