#!/bin/sh
set -e
set -v

###############################################################
## XXX Choose whether you run Coq4iPad on iPad or Simulator
###############################################################
# for real iPad, use this customized ocaml compiler
#OCAMLC=ocamlc_arm/ocamlc_arm
# for simulators
OCAMLC=ocamlc # for iPad Simulators

cd `dirname $0`
PWD=`pwd`
COQTOPDIR=`coqtop -where`
OCAMLTOPDIR=`ocamlc -where`

############################################
## Generate custom ocamlc for real iPads
############################################
make -C ocamlc_arm ocamlc_arm

###########################
## Generate coqlib.byte
###########################
ocamllex coq-src/tools/coqdep_lexer.mll
ocamlc -c -g -I coq-src/tools \
  coq-src/tools/coqdep_lexer.mli coq-src/tools/coqdep_common.mli \
  coq-src/tools/coqdep_lexer.ml coq-src/tools/coqdep_common.ml
ocamlc -c -g -rectypes \
  -I $COQTOPDIR/kernel -I $COQTOPDIR/parsing -I $COQTOPDIR/library -I $COQTOPDIR/interp \
  -I $COQTOPDIR/lib -I $COQTOPDIR/toplevel -I $COQTOPDIR/kernel/byterun \
  -I +camlp5 \
  -I coq-src/tools \
  pathmap.ml main.ml
ocamlc -a -g -o coqlib.cma \
  -I $COQTOPDIR \
  config/coq_config.cmo lib/lib.cma kernel/kernel.cma library/library.cma pretyping/pretyping.cma \
  interp/interp.cma proofs/proofs.cma parsing/parsing.cma tactics/tactics.cma toplevel/toplevel.cma \
  parsing/highparsing.cma tactics/hightactics.cma \
  coq-src/tools/coqdep_lexer.cmo coq-src/tools/coqdep_common.cmo \
  pathmap.cmo main.cmo

./prepare_ocaml.sh

$OCAMLC -o coqlib.byte \
  -linkall -noautolink -use-prims tmp/primitives-all \
  str.cma nums.cma unix.cma dynlink.cma \
  camlp5/gramlib.cma \
  coqlib.cma

#####################
## copy Coq dirs
#####################
COQLIBSRC=`coqtop -where`
COQLIBDST=$PWD/Coq4iPad/Coq4iPad/coq-8.4pl1
# clean
rm -rf $COQLIBDST/plugins $COQLIBDST/states $COQLIBDST/theories
mkdir -p $COQLIBDST/states
# copy plugin binaries
pushd $COQTOPDIR
  find plugins -type d -exec mkdir -p $COQLIBDST/{} \;
  find theories -type d -exec mkdir -p $COQLIBDST/{} \;
  find plugins \( -name '*.cm[ioa]' -or -name '*.vo' \) -exec cp {} $COQLIBDST/{} \;
  find theories \( -name '*.cm[ioa]' -or -name '*.vo' \) -exec cp {} $COQLIBDST/{} \;
popd
cp coq-src/states/MakeInitial.v $COQLIBDST/states/


