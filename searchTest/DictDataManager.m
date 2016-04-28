//
//  DataManager.m
//  searchTest
//
//  Created by isan on 16/3/18.
//  Copyright © 2016年 isan. All rights reserved.
//

#import "DictDataManager.h"
#import "Entry.h"

@interface DictDataManager (){
    NSString *dataPath; //sqlite文件名称
    FMDatabaseQueue *queue;
}
@end

@implementation DictDataManager

static DictDataManager * _sharedDBManager;

+ (DictDataManager *) defaultDBManager {
    if (!_sharedDBManager) {
        _sharedDBManager = [[DictDataManager alloc] init];
    }
    return _sharedDBManager;
}

- (id) init {
    self = [super init];
    if (self) {
        NSString *doc = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, true) objectAtIndex:0];
        dataPath = [doc stringByAppendingPathComponent:kDictSqliteName];
        _dataBase = [[FMDatabase alloc] initWithPath:dataPath];
        
        //数据保护
        NSDictionary *attributes = @{NSFileProtectionKey: NSFileProtectionComplete};
        NSError *error;
        [[NSFileManager defaultManager] setAttributes:attributes
                                                        ofItemAtPath:dataPath
                                                               error:&error];
        if ([_dataBase open]) {
            queue = [[FMDatabaseQueue alloc] initWithPath:dataPath];
        }
    }
    return self;
}

- (void) dealloc {
    [self close];
}

// 关闭连接
- (void) close {
    [_dataBase close];
    _sharedDBManager = nil;
}

-(BOOL) isDictEntryTableExist {
    NSString *sql = @"SELECT count(*) as count FROM sqlite_master WHERE type='table' AND name='dict_entry'";
    FMResultSet *result = [_dataBase executeQuery:sql];
    if (result != nil) {
        while ([result next]) {
            NSInteger count = [result intForColumn:@"count"];
            if (count > 0) {
                return true;
            }else{
                return false;
            }
            break;
        }
    }
    return false;
}

- (BOOL)createDictEntryTable {
    NSString *sql = @"CREATE TABLE IF NOT EXISTS dict_entry (id integer PRIMARY KEY AUTOINCREMENT NOT NULL, word TEXT NOT NULL, paraphrase TEXT NOT NULL, weight integer NOT NULL); CREATE INDEX word_index ON dict_entry (word)";
    return [_dataBase executeStatements:sql];
}

- (void)importFileDataToDataBaseCompletionHandler: (void (^)())completionHandler {
    NSError *error;
    NSString *data = [NSString stringWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"data" ofType:@"txt"] encoding:NSUTF8StringEncoding error:&error];
    NSArray *dataArray = [data componentsSeparatedByString:@"\n"];
    
    for(NSString *entry in dataArray) {
        NSArray *entryArray = [entry componentsSeparatedByString:@"\t"];
        if([entryArray count] == 3) {
            NSString *sql = [NSString stringWithFormat:@"INSERT INTO dict_entry (word, paraphrase, weight) VALUES ('%@', '%@', %d)", entryArray[0], entryArray[1], [entryArray[2] intValue]];
            [_dataBase executeUpdate:sql];
        }else{
            NSLog(@"warning: 数据格式不正确");
        }
    }
    completionHandler();
}

- (void)searchKey: (NSString *) key callBack:(void (^)(NSMutableArray *entryArray))callBack {
    [queue inDatabase:^(FMDatabase *db) {
        NSString *sql = [NSString stringWithFormat:@"SELECT * FROM dict_entry WHERE word like '%@' ORDER BY weight DESC limit 5", [@"%" stringByAppendingString:[key stringByAppendingString:@"%"]]];
        FMResultSet *result = [db executeQuery:sql];
        NSMutableArray *entryArray = [[NSMutableArray alloc] initWithCapacity:0];
        if (result != nil) {
            while ([result next]) {
                [entryArray addObject:[self createEntryFrom:result]];
            }
        }
        
        dispatch_async(dispatch_get_main_queue(), ^{
            callBack(entryArray);
        });
    }];
}

- (Entry *)createEntryFrom: (FMResultSet *) resultSet {
    Entry *entry = [[Entry alloc] init];
    entry.key = [resultSet stringForColumn:@"word"];
    entry.paraphrase = [resultSet stringForColumn:@"paraphrase"];
    entry.weight = [resultSet intForColumn:@"weight"];
    return entry;
}

@end
