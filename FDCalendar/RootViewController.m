//
//  RootViewController.m
//  FDCalendar
//
//  Created by 笑虎 on 13-5-15.
//  Copyright (c) 2013年 王谦. All rights reserved.
//

#import "RootViewController.h"
#import "FDCalendarView.h"
#import "NSDate+FDDate.h"

@interface RootViewController ()
<FDCalendarViewDelegate>

@end

@implementation RootViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
        [self setTitle:@"日历"];
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view.
    NSArray *items = @[[NSNumber numberWithInteger:3],[NSNumber numberWithInteger:12],[NSNumber numberWithInteger:23]];
    FDCalendarView *fview = [[FDCalendarView alloc] init];
    [fview setTaskDay:items];
    fview.delegate = self;
    [self.view addSubview:fview];
    [fview release];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

-(void)FDCalendarView:(FDCalendarView *)view changeMonth:(NSDate *)month height:(CGFloat)height
{
    //获取日期
    NSCalendar *cal = [NSCalendar currentCalendar];
    NSRange rng = [cal rangeOfUnit:NSDayCalendarUnit inUnit:NSMonthCalendarUnit forDate:month];
    NSUInteger DaysInMonth = rng.length;
    
    NSDateFormatter *fmt = [[NSDateFormatter alloc] init];
    [fmt setDateFormat:@"yyyy-MM"];
    NSString *startDate = [NSString stringWithFormat:@"%@-01",[fmt stringFromDate:month]];
    NSString *endDate = [NSString stringWithFormat:@"%@-%d",[fmt stringFromDate:month],DaysInMonth];
    NSLog(@"change:%@-%@",startDate,endDate);
}

-(void)FDCalendarView:(FDCalendarView *)view dateSelected:(NSDate *)date
{
//    date = [view getFirstDayForDate:date];
    NSDateFormatter *fmt = [[NSDateFormatter alloc] init];
    [fmt setDateFormat:@"yyyy-MM-dd"];
    NSString *dstr = [fmt stringFromDate:date];
    NSLog(@"delegate:%@",dstr);
//    NSLog(@"currDate:%@",[view getFirstDayForDate:date]);
}

@end
