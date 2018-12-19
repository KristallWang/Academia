//
//  LibgenSearch.h
//  Academia
//
//  Created by Yutong Zhang on 2018/12/17.
//  Copyright © 2018 Yutong Zhang. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "Publication.h"
#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

NSArray/*<Publication *>*/ * __nullable SearchForPublications(NSString *, NSString **);
UIImage *GetCoverImageForPublication(Publication *, NSString **error);
BOOL DownloadDocumentForPublication(Publication *, NSString **error);

NS_ASSUME_NONNULL_END
