#!/bin/sh
cd `dirname $0`
PWD=`pwd`
COQTOPDIR=`coqtop -where`
set -e
set -v

##############################################################
## Generate Coq bytecode (requires our custom coqmktop -a)
##############################################################
coqmktop -g -a -no-start -I $COQTOPDIR/parsing main.ml -o coqlib.cma
./prepare_ocaml.sh
ocamlc -g -I $COQTOPDIR -noautolink -linkall -use-prims tmp/primitives-all coqlib.cma -o coqlib.byte

#####################
## copy Coq dirs
#####################
COQLIBSRC=$COQTOPDIR
COQLIBDST=$PWD/Coq4iPad/Coq4iPad/coq-8.4pl1
rm -rf $COQLIBDST/plugins $COQLIBDST/states $COQLIBDST/theories
cp -r $COQLIBSRC/plugins $COQLIBDST
cp -r $COQLIBSRC/states $COQLIBDST
cp -r $COQLIBSRC/theories $COQLIBDST
#mkdir -p $COQLIBDST/theories; cp -r $COQLIBSRC/theories/Init $COQLIBSRC/theories/Logic $COQLIBSRC/theories/Arith $COQLIBDST/theories

find $COQLIBDST/plugins -name '*.cmxs' |xargs rm

