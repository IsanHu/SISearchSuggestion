//
//  DataManager.h
//  searchTest
//
//  Created by isan on 16/3/18.
//  Copyright © 2016年 isan. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "FMDB.h"

#define kDictSqliteName                    @"Dict.sqlite"

@interface DictDataManager : NSObject 
/// 数据库操作对象，当数据库被建立时，会存在次至
@property (nonatomic, readonly) FMDatabase * dataBase;  // 数据库操作对象
/// 单例模式
+(DictDataManager *) defaultDBManager;


/**
 *  判断词典数据表是否存在
 *
 *  @return 存在返回true,不存在返回false
 */
-(BOOL) isDictEntryTableExist;


/**
 *  创建词典数据表
 *
 *  @return 成功返回true,失败返回false
 */
- (BOOL)createDictEntryTable;

/**
 *  将data.txt 中的数据导入到词典数据表中
 *
 *  @param completionHandler 导入完成回调
 */
- (void)importFileDataToDataBaseCompletionHandler: (void (^)())completionHandler;

/**
 *  根据搜索框中输入的文字查询词条
 *
 *  @param key      搜索框中的内容
 *  @param callBack 查询结果回调
 */
- (void)searchKey: (NSString *) key callBack:(void (^)(NSMutableArray *entryArray))callBack;

@end
