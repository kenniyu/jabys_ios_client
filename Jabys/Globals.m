//
//  Globals.m
//  Jabys
//
//  Created by Ken Yu on 10/1/13.
//  Copyright (c) 2013 Ken Yu. All rights reserved.
//

#import "Globals.h"

@implementation Globals
static NSString* baseUrl = nil;

+ (void)load {
    baseUrl = @"http://localhost:3000";
}

+ (NSString *)baseUrl
{
    return baseUrl;
}
@end
