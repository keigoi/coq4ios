#include <caml/alloc.h>
#include <caml/custom.h>
#include <caml/config.h>
#include <caml/misc.h>
#include <caml/mlvalues.h>
#include <caml/fail.h>
#include <caml/memory.h>
#include <caml/callback.h>


value caml_double_for_target_arch(value d)
{
  CAMLparam1(d);
  CAMLlocal1(res);
  res = caml_alloc(Double_wosize, Double_tag);
  //assert(sizeof(int)*2==sizeof(double));
  union { int v[2]; double d; } buffer;
  buffer.d = Double_val(d);
  Field(res, 0) = buffer.v[1];
  Field(res, 1) = buffer.v[0];
  CAMLreturn(res);
}
