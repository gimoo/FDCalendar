//
//  FDCalendarView.m
//  FDCalendar
//
//  Created by 笑虎 on 13-5-16.
//  Copyright (c) 2013年 王谦. All rights reserved.
//

#import "FDCalendarView.h"
#import <QuartzCore/QuartzCore.h>

@implementation FDCalendarView
@synthesize currDate = _currDate;
@synthesize secDate = _secDate;
//@synthesize taskDay = _taskDay;
#define FDCalendar_TopBarHeight 60
#define FDCalendar_Width 320
#define FDCalendar_DayWidth 44
#define FDCalendar_DayHeight 44

//初始化
- (id)init
{
    //注意当frame高度为0时，draw不会自动调用
    self = [super initWithFrame:CGRectMake(0, 0, FDCalendar_Width, 300)];
    if (self) {
        [self initDefault];
    }
    return self;
}

//设置当前任务
-(void)setTaskDay:(NSArray *)taskDay
{
    _taskDay = [taskDay retain];
    [self setNeedsDisplay];
}

//默认设置
- (void)initDefault
{
    // 设置为模型，始终靠上方
    self.contentMode = UIViewContentModeTop;

    // 超出绘制区域时隐藏起来
    self.clipsToBounds=YES;
    
    //当前的语言
    _fmtLocale = [[NSLocale alloc] initWithLocaleIdentifier:@"zh_CN"];
       
    //当前任务
    _taskDay = nil;
    
    //日期显示
    _secMonthLable = [[UILabel alloc] initWithFrame:CGRectMake(34, 10, FDCalendar_Width-68, 30)];
    [_secMonthLable setFont:[UIFont fontWithName:@"HelveticaNeue-Bold" size:17]];
    [_secMonthLable setBackgroundColor:[UIColor whiteColor]];
    [_secMonthLable setTextColor:[UIColor blackColor]];
    [_secMonthLable setTextAlignment:NSTextAlignmentCenter];
    [self addSubview:_secMonthLable];
    [_secMonthLable release];
    
    self.currDate = [self getCurrDate];
    self.secDate = _currDate;
    
    [self setFrameHeight:self.calendarHeight];
}
#pragma mark drawRect
// 绘制界面
- (void)drawRect:(CGRect)rect
{
    //获取画板
    CGContextClearRect(UIGraphicsGetCurrentContext(),rect);
    CGContextRef context = UIGraphicsGetCurrentContext();
    
    //绘制月导航
    [self drawRectArrow:rect context:context];
    
    //绘制周
    [self drawRectWeek:rect context:context];
    
    //绘制方格
    [self drawRectGrid:rect context:context];
    
    int numRows = [self getCurrRows];
//    float gridHeight = numRows*(FDCalendar_DayHeight+2)+1;
    int numBlocks = numRows*7;
    int firstWeekDay = [self getFirstWeekDayInMonth:_currDate]-1; //-1 because weekdays begin at 1, not 0

    NSDate *previousMonth = [self getOffsetMonth:_currDate numMonths:-1];
    int currentMonthNumDays = [self getNumDaysInMonth:_currDate];
    int prevMonthNumDays = [self getNumDaysInMonth:previousMonth];
    int selectedDateBlock = _secDate ? ([[self getComponentsForDate:_secDate] day]-1 + firstWeekDay) : -1;
    
    //设置当前日期所在的block位置，默认是一个你绝对想不到的值
    NSDate *todayDate = [NSDate date];
    int todayBlock = -1;
    if ([[self getComponentsForDate:todayDate] month] == [[self getComponentsForDate:_currDate] month] && [[self getComponentsForDate:todayDate] year] == [[self getComponentsForDate:_currDate] year]) {
        todayBlock = [[self getComponentsForDate:todayDate] day] + firstWeekDay - 1;
    }
    
    //设置文字颜色
    CGContextSetFillColorWithColor(context,[UIColor blackColor].CGColor);

    for (int i=0; i<numBlocks; i++) {
        int targetDate = i;
        int targetColumn = i%7;
        int targetRow = i/7;
        int targetX = targetColumn * (FDCalendar_DayWidth+2);
        int targetY = FDCalendar_TopBarHeight + targetRow * (FDCalendar_DayHeight+2);
        
        // BOOL isCurrentMonth = NO;
        if (i<firstWeekDay) {
            //上一个月
            targetDate = (prevMonthNumDays-firstWeekDay)+(i+1);
            // [UIColor colorWithRed:56/255.0f green:56/255.0f blue:56/255.0f alpha:1.0f] 0x383838
            // [UIColor colorWithRed:170/255.0f green:170/255.0f blue:170/255.0f alpha:1.0f] aaaaaa
            CGContextSetFillColorWithColor(context,[UIColor grayColor].CGColor);
        } else if (i>=(firstWeekDay+currentMonthNumDays)) {
            //下个月
            targetDate = (i+1) - (firstWeekDay+currentMonthNumDays);
            CGContextSetFillColorWithColor(context,[UIColor grayColor].CGColor);
        } else {
            //当前月
            targetDate = (i-firstWeekDay)+1;
            CGContextSetFillColorWithColor(context, [UIColor blackColor].CGColor);
        }
        
        NSString *date = [NSString stringWithFormat:@"%i",targetDate];

        //设置选中背景
        if (_secDate && i==selectedDateBlock) {
            //选中日期
            CGRect rectangleGrid = CGRectMake(targetX,targetY+2,FDCalendar_DayWidth,FDCalendar_DayHeight);
            CGContextAddRect(context, rectangleGrid);
            CGContextSetFillColorWithColor(context, [UIColor colorWithRed:0/255.0f green:109/255.0f blue:188/255.0f alpha:1.0f].CGColor);
            CGContextFillPath(context);
            CGContextSetFillColorWithColor(context,[UIColor whiteColor].CGColor);
        } else if (todayBlock==i) {
            //当前日期
            CGRect rectangleGrid = CGRectMake(targetX,targetY+2,FDCalendar_DayWidth,FDCalendar_DayHeight);
            CGContextAddRect(context, rectangleGrid);
            CGContextSetFillColorWithColor(context, [UIColor colorWithRed:56/255.0f green:56/255.0f blue:56/255.0f alpha:1.0f].CGColor);
            CGContextFillPath(context);
            
            CGContextSetFillColorWithColor(context, [UIColor whiteColor].CGColor);
        }
        
        [date drawInRect:CGRectMake(targetX, targetY+10, FDCalendar_DayWidth, FDCalendar_DayHeight) withFont:[UIFont boldSystemFontOfSize:17] lineBreakMode:NSLineBreakByClipping alignment:NSTextAlignmentCenter];
    }
    
    //检测是否有任务，将任务标识出来
    if (!_taskDay) return;

    CGContextSetFillColorWithColor(context, [UIColor blackColor].CGColor);
    UIFont *dotFont = [UIFont boldSystemFontOfSize:18.0f];
    for (int i = 0; i<[_taskDay count]; i++) {
        id taskObj = [_taskDay objectAtIndex:i];
        
        //当前天
        int targetDay;
        
        //两种方式的赋值都可以被解析
        if ([taskObj isKindOfClass:[NSNumber class]]) {
            targetDay = [(NSNumber *)taskObj intValue];
        } else if ([taskObj isKindOfClass:[NSDate class]]) {
            NSDate *date = (NSDate *)taskObj;
            targetDay = [[self getComponentsForDate:date] day];
        } else {
            continue;
        }

        int targetBlock = firstWeekDay + (targetDay-1);
        int targetColumn = targetBlock%7;
        int targetRow = targetBlock/7;
        
        int targetX = targetColumn * (FDCalendar_DayWidth+2) + 7;
        int targetY = FDCalendar_TopBarHeight + targetRow * (FDCalendar_DayHeight+2) + 30;
        
        CGRect rectangle = CGRectMake(targetX,targetY,32,2);
        [@"•" drawInRect: rectangle
				withFont: dotFont
		   lineBreakMode: NSLineBreakByWordWrapping
			   alignment: NSTextAlignmentCenter];
    }
    
}

