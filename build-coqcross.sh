#!/bin/sh
set -e

. `dirname $0`/Makefile.config

OCAMLHOSTBIN=$OCAMLHOST/bin
OCAMLXARMBIN=$OCAMLXARM/bin
OCAMLXSIMBIN=$OCAMLXSIM/bin

INSTALL_COQLIB_XARM=$OCAMLXARM/lib/ocaml/coqlib
INSTALL_COQLIB_XSIM=$OCAMLXSIM/lib/ocaml/coqlib

ORIG_PATH=$PATH

cd `dirname $0`/coq-src

build () {
  echo "-- Cleaning --"
  make clean; git clean -fX

  echo $1 > COQ_CROSS
  target_ocaml_bin=$2

  echo "-- Building coqdep_boot with host arch --"
  export PATH=$OCAMLHOSTBIN:$ORIG_PATH
  ./configure -local -with-doc no -coqide no -natdynlink no -with-geoproof no -camlp5dir $CAMLP5HOST
  time make -j8 bin/coqdep_boot

  echo "-- Building coq libraries for $flag --"
  export PATH=$target_ocaml_bin:$ORIG_PATH
  ./configure -local -with-doc no -coqide no -natdynlink no -with-geoproof no -camlp5dir $target_ocaml_path/lib/ocaml/camlp5
  time make -j8 -f ../Makefile.coqcross buildcmx
}

install_lib () {
  if [ ! -e COQ_CROSS ]; then
    echo "No Coq build exists at `pwd`."; exit 1
  fi
  if [ "`cat COQ_CROSS`" != $1 ]; then
    echo "Current Coq build at `pwd` is not for $1 but `cat COQ_CROSS`."; exit 1
  fi
  make -f ../Makefile.coqcross INSTALL_CMX_DIR:=$2 install
}

build_xarm () {
  build xarm $OCAMLXARMBIN
}

build_xsim () {
  build xsim $OCAMLXSIMBIN
}

install_xarm () {
  install_lib xarm $INSTALL_COQLIB_XARM
}

install_xsim () {
  install_lib xsim $INSTALL_COQLIB_XSIM
}

xarm () {
  build_xarm && install_xarm
}

xsim () {
  build_xsim && install_xsim
}

all () {
  build_xarm && install_xarm && build_xsim && install_xsim
}

case "$1" in
xarm) xarm ;;
xsim) xsim ;;
build_xarm) build_xarm ;;
build_xsim) build_xsim ;;
install_xarm) install_xarm;;
install_xsim) install_xsim;;
all) all ;;
*) echo "usage: $(basename $0) {all|xarm|xsim|build_xarm|build_xsim|install_xarm|install_xsim}" >&2;
   exit 1
   ;;
esac
