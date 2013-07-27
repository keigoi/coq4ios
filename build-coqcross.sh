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

check () {
  if [ -e COQ_CROSS -a "`cat COQ_CROSS`" != "$1" ]; then
    echo "Current Coq build at `pwd` is not $1 but `cat COQ_CROSS`."
    if [ "stop" = "$2" ]; then
      echo "Stop."
      exit 1
    else
      read -p "Continue? [y/N] "
      if [ "$REPLY" != "y" -a "$REPLY" != "Y" ]; then
      exit 1
      fi
    fi
  fi
}

configure_cross () {
  flag=$1
  target_ocaml_bin=$2

  check $flag

  echo "-- Cleaning --"
  make clean; git clean -fX

  echo $flag > COQ_CROSS

  echo "-- Building coqdep_boot with host arch --"
  export PATH=$OCAMLHOSTBIN:$ORIG_PATH
  ./configure -local -with-doc no -coqide no -natdynlink no -with-geoproof no -camlp5dir $CAMLP5HOST
  time make -j8 bin/coqdep_boot

  echo "-- Configuring Coq binaries build for $flag --"
  export PATH=$target_ocaml_bin:$ORIG_PATH
  ./configure -local -with-doc no -coqide no -natdynlink no -with-geoproof no -camlp5dir $target_ocaml_bin/../lib/ocaml/camlp5
}

build_cross () {
  flag=$1
  target_ocaml_bin=$2

  check $flag stop

  echo "-- Building Coq binaries for $flag --"
  export PATH=$target_ocaml_bin:$ORIG_PATH
  time make -j8 -f ../Makefile.coqcross buildcmx
}


install_lib () {
  if [ ! -e COQ_CROSS ]; then
    echo "No Coq cross-build exists at `pwd`."; exit 1
  fi

  check $1 stop

  echo "-- Installing Coq binaries for $1 into $2 --"
  make -f ../Makefile.coqcross INSTALL_CMX_DIR:=$2 install
}


configure_host () {
  check "host"

  echo "host" > COQ_CROSS

  echo "-- Configuring Coq host build --"
  export PATH=$OCAMLHOSTBIN:$ORIG_PATH
  ./configure -local -with-doc no -coqide no -natdynlink no -with-geoproof no -camlp5dir $CAMLP5HOST
}

build_host () {
  check "host" stop

  echo "-- Building Coq host build --"
  export PATH=$OCAMLHOSTBIN:$ORIG_PATH
  time make -j8 world
}

configure_xarm () {
  configure_cross xarm $OCAMLXARMBIN
}

configure_xsim () {
  configure_cross xsim $OCAMLXSIMBIN
}

build_xarm () {
  build_cross xarm $OCAMLXARMBIN
}

build_xsim () {
  build_cross xsim $OCAMLXSIMBIN
}

install_xarm () {
  install_lib xarm $INSTALL_COQLIB_XARM
}

install_xsim () {
  install_lib xsim $INSTALL_COQLIB_XSIM
}

xarm () {
  configure_xarm && build_xarm
}

xsim () {
  configure_xarm && build_xsim
}

host () {
  configure_host && build_host
}

case "$1" in
xarm) xarm ;;
xsim) xsim ;;
host) host ;;
configure_xarm) configure_xarm ;;
configure_xsim) configure_xsim ;;
configure_host) configure_host ;;
build_xarm) build_xarm ;;
build_xsim) build_xsim ;;
build_host) build_host ;;
install_xarm) install_xarm;;
install_xsim) install_xsim;;
all) all ;;
*) echo "usage: $(basename $0) {xarm|xsim|host|configure_(xarm|xsim|host)|build_(xarm|xsim|host)|install_(xarm|xsim)}" >&2;
   exit 1
   ;;
esac