//绘制TOP导航
-(void)drawRectArrow:(CGRect)rect context:(CGContextRef)context
{
    //当前选择的月
    NSDateFormatter *fmt = [[NSDateFormatter alloc] init];
    [fmt setLocale:_fmtLocale];
    [fmt setDateFormat:@"yyyy-MMM"];
    [_secMonthLable setText:[fmt stringFromDate:_currDate]];
    [fmt release];
    
    //左右箭头的绘制    
    CGRect rectangle = CGRectMake(0,0,self.frame.size.width,FDCalendar_TopBarHeight);
    CGContextAddRect(context, rectangle);
    CGContextSetFillColorWithColor(context, [UIColor whiteColor].CGColor);
    CGContextFillPath(context);
    
    //Arrows
    int arrowSize = 12;
    int xmargin = 20;
    int ymargin = 18;
    
    //Arrow Left
    CGContextBeginPath(context);
    CGContextMoveToPoint(context, xmargin+arrowSize/1.5, ymargin);
    CGContextAddLineToPoint(context,xmargin+arrowSize/1.5,ymargin+arrowSize);
    CGContextAddLineToPoint(context,xmargin,ymargin+arrowSize/2);
    CGContextAddLineToPoint(context,xmargin+arrowSize/1.5, ymargin);
    CGContextSetFillColorWithColor(context,[UIColor blackColor].CGColor);
    CGContextFillPath(context);
    
    //Arrow right
    CGContextBeginPath(context);
    CGContextMoveToPoint(context, self.frame.size.width-(xmargin+arrowSize/1.5), ymargin);
    CGContextAddLineToPoint(context,self.frame.size.width-xmargin,ymargin+arrowSize/2);
    CGContextAddLineToPoint(context,self.frame.size.width-(xmargin+arrowSize/1.5),ymargin+arrowSize);
    CGContextAddLineToPoint(context,self.frame.size.width-(xmargin+arrowSize/1.5), ymargin);
    CGContextSetFillColorWithColor(context,[UIColor blackColor].CGColor);
    CGContextFillPath(context);
}

