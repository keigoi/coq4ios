#!/bin/sh

#####################
## copy Coq dirs
#####################
COQLIBSRC=coq-src
COQLIBDST=$PWD/coq-8.4pl2-standard-libs-for-coq4ios

# clean
rm -rf $COQLIBDST/plugins $COQLIBDST/states $COQLIBDST/theories

# copy plugin binaries
pushd $COQLIBSRC
  find plugins -type d -exec mkdir -p $COQLIBDST/{} \;
  find theories -type d -exec mkdir -p $COQLIBDST/{} \;
  find plugins \( -name '*.vo' -or -name '*.v' \) -exec cp {} $COQLIBDST/{} \;
  find theories \( -name '*.vo' -or -name '*.v' \) -exec cp {} $COQLIBDST/{} \;
  mkdir -p $COQLIBDST/states
  cp states/initial.coq states/MakeInitial.v $COQLIBDST/states/
popd

rm -f $COQLIBDST.7z

# -mf=off turns off BCJ filter
cd $COQLIBDST
7z a -mf=off $COQLIBDST.7z .

