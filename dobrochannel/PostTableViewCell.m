//
//  PostTableViewCell.m
//  dobrochannel
//
//  Created by shdwprince on 7/21/15.
//  Copyright © 2015 Vasiliy Horbachenko. All rights reserved.
//

#import "PostTableViewCell.h"

@interface PostTableViewCell ()
@property BOOL prevOpacity;
@property NSMutableArray *answers;
@property CGFloat answersBaseHeight;
@property NSOperationQueue *queue;
@property NSDateFormatter *dateFormatter;
@property CGFloat postOffset;
//---
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *answersViewHeightConstraint;
@property (weak, nonatomic) IBOutlet UICollectionView *answersCollectionView;
@property (weak, nonatomic) IBOutlet UILabel *answersLabel;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *scrollViewWidthConstraint;
@property (weak, nonatomic) IBOutlet UIButton *headerButton;
@property (weak, nonatomic) IBOutlet UITableView *attachmentsView;
@end @implementation PostTableViewCell

- (void) awakeFromNib {
    self.queue = [NSOperationQueue new];
    self.answers = [NSMutableArray new];

    self.dynamicTextView = self.messageTextView;

    self.dynamicTableDelegate = [[AttachmentsTableDelegate alloc] init];
    self.dynamicTableView = self.attachmentsView;

    self.dynamicStackViewScrollWidthConstraint = self.scrollViewWidthConstraint;
    self.postOffset = 16.f;
    self.dynamicTextViewCombinedOffsets =
    self.postOffset // post offset
    + 3.f; // message view margin

    self.headerButton.contentVerticalAlignment = UIControlContentVerticalAlignmentCenter;
    self.headerButton.titleLabel.backgroundColor = [UIColor whiteColor];

    self.answersBaseHeight = 25.f;

    CGColorRef borderColor = [UIColor colorWithWhite:0.8f alpha:1.f].CGColor;
    CGFloat borderHeight = 0.5f;

    CALayer *border = [CALayer layer];
    border.frame = CGRectMake(0, 0, self.answersCollectionView.frame.size.width, borderHeight);
    border.backgroundColor = borderColor;
    [self.answersCollectionView.layer addSublayer:border];

    border = [CALayer layer];
    border.frame = CGRectMake(0, 0, self.answersLabel.frame.size.width, borderHeight);
    border.backgroundColor = borderColor;
    [self.answersLabel.layer addSublayer:border];

    [self.answersCollectionView registerNib:[UINib nibWithNibName:@"AnswerCollectionViewCell" bundle:nil] forCellWithReuseIdentifier:@"Cell"];

    self.dateFormatter = [[NSDateFormatter alloc] init];
    self.dateFormatter.dateStyle = NSDateFormatterShortStyle;
    self.dateFormatter.timeStyle = NSDateFormatterShortStyle;

    UIFont *font = [UserDefaults textFont];
    self.dateLabel.font = font;
    self.idLabel.font = font;

    self.translatesAutoresizingMaskIntoConstraints = YES;
    self.messageTextView.translatesAutoresizingMaskIntoConstraints = YES;
    self.attachmentsView.translatesAutoresizingMaskIntoConstraints = YES;
    self.answersCollectionView.translatesAutoresizingMaskIntoConstraints = YES;
    self.answersLabel.translatesAutoresizingMaskIntoConstraints = YES;
    self.dateLabel.translatesAutoresizingMaskIntoConstraints = YES;

    [super awakeFromNib];
}

- (void) populate:(NSManagedObject *)data
      attachments:(NSArray *)attachments {
    [super populate:data attachments:attachments];
    [self.attachmentsView reloadData];
    [self.answersCollectionView reloadData];

    self.idLabel.text = [NSString stringWithFormat:@"#%@", [data valueForKey:@"display_identifier"]];
    self.dateLabel.text = [self.dateFormatter stringFromDate:[data valueForKey:@"date"]];
    self.messageTextView.attributedText = [data valueForKey:@"attributedMessage"];
}

