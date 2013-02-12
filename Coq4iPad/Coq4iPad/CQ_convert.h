//
//  CQ_convert.h
//  Coq4iPad
//
//  Created by Keigo IMAI on 2/4/13.
//  Copyright (c) 2013 Keigo IMAI. All rights reserved.
//

#import <Foundation/Foundation.h>

#include <caml/alloc.h>
#include <caml/custom.h>
#include <caml/config.h>
#include <caml/misc.h>
#include <caml/mlvalues.h>
#include <caml/fail.h>
#include <caml/memory.h>
#include <caml/callback.h>
#include <threads.h>
#undef callback
#undef initialize

// ObjC obj <-> OCaml value
#define ObjC_val(v) (__bridge id)(*((void**) Data_custom_val(v)))
value Val_ObjC_retain(id obj);

// NSRange <-> OCaml value
value Val_NSRange(NSRange range);
NSRange NSRange_val(value val);
