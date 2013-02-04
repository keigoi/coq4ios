//
//  CQ_stubs.m
//  Coq4iPad
//
//  Created by Keigo IMAI on 2/4/13.
//  Copyright (c) 2013 Keigo IMAI. All rights reserved.
//

#include "CQWrapper.h"

#include "CQ_convert.h"


// call ObjC-callback callback_ with args which_ : int and range_ : int * int

value caml_parse_matched(value callback_, value which_, value range_) {
    CAMLparam3(callback_, which_, range_);
    
    void (^callback)(int, NSRange) = ObjC_val(callback_);
    
    callback(Int_val(which_), NSRange_val(range_));
    
    CAMLreturn(Val_unit);
}
