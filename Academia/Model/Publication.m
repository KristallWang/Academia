//
//  Publication.m
//  Academia
//
//  Created by Yutong Zhang on 2018/12/17.
//  Copyright © 2018 Yutong Zhang. All rights reserved.
//

#import "Publication.h"

@interface Publication ()

- (instancetype) initFromUserDefaultsWithId:(NSString *)id;

@end

@implementation Publication

- (instancetype)initFromUserDefaultsWithId:(NSString *)id {
    self = [self init];
    if (self) {
        NSDictionary *pubs = [[self class] getPubs];
        NSDictionary *detailDict = [pubs objectForKey:id];
        if (detailDict) {
            self.id = id;
            self.md5 = detailDict[@"md5"];
            self.details = detailDict;
        }
    }
    return self;
}

- (BOOL)isEqual:(id)object {
    if ([object isKindOfClass:[self class]]) {
        Publication *pub = object;
        return [self.id isEqualToString:pub.id];
    }
    return NO;
}

- (void)writeToUserDefaults {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSDictionary/*<NSString *, Publication *>*/ *pubs = [defaults dictionaryForKey:@"pubs"];
    if (!pubs) {
        pubs = [[NSDictionary alloc] init];
    }
    NSMutableDictionary *mpubs = [pubs mutableCopy];
    mpubs[self.id] = self.details;
    [defaults setObject:mpubs forKey:@"pubs"];
    [defaults synchronize];
}

- (void)removeFromUserDefaults {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSDictionary/*<NSString *, Publication *>*/ *pubs = [defaults objectForKey:@"pubs"];
    NSMutableDictionary *mpubs = [pubs mutableCopy];
    [mpubs removeObjectForKey:self.id];
    [defaults setObject:mpubs forKey:@"pubs"];
    [defaults synchronize];
}

+ (NSDictionary *)getPubs {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSDictionary/*<NSString *, Publication *>*/ *pubs = [defaults objectForKey:@"pubs"];
    return pubs;
}

+ (NSArray *)getIds {
    return [[self getPubs] allKeys];
}

+ (NSArray/*<Publication *>*/ *)getPubObjs {
    NSMutableArray *pubObjs = [[NSMutableArray alloc] init];
    for (NSString *id in [[self getPubs] allKeys]) {
        Publication *pub = [[Publication alloc] initFromUserDefaultsWithId:id];
        [pubObjs addObject:pub];
    }
    return pubObjs;
}

- (NSString *)description {
    return self.details.description;
}

@end
