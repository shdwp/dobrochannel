//
//  NewPostViewController.h
//  dobrochannel
//
//  Created by shdwprince on 8/9/15.
//  Copyright © 2015 Vasiliy Horbachenko. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "BoardAPI.h"
#import "UserDefaults.h"

@interface NewPostViewController : UIViewController <UICollectionViewDataSource, UICollectionViewDelegate, UIImagePickerControllerDelegate, UINavigationControllerDelegate>
@property NSString *board;
@property NSNumber *thread_identifier;
@property NSAttributedString *inReplyToMessage;
@property NSNumber *inReplyToIdentifier;


@end