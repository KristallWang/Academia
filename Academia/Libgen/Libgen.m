//
//  LibgenSearch.m
//  Academia
//
//  Created by Yutong Zhang on 2018/12/17.
//  Copyright © 2018 Yutong Zhang. All rights reserved.
//

#import "Libgen.h"

NSArray *GetPublicationDetails(NSArray *, NSString **);
Publication *ExtractPublication(NSDictionary *);
NSArray *ExtractIdsFromPage(NSString *html, NSString **);

static NSString * libgenIoSearchFormat = @"http://libgen.io/search.php?req=%@&page=%d";
static NSString * libgenIoJsonFormat = @"http://libgen.io/json.php?ids=%@&fields=Id,Author,Title,ISBN,Topic,Edition,Publisher,City,Periodical,Year,Pages,Language,Size,Extension,MD5,timeadded,timelastmodified,coverurl";
static NSString * libgenIoCoverFormat = @"http://libgen.io/covers/%@";
static NSString * libgenIoDownloadFormat = @"http://libgen.io/get.php?md5=%@";

static NSString *paginatorNumberRegex = @"(\\d*),\\s//\\sобщее число страниц";
static NSString *idRegex1 = @"<tr valign=top bgcolor=><td>(\\d*)</td>";
static NSString *idRegex2 = @"<tr valign=top bgcolor=#C6DEFF><td>(\\d*)</td>";

NSArray *ExtractIdsFromPage(NSString *html, NSString **error) {
    NSError *err;
    NSRegularExpression *regex1 = [NSRegularExpression regularExpressionWithPattern:idRegex1 options:NSRegularExpressionDotMatchesLineSeparators error:&err];
    if (err.code){
        *error = err.localizedDescription;
        return nil;
    }
    NSRegularExpression *regex2 = [NSRegularExpression regularExpressionWithPattern:idRegex2 options:NSRegularExpressionDotMatchesLineSeparators error:&err];
    if (err.code){
        *error = err.localizedDescription;
        return nil;
    }
    
    NSMutableArray *res = [[NSMutableArray alloc] init];
    NSArray *idMatches1 = [regex1 matchesInString:html options:0 range:NSMakeRange(0, [html length])];
    for (NSTextCheckingResult *match in idMatches1) {
        NSRange pageNumberRange = [match rangeAtIndex:1];
        [res addObject:[html substringWithRange:pageNumberRange]];
    }
    NSArray *idMatches2 = [regex2 matchesInString:html options:0 range:NSMakeRange(0, [html length])];
    for (NSTextCheckingResult *match in idMatches2) {
        NSRange pageNumberRange = [match rangeAtIndex:1];
        [res addObject:[html substringWithRange:pageNumberRange]];
    }
    
    return res;
}

NSArray/*<Publication *>*/ * __nullable SearchForPublications(NSString *keywords, NSString **error) {
    NSError *err;
    NSURL *searchURL = [NSURL URLWithString:[NSString stringWithFormat:libgenIoSearchFormat, keywords, 1]];
    NSData *response = [NSData dataWithContentsOfURL:searchURL options:NSDataReadingMappedIfSafe error:&err];
    if (err.code){
        *error = err.localizedDescription;
        return nil;
    }
    NSString *html = [[NSString alloc] initWithData:response encoding:NSUTF8StringEncoding];
    
    NSRegularExpression *paginatorRegex = [NSRegularExpression regularExpressionWithPattern:paginatorNumberRegex options:NSRegularExpressionDotMatchesLineSeparators error:&err];
    if (err.code){
        *error = err.localizedDescription;
        return nil;
    }
    
    NSArray *paginatorMatches = [paginatorRegex matchesInString:html options:0 range:NSMakeRange(0, [html length])];
    int pageNumber = 0;
    for (NSTextCheckingResult *match in paginatorMatches) {
        NSRange pageNumberRange = [match rangeAtIndex:1];
        pageNumber = [[html substringWithRange:pageNumberRange] intValue];
    }
    
    NSMutableArray *ids = [[NSMutableArray alloc] init];
    if (pageNumber) {
        for (int i = 1; i <= pageNumber; i++) {
            NSURL *searchURL = [NSURL URLWithString:[NSString stringWithFormat:libgenIoSearchFormat, keywords, i]];
            NSData *response = [NSData dataWithContentsOfURL:searchURL options:NSDataReadingMappedIfSafe error:&err];
            if (err.code){
                *error = err.localizedDescription;
                return nil;
            }
            NSString *page = [[NSString alloc] initWithData:response encoding:NSUTF8StringEncoding];
            NSString *errStr;
            [ids addObjectsFromArray:ExtractIdsFromPage(page, &errStr)];
            if (errStr) {
                *error = errStr;
                return nil;
            }
        }
    } else {
        NSString *errStr;
        [ids addObjectsFromArray:ExtractIdsFromPage(html, &errStr)];
        if (errStr) {
            *error = errStr;
            return nil;
        }
    }
    [ids sortUsingComparator:^NSComparisonResult(NSString *id1, NSString *id2) {
        if ([id1 intValue] < [id2 intValue])
            return (NSComparisonResult)NSOrderedAscending;
        if ([id1 intValue] > [id2 intValue])
            return (NSComparisonResult)NSOrderedDescending;
        return (NSComparisonResult)NSOrderedSame;
    }];
    NSLog(@"%@", ids);
    
//    NSString *errStr;
//    NSArray *res = GetPublicationDetails(ids, &errStr);
//    if (errStr) {
//        *error = errStr;
//        return nil;
//    }
    
#define MAX_IDS_PER_REQUEST 20
    int length    = ids.count,
        round     = length / MAX_IDS_PER_REQUEST,
        remainder = length - (round * MAX_IDS_PER_REQUEST);
    NSMutableArray *res = [[NSMutableArray alloc] init];
    NSString *errStr;
    int i;
    for (i = 0; i < round; i++) {
        NSArray *subIds = [ids subarrayWithRange:NSMakeRange(i * MAX_IDS_PER_REQUEST, MAX_IDS_PER_REQUEST)];
        NSArray *subPub = GetPublicationDetails(subIds, &errStr);
        if (errStr) {
            *error = errStr;
            return nil;
        }
        [res addObjectsFromArray:subPub];
    }
    [res addObjectsFromArray:GetPublicationDetails([ids subarrayWithRange:NSMakeRange(i * MAX_IDS_PER_REQUEST, remainder)], &errStr)];
    if (errStr) {
        *error = errStr;
        return nil;
    }
    return res;
}

