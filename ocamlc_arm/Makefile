OCAMLLIB=`ocamlc -where`
COMPLIB=$(OCAMLLIB)/compiler-libs
OCAMLROOT=$(PWD)/../ocaml-src
BYTECOMPDIR=$(OCAMLROOT)/bytecomp

BYTECOMP_SRC_PART=$(BYTECOMPDIR)/meta.ml $(BYTECOMPDIR)/instruct.ml $(BYTECOMPDIR)/bytegen.ml \
  $(BYTECOMPDIR)/printinstr.ml $(BYTECOMPDIR)/opcodes.ml $(BYTECOMPDIR)/emitcode.ml \
  $(BYTECOMPDIR)/bytesections.ml $(BYTECOMPDIR)/dll.ml

BYTECOMP_MLI_PART=$(filter-out $(BYTECOMPDIR)/opcodes.mli,$(BYTECOMP_SRC_PART:%.ml=%.mli))

BYTECOMP_SRC_REST= \
  $(BYTECOMPDIR)/bytelink.ml $(BYTECOMPDIR)/bytelibrarian.ml $(BYTECOMPDIR)/bytepackager.ml \
  $(OCAMLROOT)/driver/errors.ml $(OCAMLROOT)/driver/compile.ml

BYTECOMP_MLI_REST=$(BYTECOMP_SRC_REST:%.ml=%.mli)

ocamlc_arm:
	cp $(OCAMLROOT)/bytecomp/symtable.ml $(OCAMLROOT)/bytecomp/symtable.mli . && patch -p2 < ./symtable.ml.patch
	pushd $(OCAMLROOT) && make bytecomp/opcodes.ml && popd
	ocamlc -c -I +compiler-libs $(BYTECOMP_MLI_PART)
	ocamlc -c -I +compiler-libs symtable.mli
	ocamlc -c -I +compiler-libs $(BYTECOMP_MLI_REST)
	ocamlc -c -I $(BYTECOMPDIR) -I +compiler-libs $(BYTECOMP_SRC_PART)
	ocamlc -c -I $(BYTECOMPDIR) -I +compiler-libs symtable.ml
	ocamlc -c -I $(BYTECOMPDIR) -I +compiler-libs $(BYTECOMP_SRC_REST)
	gcc -c -I`ocamlc -where` floats-arm.c
	ocamlc -o ocamlc_arm -I $(BYTECOMPDIR) -I +compiler-libs -custom ocamlcommon.cma $(BYTECOMP_SRC_PART:%.ml=%.cmo) symtable.cmo $(BYTECOMP_SRC_REST:%.ml=%.cmo) $(OCAMLROOT)/driver/main.ml floats-arm.o
