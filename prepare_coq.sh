#!/bin/sh
set -e
set -v

cd `dirname $0`

#############################
## Generate coq_jumptbl.h
#############################
SRC=coq-src/kernel/byterun/coq_instruct.h
DST=tmp/coq_jumptbl.h
if [ ! -f $DST ] || [ $SRC -nt $DST ]; then
  sed -n -e '/^  /s/ \([A-Z]\)/ \&\&coq_lbl_\1/gp' -e '/^}/q' $SRC >$DST || (RV=$?; rm -f $DST; exit $RV)
fi


#############################
## Copy *.v files
#############################
COQLIBSRC=coq-src
COQLIBDST=$PWD/Coq4iPad/Coq4iPad/coq-8.4pl1

pushd $COQLIBSRC
  for i in plugins states theories; do
    find $i -type d -exec mkdir -p $COQLIBDST/{} \;
    find $i -name '*.v' -exec cp {} $COQLIBDST/{} \;
  done
popd
