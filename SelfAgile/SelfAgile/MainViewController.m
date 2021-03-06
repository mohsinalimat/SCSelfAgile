//
//  MainViewController.m
//  SelfAgile
//
//  Created by chen Yuheng on 15/6/9.
//  Copyright (c) 2015年 chen Yuheng. All rights reserved.
//

#import "MainViewController.h"
#import "CreateSprintTableViewController.h"

#import "PullToReact.h"
#import "MentionPullToReactView.h"
#import "UITableView+Helper.h"
#import "UIImage+Helper.h"
#import "SAEvent.h"
#import "UIColor+Custom.h"
#import "UIViewExt.h"
#import "UIKitCustomUtils.h"

#import "SADoingTableViewCell.h"
#import "SADoneTableViewCell.h"
#import "SAToDoTableViewCell.h"
#import "LBorderView.h"
#import "DOPNavbarMenu/DOPNavbarMenu.h"
#import "StringConstant.h"

#define controlHeight 100.0f

@interface MainViewController ()<UITableViewDelegate,UITableViewDataSource,DOPNavbarMenuDelegate>

@property (assign, nonatomic) NSInteger numberOfItemsInRow;
@property (strong, nonatomic) DOPNavbarMenu *menu;

@property(nonatomic,strong) UITableView *tableView;
@property(nonatomic,strong) MNTPullToReactControl *reactControl;
@property(nonatomic,strong) NSMutableArray *data;

@property(nonatomic,strong) NSMutableArray *toDoData;
@property(nonatomic,strong) NSMutableArray *doingData;
@property(nonatomic,strong) NSMutableArray *doneData;

@property(nonatomic) NSInteger selectedIndex;

@property(nonatomic) CGSize snapShotSize;
@property(nonatomic) BOOL isSnapShotSmall;

@property(nonatomic,strong) UIView *processBackView;
@property(nonatomic,strong) LBorderView *processView;
@property(nonatomic,strong) UIImageView *processGestureImageView;
@property(nonatomic,strong) UILabel *processIllustrateLabel;
@end

@implementation MainViewController

- (DOPNavbarMenu *)menu {
    if (_menu == nil) {
        DOPNavbarMenuItem *item1 = [DOPNavbarMenuItem ItemWithTitle:MenuHelpText icon:[UIImage imageNamed:@"help"]];
        DOPNavbarMenuItem *item2 = [DOPNavbarMenuItem ItemWithTitle:MenuOverviewText icon:[UIImage imageNamed:@"overview"]];
        DOPNavbarMenuItem *item3 = [DOPNavbarMenuItem ItemWithTitle:MenuAboutText icon:[UIImage imageNamed:@"about"]];
        
        _menu = [[DOPNavbarMenu alloc] initWithItems:@[item1,item2,item3] width:self.view.dop_width maximumNumberInRow:_numberOfItemsInRow];
        _menu.backgroundColor = [UIColor customColorDefault];
        _menu.separatarColor = [UIColor whiteColor];
        _menu.delegate = self;
    }
    return _menu;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.numberOfItemsInRow = 3;
    if([[NSUserDefaults standardUserDefaults] objectForKey:@"sprintNum"]== nil)
    {
        [[NSUserDefaults standardUserDefaults] setObject:[NSNumber numberWithInt:1] forKey:@"sprintNum"];
    }
    
    if([[NSUserDefaults standardUserDefaults] objectForKey:@"sprintTitle"]== nil)
    {
        [[NSUserDefaults standardUserDefaults] setObject:@"基本迭代" forKey:@"sprintTitle"];
    }
    
    CreateSprintTableViewController *createSprintVC = [[CreateSprintTableViewController alloc]init];
    [self.navigationController pushViewController:createSprintVC animated:YES];
    
    UILongPressGestureRecognizer *longPress = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(longPressGestureRecognized:)];
    [self.tableView addGestureRecognizer:longPress];
    
    self.toDoData = [NSMutableArray array];
    self.doingData = [NSMutableArray array];
    self.doneData = [NSMutableArray array];
    
    self.titleLabel.text = [NSString stringWithFormat:@"S#%ld:%@",[[[NSUserDefaults standardUserDefaults] objectForKey:@"sprintNum"] integerValue],[[NSUserDefaults standardUserDefaults] objectForKey:@"sprintTitle"]];
    self.titleLabel.textAlignment = NSTextAlignmentCenter;
    
    _data = [NSMutableArray arrayWithArray:@[@"To do", @"Doing", @"Done"]];
    // Do any additional setup after loading the view.
    self.view.backgroundColor = [UIColor customColorDefault];
    [self.tableView hideExtraCellLine];
    self.tableView.backgroundColor = [UIColor customColorDefault];
    
    self.tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    self.reactControl = [[MNTPullToReactControl alloc] initWithNumberOfActions:MentionPullToReactViewNumberOfAction];
    self.reactControl.threshold = 90;
    self.reactControl.contentView = [[MentionPullToReactView alloc] initWithFrame:CGRectMake(0, 0, self.view.bounds.size.width, 100)];
    [self.reactControl addTarget:self action:@selector(reaction:) forControlEvents:UIControlEventValueChanged];
    self.tableView.reactControl = self.reactControl;
    self.selectedIndex = 0;
    
    UIBarButtonItem *add = [[UIBarButtonItem alloc]initWithBarButtonSystemItem:UIBarButtonSystemItemAdd target:self action:@selector(addNewEvent)];
    add.tintColor = [UIColor whiteColor];
    self.navigationItem.rightBarButtonItem = add;
    
    [self initEventData];
    
    //[SAEvent createEvents:[NSDictionary dictionaryWithObjects:@[@"Hello world!",@"This is my first event",[NSNumber numberWithInt:1],[NSNumber numberWithInt:0]] forKeys:@[@"title",@"content",@"level",@"sprintNum"]]];
}

