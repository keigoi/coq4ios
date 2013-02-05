//
//  CQWrapper.m
//  Coq4iPad
//
//  Created by Keigo IMAI on 2/4/13.
//  Copyright (c) 2013 Keigo IMAI. All rights reserved.
//

#import "CQWrapper.h"

#import "CQUtil.h"
#import "CQ_convert.h"

@implementation CQWrapper

+(void) parse:(const char*)str match:(void (^)(int, NSRange))match
{
    caml_callback2(*caml_named_value("parse"), caml_copy_string(str), Val_ObjC_retain(match));
}

+(void) eval:(const char*)str
{
    caml_callback(*caml_named_value("eval"), caml_copy_string(str));
}

+(void) start
{
    const char* argv[] = {
        "ocamlrun",
        [[CQUtil fullPathOf:@"coqlib.byte"] UTF8String],
        "-coqlib",
        [[CQUtil fullPathOf:@"coq-8.4pl1"] UTF8String],
        0
    };
    caml_main((char**)argv);
}
@end