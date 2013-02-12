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

static dispatch_queue_t camlQueue;


@implementation CQWrapper

+(void)initialize
{
    camlQueue = dispatch_queue_create("jp.keigoimai.Coq4iPad", NULL);
}

+(void) startRuntime
{
    dispatch_async(camlQueue, ^{
        NSLog(@"startRuntime");
        const char* argv[] = {
            "ocamlrun",
            [[CQUtil fullPathOf:@"coqlib.byte"] UTF8String],
            0
        };
        caml_main((char**)argv);
    });
}

+(void) startCoq:(NSString*)coqlib callback:(void(^)())callback
{
    dispatch_async(camlQueue, ^{
        NSLog(@"startCoq:%@", coqlib);
        caml_callback(*caml_named_value("start"), caml_copy_string([[CQUtil fullPathOf:coqlib] UTF8String]));
        dispatch_async(dispatch_get_main_queue(), callback);
    });
}

+(void) compile:(NSString*)file callback:(void(^)())callback
{
    dispatch_async(camlQueue, ^{
        NSLog(@"compile: %@", file);
        caml_callback(*caml_named_value("compile"), caml_copy_string([file UTF8String]));
        dispatch_async(dispatch_get_main_queue(), callback);
    });
}

+(void) loadInitial
{
    dispatch_async(camlQueue, ^{
        caml_callback(*caml_named_value("load_initial"), Val_unit);
    });
}

static NSArray* camlArray(value v) {
    NSMutableArray* arr = [NSMutableArray array];
    int len = caml_array_length(v);
    for(int i=0; i<len; i++) {
        [arr addObject:[NSString stringWithUTF8String:String_val(Field(v, i))]];
    }
    return arr;
}

static id in_caml(id(^fun)(void)) {
    int registered = caml_c_thread_register();
    @try {
        caml_acquire_runtime_system();
        return fun();
    } @finally {
        caml_release_runtime_system();
        if(registered) {
            caml_c_thread_unregister();
        }
    }
}


+(NSArray*) initTheories
{
    return in_caml(^{
        return camlArray(caml_callback(*caml_named_value("init_theories"), Val_unit));
    });
}


+(NSArray*) restTheories
{
    return in_caml(^{
        return camlArray(caml_callback(*caml_named_value("rest_theories"), Val_unit));
    });
}

+(void) parse:(const char*)str match:(void (^)(int, NSRange))match
{
    NSLog(@"parse:%s", str);
    caml_callback2(*caml_named_value("parse"), caml_copy_string(str), Val_ObjC_retain(match));
}

+(void) eval:(const char*)str
{
    dispatch_async(camlQueue, ^{
        NSLog(@"eval:%s", str);
        caml_callback(*caml_named_value("eval"), caml_copy_string(str));
    });
}

@end

double caml_Double_val2(value val)
{
    union { value v[2]; double d; } buffer;
    
    Assert(sizeof(double) == 2 * sizeof(value));
    buffer.v[0] = Field(val, 1);
    buffer.v[1] = Field(val, 0);
    return buffer.d;
}


value f(value x) {
    CAMLparam1(x);
    double v = Double_val(x);
    printf("%lf\n", v);
    double w = caml_Double_val2(x);
    printf("%lf\n", w);
    CAMLreturn(caml_copy_double(100));
}
