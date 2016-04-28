//
//  Entry.h
//  searchTest
//
//  Created by isan on 16/3/18.
//  Copyright © 2016年 isan. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface Entry : NSObject

@property (nonatomic, copy) NSString *key;
@property (nonatomic, copy) NSString *paraphrase;
@property (nonatomic)       NSInteger weight;

@end
