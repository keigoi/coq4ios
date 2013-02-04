#!/bin/sh
set -e
set -v

##############################################################
## Generate Coq bytecode (requires our custom coqmktop -a)
##############################################################
coqmktop -a -no-start -I `coqtop -where`/parsing main.ml -o coqlib.cma
./prepare_ocaml.sh
ocamlc -I `coqtop -where` -noautolink -use-prims tmp/primitives-all coqlib.cma -o coqlib.byte