//绘制周
-(void)drawRectWeek:(CGRect)rect context:(CGContextRef)context
{
    //Weekdays
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    dateFormatter.dateFormat=@"EEE";
    dateFormatter.locale = _fmtLocale;
    NSMutableArray *weekdays = [[NSMutableArray alloc] initWithArray:[dateFormatter shortWeekdaySymbols]];
    [self mutableArrayMoveObjectFromIndex:0 toIndex:6 object:weekdays];
    
    CGContextSetFillColorWithColor(context,[UIColor colorWithRed:56/255.0f green:56/255.0f blue:56/255.0f alpha:1.0f].CGColor);
    UIFont *font = [UIFont systemFontOfSize:12];
    for (int i =0; i<[weekdays count]; i++) {
        NSString *weekdayValue = (NSString *)[weekdays objectAtIndex:i];
        [weekdayValue drawInRect:CGRectMake(i*(FDCalendar_DayWidth+2), 40, FDCalendar_DayHeight+2, 20) withFont:font lineBreakMode:NSLineBreakByClipping alignment:NSTextAlignmentCenter];
    }
    CGContextSetAllowsAntialiasing(context, NO);
}

//绘制方格
-(void)drawRectGrid:(CGRect)rect context:(CGContextRef)context
{
    int numRows = [self getCurrRows];
    
    //日历背景
    float gridHeight = numRows*(FDCalendar_DayHeight+2)+1;
    CGRect rectangleGrid = CGRectMake(0,FDCalendar_TopBarHeight,self.frame.size.width,gridHeight+1);
    CGContextAddRect(context, rectangleGrid);
    CGContextSetFillColorWithColor(context, [UIColor colorWithRed:243/255.0f green:243/255.0f blue:243/255.0f alpha:1.0f].CGColor);
    CGContextFillPath(context);
    
    //绘制方格
    CGContextSetStrokeColorWithColor(context, [UIColor whiteColor].CGColor);
    CGContextBeginPath(context);
    CGContextMoveToPoint(context, 0, FDCalendar_TopBarHeight+1);
    CGContextAddLineToPoint(context, FDCalendar_Width, FDCalendar_TopBarHeight+1);
    for (int i = 1; i<7; i++) {
        //竖线
        CGContextMoveToPoint(context, i*(FDCalendar_DayWidth+1)+i*1-1, FDCalendar_TopBarHeight+1);
        CGContextAddLineToPoint(context, i*(FDCalendar_DayWidth+1)+i*1-1, FDCalendar_TopBarHeight+gridHeight);
        
//        if (i>numRows-1) continue;
        
        //横线
        CGContextMoveToPoint(context, 0, FDCalendar_TopBarHeight+i*(FDCalendar_DayHeight+1)+i*1+1);
        CGContextAddLineToPoint(context, FDCalendar_Width, FDCalendar_TopBarHeight+i*(FDCalendar_DayHeight+1)+i*1+1);
    }
    CGContextStrokePath(context);
    
    
    //Grid dark lines
//    CGContextSetStrokeColorWithColor(context, [UIColor grayColor].CGColor);
//    CGContextBeginPath(context);
//    CGContextMoveToPoint(context, 0, FDCalendar_TopBarHeight);
//    CGContextAddLineToPoint(context, FDCalendar_Width, FDCalendar_TopBarHeight);
//    for (int i = 1; i<7; i++) {
//        //columns
//        CGContextMoveToPoint(context, i*(FDCalendar_DayWidth+1)+i*1, FDCalendar_TopBarHeight);
//        CGContextAddLineToPoint(context, i*(FDCalendar_DayWidth+1)+i*1, FDCalendar_TopBarHeight+gridHeight);
//        
//        if (i>numRows-1) continue;
//        //rows
//        CGContextMoveToPoint(context, 0, FDCalendar_TopBarHeight+i*(FDCalendar_DayHeight+1)+i*1);
//        CGContextAddLineToPoint(context, FDCalendar_Width, FDCalendar_TopBarHeight+i*(FDCalendar_DayHeight+1)+i*1);
//    }
//    CGContextMoveToPoint(context, 0, gridHeight+FDCalendar_TopBarHeight);
//    CGContextAddLineToPoint(context, FDCalendar_Width, gridHeight+FDCalendar_TopBarHeight);
//    CGContextStrokePath(context);
    
    //设置东西设置可以抗锯齿
    CGContextSetAllowsAntialiasing(context, YES);
}

