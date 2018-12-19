//
//  Publication.h
//  Academia
//
//  Created by Yutong Zhang on 2018/12/17.
//  Copyright © 2018 Yutong Zhang. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface Publication : NSObject

@property (nonatomic, strong) NSString *id;
@property (nonatomic, strong) NSString *md5;
@property (nonatomic, strong) NSDictionary *details;

- (void)writeToUserDefaults;
- (void)removeFromUserDefaults;

+ (NSDictionary/*<Publication *>*/ *)getPubs;
+ (NSArray/*<NSString *>*/ *)getIds;
+ (NSArray/*<Publication *>*/ *)getPubObjs;

@end

NS_ASSUME_NONNULL_END
