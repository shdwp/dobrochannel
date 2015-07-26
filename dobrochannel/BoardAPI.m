//
//  Networking.m
//  dobrochannel
//
//  Created by shdwprince on 7/19/15.
//  Copyright © 2015 Vasiliy Horbachenko. All rights reserved.
//

#import "BoardAPI.h"

@interface BoardAPI ()
@property NSOperationQueue *oqueue;
@property NSURLSessionDataTask *currentTask;
@property NSURLSession *imageLoadingSession;
@property NSMutableDictionary<NSURLSessionTask *, BoardAPIProgressCallback> *progressCallbacks;

@end @implementation BoardAPI
@synthesize delegate, currentTask;

+ (instancetype) api {
    static BoardAPI *api = nil;

    if (!api)
        api = [[BoardAPI alloc] init];

    return api;
}

- (instancetype) init {
    self = [super init];
    self.oqueue = [[NSOperationQueue alloc] init];

    NSURLSessionConfiguration *config = [NSURLSessionConfiguration defaultSessionConfiguration];
    config.requestCachePolicy = NSURLRequestReturnCacheDataElseLoad;

    self.imageLoadingSession = [NSURLSession sessionWithConfiguration:config];
    self.progressCallbacks = [NSMutableDictionary new];

    return self;
}


- (NSDictionary *) boardsList {
    NSArray *sortedNames = @[@"b",        @"u" ,        @"dt" ,
        @"vg" ,        @"r" ,        @"cr" ,        @"lor",        @"mu" ,        @"oe" ,
        @"s",
                             @"w",        @"hr"];
    NSMutableDictionary *boards = [@{@"b": @[@"Братство", @"Доска обо всем"],
                                     @"u": @[@"Университет", @"Dum docemus, discimus"],
                                     @"dt": @[@"Dates and datings", @"Знакомства, встречи, сходочки", ],
                                     @"vg": @[@"Видеоигры", @"", ],
                                     @"r": @[@"Просьбы", @"", ],
                                     @"cr": @[@"Творчество", @"Доска для контента, созданного доброаноном", ],
                                     @"lor": @[@"LOR", @"Доска о программном обеспечении, железе и прочей IT-утвари", ],
                                     @"mu": @[@"Музыка", @"", ],
                                     @"oe": @[@"Oekaki", @"Доска для набросков, мазни и коллективного рисования", ],
                                     @"s": @[@"Li/s/p", @"(defboard li/s/p (:documentation \"Программирование\"))", ],
                                     @"w": @[@"Обои", @"Красивые обои для рабочего стола", ],
                                     @"hr": @[@"Высокое разрешение", @"Картинки в высоком разрешении", ],
                                     } mutableCopy];

    /*
    NSArray *nodescription = @[[@"u/ /rf/ /dt/ /r/ /cr/ /lor/ /mu/ /oe/ /s/ /w/ /hr" componentsSeparatedByString:@"/ /"],
             [@"a/ /ma/ /sw/ /hau/ /azu" componentsSeparatedByString:@"/ /"],
             [@"tv/ /cp/ /gf/ /bo/ /di/ /vn/ /ve/ /wh/ /fur/ /to/ /bg/ /wn/ /slow/ /mad" componentsSeparatedByString:@"/ /"],
             [@"d/ /news" componentsSeparatedByString:@"/ /"], ];


    for (NSArray *array in nodescription) {
        for (NSString *board in array)
            boards[board] = @[board, @""];
    }*/


    return @{@"sorted_keys": sortedNames, @"data": boards};
}

- (void) requestThreadsFrom:(NSString *) board
                       page:(NSNumber *) page
              stateCallback: (BoardAPIProgressCallback) callback {
    [self loadThreadsFrom:board
                     page:page
            stateCallback:callback];
}

- (void) requestThread:(NSNumber *) threadId
                  from:(NSString *) board
         stateCallback: (BoardAPIProgressCallback) callback {
    [self loadThread:threadId from:board stateCallback:callback];
}