#pragma mark touche
-(void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
    UITouch *touch = [touches anyObject];
    CGPoint touchPoint = [touch locationInView:self];

    //Touch a specific day
    if (touchPoint.y > FDCalendar_TopBarHeight) {
        float xLocation = touchPoint.x;
        float yLocation = touchPoint.y-FDCalendar_TopBarHeight;
        
        int column = floorf(xLocation/(FDCalendar_DayWidth+2));
        int row = floorf(yLocation/(FDCalendar_DayHeight+2));
        
        int blockNr = (column+1)+row*7;
        int firstWeekDay = [self getFirstWeekDayInMonth:_currDate]-1; //-1 because weekdays begin at 1, not 0
        NSInteger date = blockNr-firstWeekDay;
        [self selectDate:date];
        return;
    }
    
    
    CGRect rectArrowLeft = CGRectMake(0, 0, 50, 40);
    CGRect rectArrowRight = CGRectMake(self.frame.size.width-50, 0, 50, 40);
    
    //点击左边箭头
    if (CGRectContainsPoint(rectArrowLeft, touchPoint)) {
        self.secDate = [self getFirstDayForDate:[self getOffsetMonth:_currDate numMonths:-1]];
        [self showChangeAnimating:-1];
    } else if (CGRectContainsPoint(rectArrowRight, touchPoint)) {
        self.secDate = [self getFirstDayForDate:[self getOffsetMonth:_currDate numMonths:-1]];
        [self showChangeAnimating:1];
    } else if (CGRectContainsPoint(_secMonthLable.frame, touchPoint)) {
        self.currDate = [self getCurrDate];
        self.secDate = _currDate;
        [self setFrameHeight:self.calendarHeight];
        [self setNeedsDisplay];
        
        //代理调用
        if (self.delegate && [self.delegate respondsToSelector:@selector(FDCalendarView:changeMonth:height:)]) {
            [self.delegate FDCalendarView:self changeMonth:_currDate height:self.calendarHeight];
        }
    }
}

-(void)selectDate:(NSInteger)day
{
    NSCalendar *gregorian = [[NSCalendar alloc] initWithCalendarIdentifier:NSGregorianCalendar];
    NSDateComponents *comps = [gregorian components:NSYearCalendarUnit | NSMonthCalendarUnit |  NSDayCalendarUnit fromDate:_currDate];
    [comps setDay:day];
    self.secDate = [gregorian dateFromComponents:comps];
    
    NSDateComponents *currComp = [self getComponentsForDate:_currDate];
    NSDateComponents *secComp = [self getComponentsForDate:_secDate];
    
    if ([secComp year]<[currComp year] || ([secComp year]==[currComp year] && [secComp month]<[currComp month])) {
        //上一月
        [self showChangeAnimating:-1];
    }else if([secComp year]>[currComp year] || ( [secComp year]==[currComp year] && [secComp month]>[currComp month])){
        //下一月
        [self showChangeAnimating:1];
    }else{
        [self setNeedsDisplay];
    }
    
    //代理调用
    if (self.delegate && [self.delegate respondsToSelector:@selector(FDCalendarView:dateSelected:)]) {
//        [comps setTimeZone:[NSTimeZone timeZoneWithName:@"Asia/BeiJing"]];
//        NSDate *date = [gregorian dateFromComponents:comps];
//        NSLog(@"_currTimeZone:%@,date:%@",_currTimeZone,date);
        [self.delegate FDCalendarView:self dateSelected:_secDate];
    }
}

