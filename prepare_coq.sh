#!/bin/sh
set -e

cd `dirname $0`

#############################
## Generate coq_jumptbl.h
#############################
SRC=coq-src/kernel/byterun/coq_instruct.h
DST=tmp/coq_jumptbl.h
if [ ! -f $DST ] || [ $SRC -nt $DST ]; then
  sed -n -e '/^  /s/ \([A-Z]\)/ \&\&coq_lbl_\1/gp' -e '/^}/q' $SRC >$DST || (RV=$?; rm -f $DST; exit $RV)
fi
