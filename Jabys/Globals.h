//
//  Globals.h
//  Jabys
//
//  Created by Ken Yu on 10/1/13.
//  Copyright (c) 2013 Ken Yu. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface Globals : NSObject
@property (strong, nonatomic) NSString *baseUrl;
+ (void)load;
+ (NSString *)baseUrl;
@end