- (NSURLSessionDataTask *) requestImage:(NSString *)path
        stateCallback:(BoardAPIProgressCallback)stateCallback
       finishCallback:(BoardImageDownloadFinishCallback)finishCallback {
    NSString *fullUrl = [@"http://dobrochan.com/" stringByAppendingString:path];
    NSURL *url = [NSURL URLWithString:[fullUrl stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]];

    NSURLRequest *request = [NSURLRequest requestWithURL:url];
    NSURLSessionDataTask *task = [self.imageLoadingSession
                                  dataTaskWithRequest:request
                                  completionHandler:^(NSData * data, NSURLResponse * response, NSError * error) {
                                      UIImage *image = [UIImage imageWithData:data];
                                      if (image) {
                                          dispatch_sync(dispatch_get_main_queue(), ^{
                                              finishCallback(image);
                                          });
                                      }
                                  }];

    [self.progressCallbacks setObject:stateCallback forKey:task];
    [task addObserver:self forKeyPath:@"countOfBytesReceived" options:NSKeyValueObservingOptionNew context:nil];
    [task resume];
    return task;
}

- (void) cancelRequest {
    if (self.currentTask) {
        [self.currentTask removeObserver:self forKeyPath:@"countOfBytesReceived"];
        [self.currentTask cancel];

        self.currentTask = nil;
    }
}

#pragma mark thread helpers

- (void) didParsedThread:(NSDictionary *)thread {
    dispatch_sync(dispatch_get_main_queue(), ^{
        [self.delegate didReceivedThread:thread];
    });
}

- (void) didParsedPost:(NSDictionary *)post {
    dispatch_sync(dispatch_get_main_queue(), ^{
        [self.delegate didReceivedPost:post];
    });
}

#pragma mark private helper methods

- (void) observeValueForKeyPath:(NSString *)keyPath
                       ofObject:(id)object
                         change:(NSDictionary *)change
                        context:(void *)context {
    if ([keyPath isEqualToString:@"countOfBytesReceived"]) {
        BoardAPIProgressCallback cb = [self.progressCallbacks objectForKey:object];
        NSURLSessionTask *task = (NSURLSessionTask *) object;
        
        dispatch_sync(dispatch_get_main_queue(), ^{
            cb(task.countOfBytesReceived, task.countOfBytesExpectedToReceive);
        });
    }
}

#pragma mark abstract methods

- (void) loadThreadsFrom:(NSString *) board
                    page:(NSNumber *) page
           stateCallback:(BoardAPIProgressCallback) block {
    [self cancelRequest];

    NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:@"http://dobrochan.com/%@/%@.json", board, page]];
//    url = [NSURL URLWithString:@"http://localhost/broken.json"];

    BoardRequestParser *parser = [[BoardRequestParser alloc] initWithDelegate:self];
    NSURLSessionConfiguration *config = [NSURLSessionConfiguration defaultSessionConfiguration];
    config.requestCachePolicy = NSURLRequestReloadIgnoringLocalCacheData;

    NSURLSession *session = [NSURLSession sessionWithConfiguration:config
                                                          delegate:parser
                                                     delegateQueue:nil];

    NSURLSessionDataTask *task = [session dataTaskWithRequest:[NSURLRequest requestWithURL:url]];
    [self.progressCallbacks setObject:block forKey:task];

    self.currentTask = task;
    [task resume];
    [task addObserver:self forKeyPath:@"countOfBytesReceived" options:NSKeyValueObservingOptionNew context:nil];
}

- (void) loadThread:(NSNumber *) threadId
               from:(NSString *) board
      stateCallback:(BoardAPIProgressCallback) block {
    [self cancelRequest];

    NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:@"http://dobrochan.com/%@/res/%@.json", board, threadId]];
//    url = [NSURL URLWithString:@"http://192.168.12.177/3814061.json"];

    BoardRequestParser *parser = [[BoardRequestParser alloc] initWithDelegate:self];
    NSURLSession *session = [NSURLSession sessionWithConfiguration:[NSURLSessionConfiguration defaultSessionConfiguration]
                                                          delegate:parser
                                                     delegateQueue:nil];

    NSURLRequest *request = [NSURLRequest requestWithURL:url cachePolicy:NSURLRequestReloadIgnoringCacheData timeoutInterval:NSTimeIntervalSince1970];
    NSURLSessionDataTask *task = [session dataTaskWithRequest:request];

    self.currentTask = task;
    [self.progressCallbacks setObject:block forKey:task];

    [task resume];
    [task addObserver:self forKeyPath:@"countOfBytesReceived" options:NSKeyValueObservingOptionNew context:nil];
}


@end
