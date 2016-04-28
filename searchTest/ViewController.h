//
//  ViewController.h
//  searchTest
//
//  Created by isan on 16/3/18.
//  Copyright © 2016年 isan. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface ViewController : UIViewController<UITableViewDataSource, UITableViewDelegate, UITextFieldDelegate>

@property (nonatomic) dispatch_queue_t importDataQueue;
@end

