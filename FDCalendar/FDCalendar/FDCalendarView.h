//
//  FDCalendarView.h
//  FDCalendar
//
//  Created by 笑虎 on 13-5-16.
//  Copyright (c) 2013年 王谦. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol FDCalendarViewDelegate;
@interface FDCalendarView : UIView
{
    UILabel *_secMonthLable;
    NSDate *_secDate;
    NSDate *_currDate;
    NSLocale *_fmtLocale;
    NSArray *_taskDay;
}

//当前日期
@property(nonatomic,retain)NSDate *currDate;
//选中的日期
@property(nonatomic,retain)NSDate *secDate;
//当前的高度
@property(nonatomic,getter=getCalendarHeight) float calendarHeight;
//代理设置
@property(nonatomic,assign)id<FDCalendarViewDelegate> delegate;
//当前月的那些天有任务@[1,4,6,8];
//@property(nonatomic,retain)NSArray *taskDay;

-(void)setTaskDay:(NSArray *)taskDay;
-(NSDate *)getFirstDayForDate:(NSDate *)date;

@end

#pragma mark delegate
@protocol FDCalendarViewDelegate <NSObject>

-(void)FDCalendarView:(FDCalendarView *)view dateSelected:(NSDate *)date;
-(void)FDCalendarView:(FDCalendarView *)view changeMonth:(NSDate *)month height:(CGFloat)height;

@end