- (void)loadView
{
    self.tableView = [[UITableView alloc] initWithFrame:[[UIScreen mainScreen] applicationFrame]];
    self.tableView.delegate = self;
    self.tableView.dataSource = self;
    self.view = self.tableView;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section
{
    if(section == 0)
    {
        NSString *nextStatus = @"正在进行中";
        switch (self.selectedIndex) {
            case 1:
            {
                nextStatus = @"已完成";
            }
                break;
            case 2:
            {
                return nil;
            }
                break;
            default:
            {
                nextStatus = @"正在进行中";
            }
                break;
        }
        
        _processBackView = [[UIView alloc]initWithFrame:CGRectMake(0.0f, 0.0f, ScreenWidth, controlHeight)];
        _processBackView.backgroundColor = [UIColor clearColor];
        
        _processView = [[LBorderView alloc]initWithFrame:CGRectMake(3.0f, 3.0f, ScreenWidth - 6.0f, controlHeight - 6.0f)];
        _processView.borderColor = [UIColor whiteColor];
        _processView.backgroundColor = [UIColor customColorYellow];
        _processView.alpha = 1.0f;
        _processView.borderType = BorderTypeDashed;
        _processView.dashPattern = 6;
        _processView.spacePattern = 4;
        _processView.borderWidth = 2.0f;
        _processView.cornerRadius = 6.0f;
        
        _processGestureImageView = [[UIImageView alloc]initWithFrame:CGRectMake((ScreenWidth - 240.0f)/2, 35.0f, 30.0f, 30.0f)];
        [_processGestureImageView setContentScaleFactor:[[UIScreen mainScreen] scale]];
        _processGestureImageView.contentMode =  UIViewContentModeCenter;
        _processGestureImageView.image = [UIImage imageNamed:@"holdGesture"];
        
        _processIllustrateLabel = [[UILabel alloc]initWithFrame:CGRectMake(_processGestureImageView.right + 10.0f, 30.0f, 200.0f, 40.0f)];
        _processIllustrateLabel.font = [UIFont systemFontOfSize:14.0f];
        _processIllustrateLabel.textColor = [UIColor whiteColor];
        _processIllustrateLabel.numberOfLines = 0;
        _processIllustrateLabel.textAlignment = NSTextAlignmentLeft;
        _processIllustrateLabel.text = [NSString stringWithFormat:@"长按卡片拖拽到这里移动到%@状态",nextStatus];
        
        [_processView addSubview:_processIllustrateLabel];
        [_processView addSubview:_processGestureImageView];
        [_processBackView addSubview:_processView];
        
        return _processBackView;
    }
    else
    {
        return nil;
    }
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
    switch (self.selectedIndex) {
        case 1:
        {
            return controlHeight;
        }
            break;
        case 2:
        {
            return 0.0f;
        }
            break;
        default:
        {
            return controlHeight;
        }
            break;
    }
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    switch(self.selectedIndex)
    {
        case 1:
        {
            NSDictionary *event = [self.doingData objectAtIndex:indexPath.row];
            CGFloat height = 60.0f;
            if([event objectForKey:@"title"])
            {
                height += [UIKitCustomUtils getTextHeightWithText:[event objectForKey:@"title"] andMaxWidth:ScreenWidth -20.0f andFont:[UIFont boldSystemFontOfSize:18.0f]];
            }
            
            if([event objectForKey:@"content"])
            {
                height += [UIKitCustomUtils getTextHeightWithText:[event objectForKey:@"content"] andMaxWidth:ScreenWidth -20.0f andFont:[UIFont systemFontOfSize:14.0f]];
            }
            return height;
        }
            break;
        case 2:
        {
            NSDictionary *event = [self.doneData objectAtIndex:indexPath.row];
            CGFloat height = 60.0f;
            if([event objectForKey:@"title"])
            {
                height += [UIKitCustomUtils getTextHeightWithText:[event objectForKey:@"title"] andMaxWidth:ScreenWidth -20.0f andFont:[UIFont boldSystemFontOfSize:18.0f]];
            }
            
            if([event objectForKey:@"content"])
            {
                height += [UIKitCustomUtils getTextHeightWithText:[event objectForKey:@"content"] andMaxWidth:ScreenWidth -20.0f andFont:[UIFont systemFontOfSize:14.0f]];
            }
            return height;
        }
            break;
        default:
        {
            NSDictionary *event = [self.toDoData objectAtIndex:indexPath.row];
            CGFloat height = 60.0f;
            if([event objectForKey:@"title"])
            {
                height += [UIKitCustomUtils getTextHeightWithText:[event objectForKey:@"title"] andMaxWidth:ScreenWidth -20.0f andFont:[UIFont boldSystemFontOfSize:18.0f]];
            }
            
            if([event objectForKey:@"content"])
            {
                height += [UIKitCustomUtils getTextHeightWithText:[event objectForKey:@"content"] andMaxWidth:ScreenWidth -20.0f andFont:[UIFont systemFontOfSize:14.0f]];
            }
            return height;
        }
            break;
    }
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [self.navigationController.navigationBar setTranslucent:NO];
    self.navigationController.navigationBar.barTintColor = [UIColor customColorDefault];
    
    // Hide the shadow of navBar
    for (UIView *view in [[[self.navigationController.navigationBar subviews] objectAtIndex:0] subviews]) {
        if ([view isKindOfClass:[UIImageView class]]) {
            view.hidden = YES;
        }
    }
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    // Return the number of sections.
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    // Return the number of rows in the section.
    switch(self.selectedIndex)
    {
        case 1:
            return self.doingData.count;
            break;
        case 2:
            return self.doneData.count;
            break;
        default:
            return self.toDoData.count;
            break;
    }
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    switch(self.selectedIndex)
    {
        case 1:
        {
            if(indexPath.row > self.doingData.count-1)
            {
                // in order to protect Index out of range exception
                return nil;
            }
            
            NSDictionary *event = [self.doingData objectAtIndex:indexPath.row];
            SADoingTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"DoingTableViewCell"];
            if(!cell)
            {
                cell = [[SADoingTableViewCell alloc]initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"DoingTableViewCell"];
            }
            cell.event = event;
            return cell;
        }
            break;
        case 2:
        {
            if(indexPath.row > self.doneData.count-1)
            {
                // in order to protect Index out of range exception
                return nil;
            }
            
            NSDictionary *event = [self.doneData objectAtIndex:indexPath.row];
            SADoneTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"DoneTableViewCell"];
            if(!cell)
            {
                cell = [[SADoneTableViewCell alloc]initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"DoneTableViewCell"];
            }
            cell.event = event;
            return cell;
        }
            break;
        default:
        {
            if(indexPath.row > self.toDoData.count-1)
            {
                // in order to protect Index out of range exception
                return nil;
            }
            
            NSDictionary *event = [self.toDoData objectAtIndex:indexPath.row];
            SAToDoTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"todoTableViewCell"];
            if(!cell)
            {
                cell = [[SAToDoTableViewCell alloc]initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"todoTableViewCell"];
            }
            cell.event = event;
            return cell;
        }
            break;
    }
}