//切换上下月动画
-(void)showChangeAnimating:(NSInteger)type
{
    static BOOL isAnimating = NO;
    //如果已经在执行动画了则直接跳出
    if (isAnimating)  return;
    isAnimating = YES;

    _taskDay = nil;
    
    //获取当前的页面
    float oldSize = self.calendarHeight;
    UIImageView *animatViewA = [[UIImageView alloc] initWithImage:[self getCurrentDrawState]];
    
    //切换月状态
    self.currDate = [self getOffsetMonth:_currDate numMonths:type];
    [self setFrameHeight:self.calendarHeight];
    [self setNeedsDisplay];
    UIImageView *animatViewB = [[UIImageView alloc] initWithImage:[self getCurrentDrawState]];

    float targetSize = fmaxf(oldSize, self.calendarHeight);
    UIView *antimatView = [[UIView alloc] initWithFrame:CGRectMake(0, FDCalendar_TopBarHeight, FDCalendar_Width, targetSize-FDCalendar_TopBarHeight)];
    [antimatView setClipsToBounds:YES];
    [self addSubview:antimatView];
    [antimatView release];
    
    [antimatView addSubview:animatViewA];
    [antimatView addSubview:animatViewB];
    [animatViewA release];
    [animatViewB release];
    
    
    //代理调用
    if (self.delegate && [self.delegate respondsToSelector:@selector(FDCalendarView:changeMonth:height:)]) {
        [self.delegate FDCalendarView:self changeMonth:_currDate height:self.calendarHeight];
    }
    
    CGFloat starPiont = 0;
    CGFloat endPiont = 0;
    if (type == 1) {
        //下一月
        starPiont = animatViewA.frame.origin.y + animatViewB.frame.size.height+3;
        endPiont = animatViewA.frame.origin.y - animatViewA.frame.size.height+3;
        
    }else{
        //上一月
        starPiont = animatViewA.frame.origin.y-animatViewB.frame.size.height+3;
        endPiont = animatViewB.frame.size.height-3;
    }

    //初始化动画坐标-设置默认位置
    [self setFrameForView:animatViewB frameY:starPiont];
    [self setFrameHeight:oldSize];
    
    [UIView animateWithDuration:.35
                     animations:^{
                         [self setFrameHeight:self.calendarHeight];
                         [self setFrameForView:animatViewA frameY:endPiont];
                         [self setFrameForView:animatViewB frameY:0];
                     }
                     completion:^(BOOL finished) {
                         isAnimating=NO;
                         [antimatView removeFromSuperview];
                     }
     ];
}

//获取当前绘制的状态转存为图片
-(UIImage *)getCurrentDrawState
{
    float targetHeight = FDCalendar_TopBarHeight + [self getCurrRows]*(FDCalendar_DayHeight+2)+1;
    UIGraphicsBeginImageContext(CGSizeMake(FDCalendar_Width, targetHeight-FDCalendar_TopBarHeight));
    CGContextRef c = UIGraphicsGetCurrentContext();
    CGContextTranslateCTM(c, 0, -FDCalendar_TopBarHeight);    // <-- shift everything up by 40px when drawing.
    [self.layer renderInContext:c];
    UIImage *tmpImg = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return tmpImg;
}

#pragma mark mout
//获取当前时间
-(NSDate *)getCurrDate
{
    NSCalendar *gregorian = [[NSCalendar alloc] initWithCalendarIdentifier:NSGregorianCalendar];
    NSDateComponents *comps = [gregorian components:(NSYearCalendarUnit | NSMonthCalendarUnit | NSDayCalendarUnit) fromDate: [NSDate date]];
    return [gregorian dateFromComponents:comps];
}

