//
//  BoardPostResponseParser.h
//  dobrochannel
//
//  Created by shdwprince on 8/12/15.
//  Copyright © 2015 Vasiliy Horbachenko. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface BoardWebResponseParser : NSObject
+ (NSArray *) parseErrorsFromPostData:(NSData *) data;
+ (NSArray *) parseErrorsFromDeleteData:(NSData *) data;

@end