#pragma mark - Pull to react target-action method
- (void)reaction:(id)sender
{
    MNTPullToReactControl *reactControl = (MNTPullToReactControl *)sender;
    if(reactControl.action < 1 || reactControl.action > 3)
    {
        return;
    }
    
    NSLog(@"Doing action %ld", (long)reactControl.action);
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{
        dispatch_async(dispatch_get_main_queue(), ^{
            self.selectedIndex = reactControl.action - 1;
            NSInteger sprintNum = [[[NSUserDefaults standardUserDefaults] objectForKey:@"sprintNum"] integerValue];
            switch (self.selectedIndex) {
                case 1:
                    self.doingData = [[SAEvent getDoingEventList:sprintNum] mutableCopy];
                    break;
                case 2:
                    self.doneData = [[SAEvent getDoneEventList:sprintNum] mutableCopy];
                    break;
                case 0:
                default:
                    self.toDoData = [[SAEvent getToDoEventList:sprintNum] mutableCopy];
                    break;
            }
            [self.tableView reloadSections:[NSIndexSet indexSetWithIndex:0] withRowAnimation:UITableViewRowAnimationFade];
            usleep(600 * 1000);
            [reactControl endAction:reactControl.action];
        });
    });
}

#pragma mark - Private
- (void)doAction:(NSInteger)action
{
    [self.reactControl beginAction:action];
    NSLog(@"Do action %ld", (long)action);
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{
        usleep(10 * 1000);
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.reactControl endAction:action];
        });
    });
}

