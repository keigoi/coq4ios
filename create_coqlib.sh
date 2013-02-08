#!/bin/sh
set -e
set -v
cd `dirname $0`
PWD=`pwd`
COQTOPDIR=`coqtop -where`

##############################################################
## Generate Coq bytecode (requires our custom coqmktop -a)
##############################################################
ocamllex coq-src/tools/coqdep_lexer.mll
ocamlc -c -I coq-src/tools coq-src/tools/coqdep_lexer.mli coq-src/tools/coqdep_lexer.ml coq-src/tools/coqdep_common.mli coq-src/tools/coqdep_common.ml
coqmktop -g -a -no-start -I $COQTOPDIR/kernel -I $COQTOPDIR/parsing -I $COQTOPDIR/library -I $COQTOPDIR/interp -I coq-src/tools coqdep_lexer.cmo coqdep_common.cmo main.ml -o coqlib.cma
./prepare_ocaml.sh
ocamlc -g -I $COQTOPDIR -noautolink -linkall -use-prims tmp/primitives-all coqlib.cma -o coqlib.byte

#######################
## make NMake_gen.v
#######################
make -C coq-src theories/Numbers/Natural/BigN/NMake_gen.v

#####################
## copy Coq dirs
#####################
COQLIBSRC=coq-src
COQLIBDST=$PWD/Coq4iPad/Coq4iPad/coq-8.4pl1
# clean
rm -rf $COQLIBDST/plugins $COQLIBDST/states $COQLIBDST/theories
mkdir -p $COQLIBDST/states
# copy plugin binaries
pushd $COQTOPDIR
  find plugins -type d -exec mkdir -p $COQLIBDST/{} \;
  find theories -type d -exec mkdir -p $COQLIBDST/{} \;
  find plugins -name '*.cm[ioa]' -exec cp {} $COQLIBDST/{} \;
  find theories -name '*.cm[ioa]' -exec cp {} $COQLIBDST/{} \;
popd
# copy NMake_gen.v
cp coq-src/theories/Numbers/Natural/BigN/NMake_gen.v $COQLIBDST/theories/Numbers/Natural/BigN/