//获取当前月第一天
-(NSDate *)getFirstDayForDate:(NSDate *)date
{
    NSCalendar *calendar = [NSCalendar currentCalendar];
    NSDateComponents *dayComponents = [calendar components:(NSDayCalendarUnit) fromDate:date];
    NSInteger day = [dayComponents day];//当前天
    
    //计算获取新date
    NSDateComponents *compToAdd = [[NSDateComponents alloc] init];    
    [compToAdd setDay:-day+1];
    NSDate *nDate = [calendar dateByAddingComponents:compToAdd toDate:date options:0];
    [compToAdd release];
    
    return nDate;
}

//获取当前月按周排列的总行数
-(int)getCurrRows
{
    float lastBlock = [self getNumDaysInMonth:_currDate]+([self getFirstWeekDayInMonth:_currDate]-1);
    return ceilf(lastBlock/7);
}

//获取当前的日历高度
-(float)getCalendarHeight {
    return FDCalendar_TopBarHeight + [self getCurrRows]*(FDCalendar_DayHeight+2)+2;
}

//将指定对象移动到指定的位置
-(void)mutableArrayMoveObjectFromIndex:(NSUInteger)from toIndex:(NSUInteger)to object:(NSMutableArray *)object
{
    if (to != from) {
        id obj = [object objectAtIndex:from];
        [obj retain];
        [object removeObjectAtIndex:from];
        if (to >= [object count]) {
            [object addObject:obj];
        } else {
            [object insertObject:obj atIndex:to];
        }
        [obj release];
    }
}

-(int)getNumDaysInMonth:(NSDate *)date
{
    NSCalendar *cal = [NSCalendar currentCalendar];
    NSRange rng = [cal rangeOfUnit:NSDayCalendarUnit inUnit:NSMonthCalendarUnit forDate:date];
    NSUInteger numberOfDaysInMonth = rng.length;
    return numberOfDaysInMonth;
}

//根据偏移量获取一个日期
-(NSDate *)getOffsetMonth:(NSDate *)date numMonths:(int)numMonths
{
    NSCalendar *gregorian = [[NSCalendar alloc] initWithCalendarIdentifier:NSGregorianCalendar];
    [gregorian setFirstWeekday:2];//monday is first day
    NSDateComponents *offsetComponents = [[NSDateComponents alloc] init];
    [offsetComponents setMonth:numMonths];
    //[offsetComponents setHour:1];
    //[offsetComponents setMinute:30];
    return [gregorian dateByAddingComponents:offsetComponents toDate:date options:0];
}

//用一个日期获取当前Components对象
-(NSDateComponents *)getComponentsForDate:(NSDate *)date
{
    NSCalendar *gregorian = [[NSCalendar alloc] initWithCalendarIdentifier:NSGregorianCalendar];
    NSDateComponents *comp = [gregorian components:(NSYearCalendarUnit | NSMonthCalendarUnit | NSDayCalendarUnit) fromDate:date];
    [gregorian release];
    return comp;
}

//获取每月1号是周几
-(int)getFirstWeekDayInMonth:(NSDate *)date
{
    NSCalendar *gregorian = [[NSCalendar alloc]
                             initWithCalendarIdentifier:NSGregorianCalendar];
    [gregorian setFirstWeekday:2]; //monday is first day
    //[gregorian setLocale:[[NSLocale alloc] initWithLocaleIdentifier:@"nl_NL"]];
    
    //Set date to first of month
    NSDateComponents *comps = [gregorian components:NSYearCalendarUnit | NSMonthCalendarUnit |  NSDayCalendarUnit fromDate:date];
    [comps setDay:1];
    NSDate *newDate = [gregorian dateFromComponents:comps];
    
    return [gregorian ordinalityOfUnit:NSWeekdayCalendarUnit inUnit:NSWeekCalendarUnit forDate:newDate];
}

//设置当前frame的新高度
- (void)setFrameHeight:(CGFloat)newHeight {
	self.frame = CGRectMake(self.frame.origin.x, self.frame.origin.y,
							self.frame.size.width, newHeight);
}

//设置x轴
- (void)setFrameForView:(UIView *)view frameX:(CGFloat)frameX
{
    view.frame = CGRectMake(frameX, view.frame.origin.y, view.frame.size.width, view.frame.size.height);
}

//设置Y轴
- (void)setFrameForView:(UIView *)view frameY:(CGFloat)frameY
{
    view.frame = CGRectMake(view.frame.origin.x, frameY, view.frame.size.width, view.frame.size.height);
}
@end