#pragma mark - Create new event
- (void)addNewEvent
{
    [self performSegueWithIdentifier:@"CreateNewEvent" sender:self];
}

- (void)initEventData
{
    NSInteger sprintNum = [[[NSUserDefaults standardUserDefaults] objectForKey:@"sprintNum"] integerValue];
    self.toDoData = [[SAEvent getToDoEventList:sprintNum] mutableCopy];
    [self.tableView reloadData];
}

- (void)longPressGestureRecognized:(id)sender {
    
    UILongPressGestureRecognizer *longPress = (UILongPressGestureRecognizer *)sender;
    UIGestureRecognizerState state = longPress.state;
    
    CGPoint location = [longPress locationInView:self.tableView];
    NSIndexPath *indexPath = [self.tableView indexPathForRowAtPoint:location];
    
    static UIView       *snapshot = nil;
    ///< A snapshot of the row user is moving.
    
    static NSIndexPath  *sourceIndexPath = nil;
    ///< Initial index path, where gesture begins.
    
    static NSInteger    eventId = 0;
    
    switch (state) {
        case UIGestureRecognizerStateBegan: {
            if (indexPath) {
                sourceIndexPath = indexPath;
                
                UITableViewCell *cell = [self.tableView cellForRowAtIndexPath:indexPath];
                
                switch (self.selectedIndex) {
                    case 1:
                    {
                        eventId = [[[self.doingData objectAtIndex:indexPath.row] objectForKey:@"id"] integerValue];
                    }
                        break;
                    case 2:
                    {
                        eventId = [[[self.doneData objectAtIndex:indexPath.row] objectForKey:@"id"] integerValue];
                    }
                        break;
                    default:
                    {
                        eventId = [[[self.toDoData objectAtIndex:indexPath.row] objectForKey:@"id"] integerValue];
                    }
                        break;
                }

                // Take a snapshot of the selected row using helper method.
                snapshot = [self customSnapshoFromView:cell];
                
                // Add the snapshot as subview, centered at cell's center...
                __block CGPoint center = cell.center;
                snapshot.center = center;
                snapshot.alpha = 0.0;
                self.isSnapShotSmall = NO;
                [self.tableView addSubview:snapshot];
                [UIView animateWithDuration:0.25 animations:^{
                    
                    // Offset for gesture location.
                    center.y = location.y;
                    snapshot.center = center;
                    snapshot.transform = CGAffineTransformMakeScale(1.05, 1.05);
                    snapshot.alpha = 0.6;
                    cell.alpha = 0.0;
                    self.snapShotSize = snapshot.size;
                } completion:^(BOOL finished) {
                    
                    cell.hidden = YES;
                    
                }];
            }
            break;
        }
            
        case UIGestureRecognizerStateChanged: {
            CGPoint center = snapshot.center;
            CGPoint centerCopy = center;
            centerCopy.y = centerCopy.y - self.tableView.contentOffset.y;
            center.y = location.y;
            snapshot.center = center;
            
            if(centerCopy.y < controlHeight + 64.0f)
            {
                if(self.selectedIndex!=2)
                {
                    if(!self.isSnapShotSmall)
                    {
                        _processGestureImageView.image = [UIImage imageNamed:@"releaseGesture"];
                        _processIllustrateLabel.text = @"请确认卡片的状态变更后松开您的手指";
                        _processView.backgroundColor = [UIColor customColorDefault];
                        [UIView animateWithDuration:0.25 animations:^{
                            snapshot.height = self.snapShotSize.height/2;
                            snapshot.width = self.snapShotSize.width/2;
                            CGPoint center_tmp = snapshot.center;
                            center_tmp.x = ScreenWidth/2;
                            snapshot.center=center_tmp;
                            
                            snapshot.transform = CGAffineTransformIdentity;
                        } completion:^(BOOL finished) {
                            self.isSnapShotSmall = YES;
                        }];
                    }
                }
            }
            else
            {
                if(self.selectedIndex!=2)
                {
                    if(self.isSnapShotSmall)
                    {
                        _processGestureImageView.image = [UIImage imageNamed:@"holdGesture"];
                        _processIllustrateLabel.text = @"长按卡片拖拽到这里移动到正在进行中状态";
                        _processView.backgroundColor = [UIColor customColorYellow];
                        [UIView animateWithDuration:0.25 animations:^{
                            snapshot.height = self.snapShotSize.height;
                            snapshot.width = self.snapShotSize.width;
                            CGPoint center_tmp = snapshot.center;
                            center_tmp.x = ScreenWidth/2;
                            snapshot.center=center_tmp;
                            
                            snapshot.transform = CGAffineTransformIdentity;
                        } completion:^(BOOL finished) {
                            self.isSnapShotSmall = NO;
                        }];
                    }
                }
                
                // Is destination valid and is it different from source?
                if (indexPath && ![indexPath isEqual:sourceIndexPath]) {
                    
                    switch (self.selectedIndex) {
                        case 1:
                        {
                            [SAEvent exchangeCustomIndexFronEvent:[self.doingData objectAtIndex:indexPath.row] withEvent:[self.doingData objectAtIndex:sourceIndexPath.row]];
                            [self.doingData exchangeObjectAtIndex:indexPath.row withObjectAtIndex:sourceIndexPath.row];
                        }
                            break;
                        case 2:
                        {
                            [SAEvent exchangeCustomIndexFronEvent:[self.doneData objectAtIndex:indexPath.row] withEvent:[self.doneData objectAtIndex:sourceIndexPath.row]];
                            [self.doneData exchangeObjectAtIndex:indexPath.row withObjectAtIndex:sourceIndexPath.row];
                        }
                            break;
                        default:
                        {
                            [SAEvent exchangeCustomIndexFronEvent:[self.toDoData objectAtIndex:indexPath.row] withEvent:[self.toDoData objectAtIndex:sourceIndexPath.row]];
                            [self.toDoData exchangeObjectAtIndex:indexPath.row withObjectAtIndex:sourceIndexPath.row];
                        }
                            break;
                    }
                    
                    [self.tableView moveRowAtIndexPath:sourceIndexPath toIndexPath:indexPath];
                    NSLog(@"sourceIndexPath changed to:%ld",indexPath.row);
                    sourceIndexPath = indexPath;
                }
                
            }
            break;
        }
        case UIGestureRecognizerStateEnded:
        {
            _processGestureImageView.image = [UIImage imageNamed:@"holdGesture"];
            _processIllustrateLabel.text = @"长按卡片拖拽到这里移动到正在进行中状态";
            _processView.backgroundColor = [UIColor customColorYellow];
            CGPoint center = snapshot.center;
            center.y = center.y - self.tableView.contentOffset.y;
            if(center.y < controlHeight + 64.0f && self.selectedIndex != 2)
            {
                // transfer card now
                NSLog(@"fuckfuck!!");
                switch (self.selectedIndex) {
                    case 1:
                    {
                        [SAEvent alterEvents:eventId toState:2];
                        for(NSInteger i=0;i<self.doingData.count;i++)
                        {
                            if ([[[self.doingData objectAtIndex:i] objectForKey:@"id"] isEqualToString:[NSString stringWithFormat:@"%ld",eventId]])
                            {
                                [self.doingData removeObjectAtIndex:i];
                                break;
                            }
                        }
                    }
                        break;
                    case 2:
                    {
                        return;
                    }
                        break;
                    default:
                    {
                        [SAEvent alterEvents:eventId toState:1];
                        for(NSInteger i=0;i<self.toDoData.count;i++)
                        {
                            if ([[[self.toDoData objectAtIndex:i] objectForKey:@"id"] isEqualToString:[NSString stringWithFormat:@"%ld",eventId]])
                            {
                                [self.toDoData removeObjectAtIndex:i];
                                break;
                            }
                        }
                    }
                        break;
                }
                
                [self.tableView reloadSections:[NSIndexSet indexSetWithIndex:0] withRowAnimation:UITableViewRowAnimationNone];
                
                [UIView animateWithDuration:0.25 animations:^{
                    [snapshot setFrame:CGRectZero];
                } completion:^(BOOL finished) {
                    eventId = 0;
                    sourceIndexPath = nil;
                    [snapshot removeFromSuperview];
                    snapshot = nil;
                }];
            }
            else
            {
                    UITableViewCell *cell = [self.tableView cellForRowAtIndexPath:sourceIndexPath];
                    cell.hidden = NO;
                    cell.alpha = 0.0;
                    
                    [UIView animateWithDuration:0.25 animations:^{
                        
                        snapshot.center = cell.center;
                        snapshot.transform = CGAffineTransformIdentity;
                        snapshot.alpha = 0.0;
                        cell.alpha = 1.0;
                        
                    } completion:^(BOOL finished) {
                        
                        sourceIndexPath = nil;
                        [snapshot removeFromSuperview];
                        snapshot = nil;
                        
                    }];
            }
            break;
        }
        default: {
            // Clean up.
            UITableViewCell *cell = [self.tableView cellForRowAtIndexPath:sourceIndexPath];
            cell.hidden = NO;
            cell.alpha = 0.0;
            
            [UIView animateWithDuration:0.25 animations:^{
                
                snapshot.center = cell.center;
                snapshot.transform = CGAffineTransformIdentity;
                snapshot.alpha = 0.0;
                cell.alpha = 1.0;
                
            } completion:^(BOOL finished) {
                
                sourceIndexPath = nil;
                [snapshot removeFromSuperview];
                snapshot = nil;
                
            }];
            
            break;
        }
    }
}

