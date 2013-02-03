#!/bin/sh
cd `dirname $0`
TMP=`pwd`/tmp
CFG=`pwd`/ocaml-config

mkdir -p $TMP

#######################
## Generate prims.c
#######################

PRIMS="alloc.c array.c compare.c extern.c floats.c gc_ctrl.c hash.c \
  intern.c interp.c ints.c io.c lexing.c md5.c meta.c obj.c parsing.c \
  signals.c str.c sys.c terminfo.c callback.c weak.c finalise.c stacks.c \
  dynlink.c backtrace.c"

if [ ! -f ../tmp/prims.c ]; then
  cd ocaml-src/byterun
  sed -n -e "s/CAMLprim value \([a-z0-9_][a-z0-9_]*\).*/\1/p" \
	    $PRIMS > $TMP/primitives
  cd ../..
  cat $TMP/primitives $CFG/primitives-coqtop |sort -u >$TMP/primitives-all

  (echo '#include "mlvalues.h"'; \
    echo '#include "prims.h"'; \
    sed -e 's/.*/extern value &();/' $TMP/primitives-all; \
    echo 'c_primitive caml_builtin_cprim[] = {'; \
    sed -e 's/.*/	&,/' $TMP/primitives-all; \
    echo '	 0 };'; \
    echo 'char * caml_names_of_builtin_cprim[] = {'; \
    sed -e 's/.*/	"&",/' $TMP/primitives-all; \
    echo '	 0 };') > $TMP/prims.c

fi


#########################
## Generate jumptbl.h
#########################
if [ ! -f $TMP/jumptbl.h ]; then
  cd ocaml-src/byterun
  sed -n -e '/^  /s/ \([A-Z]\)/ \&\&lbl_\1/gp' \
    -e '/^}/q' instruct.h > $TMP/jumptbl.h
  cd ../..
fi

#########################
## Generate version.h
#########################
if [ ! -f $TMP/version.h ]; then
  echo "#define OCAML_VERSION \"`sed -e 1q ocaml-src/VERSION`\"" > $TMP/version.h
fi