NSData *RegularizeSearchResponse(NSData *response) {
    return [[[[NSString alloc] initWithData:response encoding:NSUTF8StringEncoding] substringFromIndex:2] dataUsingEncoding:NSUTF8StringEncoding]; // There is a "id" before the json data
}

NSArray *GetPublicationDetails(NSArray *ids, NSString **error) {
    NSURL *detailURL = [NSURL URLWithString:[NSString stringWithFormat:libgenIoJsonFormat, [ids componentsJoinedByString:@","]]];
    NSError *err;
    NSData *response = [NSData dataWithContentsOfURL:detailURL options:NSDataReadingMappedIfSafe error:&err];
    if (err.code){
        *error = err.localizedDescription;
        return nil;
    }
    
    NSArray *jsonPubArray = [NSJSONSerialization JSONObjectWithData:RegularizeSearchResponse(response) options:NSJSONReadingMutableContainers error:&err];
    if (err.code) {
        *error = err.localizedDescription;
        return nil;
    }
    
    NSMutableArray *pubs = [[NSMutableArray alloc] init];
    for (NSDictionary *jsonObj in jsonPubArray) {
        [pubs addObject:ExtractPublication(jsonObj)];
    }
    return pubs;
}

Publication *ExtractPublication(NSDictionary *jsonObj) {
    Publication *pub = [[Publication alloc] init];
    pub.id = jsonObj[@"id"];
    pub.md5 = jsonObj[@"md5"];
    pub.details = jsonObj;
    return pub;
}

UIImage *GetCoverImageForPublication(Publication *pub, NSString **error) {
    NSURL *imageURL = [NSURL URLWithString:[NSString stringWithFormat:libgenIoCoverFormat, pub.details[@"coverurl"]]];
    NSError *err;
    UIImage *img = [UIImage imageWithData:[NSData dataWithContentsOfURL:imageURL options:NSDataReadingMappedIfSafe error:&err]];
    if (err.code) {
        *error = err.localizedDescription;
        return nil;
    }
    return img;
}

BOOL DownloadDocumentForPublication(Publication *pub, NSString **error) {
    NSURL *downloadURL = [NSURL URLWithString:[NSString stringWithFormat:libgenIoDownloadFormat, pub.details[@"md5"]]];
    NSError *err;
    NSData *fileData = [NSData dataWithContentsOfURL:downloadURL options:NSDataReadingMappedIfSafe error:&err];
    if (err.code) {
        *error = err.localizedDescription;
        return NO;
    }
    NSString * docDirectory = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES)[0];
    NSString *filePath = [NSString stringWithFormat:@"%@/%@.%@", docDirectory, pub.id, pub.details[@"extension"]];
    [fileData writeToFile:filePath options:NSDataWritingAtomic error:&err];
    if (err.code) {
        *error = err.localizedDescription;
        return NO;
    }
    return YES;
}