#pragma mark - Helper methods

/** @brief Returns a customized snapshot of a given view. */
- (UIView *)customSnapshoFromView:(UIView *)inputView {
    
    // Make an image from the input view.
    UIGraphicsBeginImageContextWithOptions(inputView.bounds.size, NO, 0);
    [inputView.layer renderInContext:UIGraphicsGetCurrentContext()];
    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    // Create an image view.
    UIView *snapshot = [[UIImageView alloc] initWithImage:image];
    snapshot.layer.masksToBounds = NO;
    snapshot.layer.cornerRadius = 0.0;
    snapshot.layer.shadowOffset = CGSizeMake(-5.0, 0.0);
    snapshot.layer.shadowRadius = 5.0;
    snapshot.layer.shadowOpacity = 0.4;
    
    return snapshot;
}
- (IBAction)openMenu:(id)sender {
    self.navigationItem.leftBarButtonItem.enabled = NO;
    if (self.menu.isOpen) {
        [self.menu dismissWithAnimation:YES];
    } else {
        [self.menu showInNavigationController:self.navigationController];
    }
}

- (void)didShowMenu:(DOPNavbarMenu *)menu {
    self.navigationItem.leftBarButtonItem.enabled = YES;
}

- (void)didDismissMenu:(DOPNavbarMenu *)menu {
    self.navigationItem.leftBarButtonItem.enabled = YES;
}

- (void)didSelectedMenu:(DOPNavbarMenu *)menu atIndex:(NSInteger)index {
    switch (index) {
        case 0:
        {
            
        }
            break;
        case 1:
        {
            [self performSegueWithIdentifier:@"OverViewSegue" sender:self];
        }
            break;
        case 2:
        {
            
        }
            break;
        default:
            break;
    }
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
