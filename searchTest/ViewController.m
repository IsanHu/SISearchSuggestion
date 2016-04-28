//
//  ViewController.m
//  searchTest
//
//  Created by isan on 16/3/18.
//  Copyright © 2016年 isan. All rights reserved.
//

#import "ViewController.h"
#import "MBProgressHUD.h"
#import "DictDataManager.h"
#import "Entry.h"

@interface ViewController (){
    UITextField *searchField;
    UITableView *searchSuggestionTable;
    UILabel *contentLabel; //显示选中的词条的释义
    
    DictDataManager *dataManager;
    
    NSMutableArray *suggestEntries;
    
    NSString *searchKey;
}

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    CGSize screenSize = [UIScreen mainScreen].bounds.size;
    searchField = [[UITextField alloc] initWithFrame:CGRectMake(15, 64, screenSize.width - 30, 44)];
    searchField.backgroundColor = [UIColor whiteColor];
    searchField.layer.cornerRadius = 4;
    searchField.layer.borderColor = [UIColor grayColor].CGColor;
    searchField.layer.borderWidth = 1;
    searchField.leftViewMode = UITextFieldViewModeAlways;
    searchField.leftView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 10, 1)];
    searchField.delegate = self;
    [self.view addSubview:searchField];
    
    searchSuggestionTable = [[UITableView alloc] initWithFrame:CGRectMake(15, CGRectGetMaxY(searchField.frame), screenSize.width - 30, 44 * 5) style:UITableViewStylePlain];
    searchSuggestionTable.delegate = self;
    searchSuggestionTable.dataSource = self;
    searchSuggestionTable.hidden = true;
    [self.view addSubview:searchSuggestionTable];
    
    contentLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, CGRectGetMaxY(searchSuggestionTable.frame) + 12, screenSize.width, 30)];
    contentLabel.backgroundColor = [UIColor clearColor];
    contentLabel.textColor = [UIColor blackColor];
    contentLabel.textAlignment = NSTextAlignmentCenter;
    contentLabel.font = [UIFont systemFontOfSize:14];
    [self.view addSubview:contentLabel];

}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    [self processData];
}

- (void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];
}

- (void)viewDidDisappear:(BOOL)animated {
    [super viewDidDisappear:animated];
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - process data
- (void) processData {
    //创建导入数据queue
    _importDataQueue = dispatch_queue_create("com.searchTest.importData", DISPATCH_QUEUE_SERIAL);
    
    dataManager = [DictDataManager defaultDBManager];
    if (![dataManager isDictEntryTableExist]) {
        if ([dataManager createDictEntryTable]) {
            [self showToastText:@"创建字典表成功"];
            //将文件中的数据导入到字典表中
            __weak typeof(self) weakSelf = self;
            dispatch_async(_importDataQueue, ^{
                [dataManager importFileDataToDataBaseCompletionHandler:^{
                    dispatch_async(dispatch_get_main_queue(), ^{
                        [weakSelf hideToast];
                        [weakSelf showToastText:@"数据导入完成"];
                    });
                }];
            });
            
            dispatch_time_t firstRemindTime = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1.5 * NSEC_PER_SEC));
            dispatch_after(firstRemindTime, dispatch_get_main_queue(), ^(void){
                [self showToastText:@"开始导入数据"];
            });
            dispatch_time_t secondRemindTime = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(3 * NSEC_PER_SEC));
            dispatch_after(secondRemindTime, dispatch_get_main_queue(), ^(void){
                [self showToastForever];
            });
        }else{
            [self showToastText:@"创建字典表失败"];
        }
    }
}


#pragma mark - TableViewDatasourse, TableViewDelegate

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [suggestEntries count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    NSString *reuserId = @"entryCell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:reuserId];
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:reuserId];
    }
    if (indexPath.row < suggestEntries.count) {
        Entry *entry = (Entry *)suggestEntries[indexPath.row];
        cell.textLabel.text = [NSString stringWithFormat:@"%@", entry.key];
        
        if (searchKey.length != 0) {
            NSRange range = [[entry.key lowercaseString] rangeOfString:[searchKey lowercaseString]];
            
            NSMutableAttributedString *str = [[NSMutableAttributedString alloc] initWithString:entry.key];
            [str addAttribute:NSForegroundColorAttributeName value:[UIColor blueColor] range:range];
            cell.textLabel.attributedText = str;
        }
        
        cell.detailTextLabel.text = entry.paraphrase;
    }
    return cell;
}
- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return 44;
}
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [tableView deselectRowAtIndexPath:indexPath animated:true];
    if (indexPath.row < suggestEntries.count) {
        Entry *entry = (Entry *)suggestEntries[indexPath.row];
        contentLabel.text = [NSString stringWithFormat:@"%@: %@, 权重为：%ld", entry.key, entry.paraphrase, (long)entry.weight];
        searchField.text = entry.key;
        searchSuggestionTable.hidden = true;
        [self.view endEditing:true];
    }
}

#pragma mark - UITextFieldDelegate
- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string
{
    NSString *key = textField.text;
    if (string.length == 0) {
        if (key.length >= 1) {
            key = [key substringToIndex:(key.length - 1)];
        }
    }else{
        key = [key stringByAppendingString:string];
    }
    searchKey = key;
    if (key != nil && key.length > 0) {
        [dataManager searchKey:key callBack:^(NSMutableArray *entryArray) {
            suggestEntries = entryArray;
            if (suggestEntries.count > 0) {
                Entry *firstEntry = [suggestEntries firstObject];
                contentLabel.text = [NSString stringWithFormat:@"%@: %@, 权重为：%ld", firstEntry.key, firstEntry.paraphrase, (long)firstEntry.weight];
                searchSuggestionTable.hidden = false;
                [searchSuggestionTable reloadData];
            }else{
                searchSuggestionTable.hidden = true;
                contentLabel.text = nil;
            }
        }];
    }else {
        [suggestEntries removeAllObjects];
        searchSuggestionTable.hidden = true;
        contentLabel.text = nil;
    }
    return true;
}

#pragma mark - HUD
- (void) showToastText: (NSString*)text {
    MBProgressHUD *hudProgress = [MBProgressHUD showHUDAddedTo:self.view animated:true];
    hudProgress.mode = MBProgressHUDModeText;
    hudProgress.labelText = text;
    hudProgress.minSize = CGSizeMake(135, 135);
    hudProgress.square = false;
    [hudProgress hide:true afterDelay:1.5];
}

- (void)showToastForever {
    MBProgressHUD *hudProgress = [MBProgressHUD showHUDAddedTo:self.view animated:true];
    hudProgress.minSize = CGSizeMake(135, 135);
    hudProgress.square = true;
    hudProgress.opacity = 0;
    hudProgress.activityIndicatorColor = [UIColor colorWithWhite:0.196 alpha:1];
}

- (void) hideToast {
    [MBProgressHUD hideAllHUDsForView:self.view animated:true];
}

@end
