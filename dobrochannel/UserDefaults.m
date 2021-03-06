//
//  UserDefaults.m
//  dobrochannel
//
//  Created by shdwprince on 7/29/15.
//  Copyright © 2015 Vasiliy Horbachenko. All rights reserved.
//

#import "UserDefaults.h"

@implementation UserDefaults

+ (NSArray *) listOfBannedPosts {
    static NSMutableArray *list = nil;

    if (!list) {
        if ([UserDefaults enhanced]) {
            list = [NSMutableArray new];
        } else {
            NSString *str = [NSString stringWithContentsOfURL:[NSURL URLWithString:@"http://shadowprince.github.io/dobrochannel/apple_banned_posts.txt"]
                                                     encoding:NSUTF8StringEncoding
                                                        error:nil];
            
            list = [NSMutableArray new];
            for (NSString *comp in [str componentsSeparatedByString:@"\n"]) {
                if (![comp isEqualToString:@""]) {
                    [list addObject:[NSNumber numberWithInteger:comp.integerValue]];
                }
            }
        }
    }

    return list;
}

#pragma mark - meta

+ (NSMutableArray<NSString *> *) meta {
    static NSMutableArray *list = nil;

    if (!list) {
        NSString *str = [NSString stringWithContentsOfURL:[NSURL URLWithString:@"http://shadowprince.github.io/dobrochannel/meta.txt"]
                                                 encoding:NSUTF8StringEncoding
                                                    error:nil];

        list = [NSMutableArray new];
        for (NSString *comp in [str componentsSeparatedByString:@"\n"]) {
            if (![comp isEqualToString:@""] && ![comp hasPrefix:@"#"]) {
                [list addObject:comp];
            }
        }

        if (list.count == 0) {
            list = @[@"###", @"1999", @"###", @"1", ].mutableCopy;
        }
    }

    return list;
}

+ (NSNumber *) supportThreadNumber {
    return [NSNumber numberWithInteger:[UserDefaults meta][0].integerValue];
}

+ (BOOL) showReportButton {
    if ([UserDefaults enhanced]) {
        return NO;
    } else {
        return [UserDefaults meta][1].boolValue;
    }
}

#pragma mark - user defaults

+ (void) setupDefaultValues {
    NSString *pwd = [[[NSProcessInfo processInfo] globallyUniqueString] substringToIndex:8];

    NSDictionary *defaultValues = @{@"initial_setup": @YES,
                                    @"av_load_full": @YES,
                                    @"cr_load_full": @NO,
                                    @"cr_load_full_max_size": @333,
                                    @"cr_load_thumbs": @YES,
                                    @"cr_show_no_rating": @NO,
                                    @"post_password": pwd,
                                    };

    [defaultValues enumerateKeysAndObjectsUsingBlock:^(id  key, id  obj, BOOL * stop) {
        if (![[NSUserDefaults standardUserDefaults] valueForKey:key]) {
            [[NSUserDefaults standardUserDefaults] setValue:obj forKey:key];
        }
    }];
}

+ (BOOL) attachmentsViewerLoadFull {
    NSNumber *value = [[NSUserDefaults standardUserDefaults] valueForKey:@"av_load_full"];

    return value.boolValue;
}

+ (BOOL) attachmentsViewLoadFull {
    NSNumber *value = [[NSUserDefaults standardUserDefaults] valueForKey:@"aview_load_full"];

    return value.boolValue;
}

+ (BOOL) contentReaderLoadFull {
    NSNumber *value = [[NSUserDefaults standardUserDefaults] valueForKey:@"cr_load_full"];

    return value.boolValue;
}

+ (NSInteger) contentReaderLoadFullMaxSize {
    NSNumber *value = [[NSUserDefaults standardUserDefaults] valueForKey:@"cr_load_full_max_size"];

    return value.integerValue;
}

+ (BOOL) contentReaderLoadThumbnails {
    NSNumber *value = [[NSUserDefaults standardUserDefaults] valueForKey:@"cr_load_thumbs"];

    return value.boolValue;
}


+ (BOOL) showUnrated {
    NSNumber *value = [[NSUserDefaults standardUserDefaults] valueForKey:@"show_no_rating"];

    return [self enhanced] && value;
}

+ (NSInteger) maxRating {
    NSNumber *value = [[NSUserDefaults standardUserDefaults] valueForKey:@"max_rating"];

    return value.integerValue;
}

+ (NSString *) postPassword {
    return (NSString *) [[NSUserDefaults standardUserDefaults] valueForKey:@"post_password"];
}

+ (UIFont *) textFont {
    float value = [[[NSUserDefaults standardUserDefaults] valueForKey:@"text_size"] floatValue];
    float size =  floorf(value)  - 2.f ?: 12.f;

    //return [UIFont fontWithName:@"Helvetica Neue" size:size];
    return [UIFont systemFontOfSize:size];
}

+ (UIFont *) messageFont {
    float value = [[[NSUserDefaults standardUserDefaults] valueForKey:@"text_size"] floatValue];
    float size =  floorf(value) ?: 14.f;

    return [UIFont fontWithName:@"Helvetica Neue" size:size];
}

+ (BOOL) enhanced {
    return YES;
    /*
#ifdef RESTRICTIONS
    NSString *secret = [[NSUserDefaults standardUserDefaults] valueForKey:@"secret"];
    return secret != nil;
#else
    return YES;
#endif
     */
}

@end