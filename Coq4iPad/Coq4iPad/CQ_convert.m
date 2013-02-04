//
//  CQ_convert.m
//  Coq4iPad
//
//  Created by Keigo IMAI on 2/4/13.
//  Copyright (c) 2013 Keigo IMAI. All rights reserved.
//

#import "CQ_convert.h"


static void release_ObjC_val(value camlval) { // ファイナライザ. GC時に参照カウントを減らす
    CFRelease(*(void**)Data_custom_val(camlval));
}

/**
 * NSObject を OCaml の抽象型値に変換する.
 * OCamlのファイナライザが オブジェクト を解放するようになる.
 */
value Val_ObjC_retain(id obj)
{
    CAMLparam0();
    CAMLlocal1(v);
    
    v = caml_alloc_final((sizeof(id)+sizeof(value))/sizeof(value), release_ObjC_val, 0, 1);
    *(void**)Data_custom_val(v) = (__bridge_retained void*)obj;
    CAMLreturn(v);
}


value Val_NSRange(NSRange range) {
    CAMLparam0();
    CAMLlocal1(v);
    
    v= caml_alloc_tuple(2);
    Store_field(v, 0, Val_int(range.location));
    Store_field(v, 1, Val_int(range.length));
    
    CAMLreturn(v);
}


NSRange NSRange_val(value val) {
    CAMLparam1(val);
    NSRange range;
    
    range.location = Int_val(Field(val, 0));
    range.length = Int_val(Field(val, 1));
    
    CAMLreturnT(NSRange, range);
}