- (void) layoutSubviews {
    CGFloat left = self.postOffset + 3.f;
    left = self.dynamicTextViewCombinedOffsets;
    CGFloat top = 16.f;
    CGFloat height = self.frame.size.height - top;
    if (self.attachmentsCount) {
        self.messageTextView.frame = CGRectMake(self.dynamicLeftOffset + left, top, self.frame.size.width - self.dynamicLeftOffset - left, height);
        self.attachmentsView.frame = CGRectMake(left, top, self.dynamicLeftOffset, height);
    } else {
        self.messageTextView.frame = CGRectMake(left, top, self.frame.size.width - left, height);
        self.attachmentsView.frame = CGRectMake(0, 0, 0, 0);
    }

    if (self.answers.count) {
        CGRect mframe = self.messageTextView.frame;
        mframe.size.height -= self.answersBaseHeight;
        self.messageTextView.frame = mframe;

        self.answersLabel.frame = CGRectMake(mframe.origin.x,
                                             self.frame.size.height - self.answersBaseHeight,
                                             self.answersLabel.frame.size.width,
                                             self.answersBaseHeight);
        self.answersCollectionView.frame = CGRectMake(mframe.origin.x + self.answersLabel.frame.size.width,
                                                      self.frame.size.height - self.answersBaseHeight,
                                                      mframe.size.width - self.answersLabel.frame.size.width,
                                                      self.answersBaseHeight);
        self.answersLabel.hidden = NO;
    } else {
        self.answersCollectionView.frame = CGRectMake(0, 0, 0, 0);
        self.answersLabel.hidden = YES;
    }

    CGRect frame = self.headerButton.frame;
    frame.origin.x = self.frame.size.width - frame.size.width;
    self.headerButton.frame = frame;

    frame = self.idLabel.frame;
    frame.origin.x = floorf(self.frame.size.width - frame.size.width - self.headerButton.frame.size.width / 2);
    self.idLabel.frame = frame;

    frame = self.dateLabel.frame;
    frame.origin.x = left;
    frame.size.width = self.idLabel.frame.origin.x - left;
    self.dateLabel.frame = frame;

    [self.attachmentsView layoutSubviews];
    [super layoutSubviews];
}

- (void) populateForHeightCalculation:(NSManagedObject *)object
                          attachments:(NSArray *)attachments {
    self.dynamicText = [object valueForKey:@"attributedMessage"];
    self.answers = [NSMutableArray new];

    for (NSString *identifier in [[object valueForKey:@"answers"] componentsSeparatedByString:@","]) {
        if (identifier.length)
            [self.answers addObject:[NSNumber numberWithInteger:identifier.integerValue]];
    }

    [super populateForHeightCalculation:object
                            attachments:attachments];
}

- (void) setupAttachmentOffsetFor:(CGSize) parentSize {
    self.dynamicLeftOffset = floorf(parentSize.width / 3.5);
}

- (void) setBoardlinkTouchTarget:(id) target
                          action:(SEL) action {
    self.textViewDelegate = [[MessageTextViewDelegate alloc] initWithTarget:target action:action];
    self.textViewDelegate.contextObject = self.object;
    self.dynamicTextView.delegate = self.textViewDelegate;
}

- (void) setHeaderTouchTarget:(id) target
                       action:(SEL) action {
    [self.headerButton addTarget:target action:action forControlEvents:UIControlEventTouchUpInside];
}

- (CGFloat) calculatedHeight:(CGSize)parentSize {
    CGFloat attach = [self attachmentExpandHeight];
    CGFloat message = [self messageExpandHeight:parentSize] - (self.answers.count ? 0 : self.answersBaseHeight);
    CGFloat height = MAX(attach, message);

    return height;
}

- (void) setOpacity:(BOOL) set_op {
    if (self.prevOpacity == set_op) {
        return;
    } else {
        self.prevOpacity = set_op;
        UIColor *background = nil;
        
        if (set_op) {
            background = [UIColor clearColor];
        } else {
            background = [UIColor whiteColor];
        }
        
        for (UIView *view in @[self.dateLabel,
                               self.idLabel,
                               self.messageTextView,
                               self.attachmentsView, ]) {
            [view setValuesForKeysWithDictionary:@{@"backgroundColor": background,
                                                   @"opaque": [NSNumber numberWithBool:set_op], }];
        }
    }
}

#pragma mark answers collection view

- (void) collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath {
    NSNumber *identifier = self.answers[indexPath.row];
    [self.textViewDelegate fireActionWith:identifier.stringValue contextObject:self.object];
}

- (NSInteger) numberOfSectionsInCollectionView:(UICollectionView *)collectionView {
    return 1;
}

- (NSInteger) collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    return self.answers.count;
}

- (UICollectionViewCell *) collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    AnswerCollectionViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"Cell" forIndexPath:indexPath];
    NSNumber *answer = self.answers[indexPath.row];
    [cell populate:answer];
    return cell;
}

- (CGSize) collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath {
    CGFloat base_height = 25.f;
    CGRect bounds = [@">>00000000" boundingRectWithSize:CGSizeMake(MAXFLOAT, base_height)
                                               options:NSStringDrawingUsesLineFragmentOrigin
                                             attributes:@{NSFontAttributeName: [UIFont systemFontOfSize:13.f]}
                                               context:nil];
    return CGSizeMake(bounds.size.width, base_height);
}

@end