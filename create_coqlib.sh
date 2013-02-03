#!/bin/sh

##############################################################
## Generate Coq bytecode (requires our custom coqmktop -a)
##############################################################
coqmktop -a -no-start -o coqlib.cma

