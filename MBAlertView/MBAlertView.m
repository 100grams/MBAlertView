//
//  MBAlertView.m
//  Notestand
//
//  Created by M B. Bitar on 9/8/12.
//  Copyright (c) 2012 progenius, inc. All rights reserved.
//

#import "MBAlertView.h"
#import "MBHUDView.h"
#import <QuartzCore/QuartzCore.h>

#import "MBAlertViewButton.h"
#import "MBSpinningCircle.h"
#import "MBCheckMarkView.h"

#import "UIView+Animations.h"
#import "NSString+Trim.h"
#import "UIFont+Alert.h"

#import "MBAlertViewSubclass.h"

#define kIconLabelMargin 30

NSString *const MBAlertViewDidAppearNotification = @"MBAlertViewDidAppearNotification";
NSString *const MBAlertViewDidDismissNotification = @"MBAlertViewDidDismissNotification";

CGFloat MBAlertViewMaxHUDDisplayTime = 10.0;
CGFloat MBAlertViewDefaultHUDHideDelay = 0.65;

@interface MBAlertView ()
@property (nonatomic, strong) NSMutableArray *items;
@property (nonatomic, strong) UILabel        *titleLabel;
@property (nonatomic, strong) UIView         *maskView;

@end

@implementation MBAlertView
{
    NSMutableArray *_buttons;
    BOOL isPendingDismissal;
    UIButton *_backgroundButton;

}
// when dismiss is called, it takes about 0.5 seconds to complete animations. you want to remove it from the queue in the beginning, but want something to hold on to it. this is what retain queue is for

static NSMutableArray *retainQueue;
static NSMutableArray *displayQueue;
static NSMutableArray *dismissQueue;
static MBAlertView *currentAlert;

+(BOOL)alertIsVisible
{
    if(currentAlert)
        return YES;
    return NO;
}

+(CGSize)halfScreenSize
{
    return CGSizeMake(280, 240);
}


+(MBAlertView*)alertWithTitle:(NSString*)title message:(NSString*)body;
{
    MBAlertView *alert = [[MBAlertView alloc] init];
    alert.bodyText = body;
    alert.titleText = title;
    return alert;
}


+(MBAlertView*)alertWithTitle:(NSString*)title message:(NSString*)body cancelTitle:(NSString*)cancelTitle cancelBlock:(id)cancelBlock
{
    MBAlertView *alert = [MBAlertView alertWithTitle:title message:body];
    if(cancelTitle)
        [alert addButtonWithText:cancelTitle type:MBAlertViewItemTypeDefault block:cancelBlock];
    return alert;
}

-(void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

-(id)init
{
    if(self = [super init])
    {
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(setRotation:)name:UIApplicationDidChangeStatusBarOrientationNotification object:nil];
        self.addsMask = YES;
    }

    return self;
}

-(void)addToDisplayQueue
{
    if(!displayQueue)
        displayQueue = [[NSMutableArray alloc] init];
    if(!dismissQueue)
        dismissQueue = [[NSMutableArray alloc] init];

    [displayQueue addObject:self];
    [dismissQueue addObject:self];

    if(retainQueue.count == 0 && !currentAlert)
    {
        // show now
        currentAlert = self;
        [self addToWindow];
        if([self isMemberOfClass:[MBAlertView class]])
        {
            [[NSNotificationCenter defaultCenter] postNotificationName:MBAlertViewDidAppearNotification object:nil];
        }
    }
}

-(void)addToWindow
{
    UIWindow * window = [UIApplication sharedApplication].keyWindow;
    if (!window)
        window = [[UIApplication sharedApplication].windows objectAtIndex:0];

    UIInterfaceOrientation orientation = [UIApplication sharedApplication].statusBarOrientation;

    if (self.addsMask && !self.maskView) {
        CGRect frame = window.frame;
        if(orientation == UIDeviceOrientationLandscapeLeft || orientation == UIDeviceOrientationLandscapeRight)
            frame.size = CGSizeMake(frame.size.height, frame.size.width);
        self.maskView = [[UIView alloc] initWithFrame:frame];
        self.maskView.backgroundColor = [UIColor blackColor];
        self.maskView.alpha = 0.7;
    }

    if(self.addsToWindow){
        if (self.maskView) {
            [window addSubview:self.maskView];
        }
        [window addSubview:self.view];
    }
    else {
        if (self.maskView) {
            [[[window subviews] objectAtIndex:0] addSubview:self.maskView];
        }
        [[[window subviews] objectAtIndex:0] addSubview:self.view];
    }

    [self performLayoutOfButtons];
    [self centerViews];

    self.titleLabel.frame = CGRectMake(self.titleLabel.frame.origin.x, self.titleLabel.frame.origin.y + self.titleInset, self.titleLabel.frame.size.width, self.titleLabel.frame.size.height);


    if(orientation == UIDeviceOrientationLandscapeLeft || orientation == UIDeviceOrientationLandscapeRight)
    {
        self.bodyLabelButton.frame = CGRectMake(self.bodyLabelButton.frame.origin.x, self.bodyLabelButton.frame.origin.y + self.bodyInset - 3, self.bodyLabelButton.frame.size.width, self.bodyLabelButton.frame.size.height);
    }
    else
    {
        self.bodyLabelButton.frame = CGRectMake(self.bodyLabelButton.frame.origin.x, self.bodyLabelButton.frame.origin.y + self.bodyInset, self.bodyLabelButton.frame.size.width, self.bodyLabelButton.frame.size.height);
    }

    [window resignFirstRespondersForSubviews];

    [self addBounceAnimationToLayer:self.view.layer];
    [displayQueue removeObject:self];

}

// calling this removes the last queued alert, whether it has been displayed or not
+(void)dismissCurrentHUD
{
    if(dismissQueue.count > 0)
    {
        MBAlertView *current = [dismissQueue lastObject];
        [displayQueue removeObject:current];
        [current dismiss];
        [dismissQueue removeLastObject];
    }
}

+(void)dismissCurrentHUDAfterDelay:(float)delay
{
    [[MBAlertView class] performSelector:@selector(dismissCurrentHUD) withObject:nil afterDelay:delay];
}

-(void)dismiss
{
    if(isPendingDismissal)
        return;
    isPendingDismissal = YES;

    if(!retainQueue)
        retainQueue = [[NSMutableArray alloc] init];

    [self.hideTimer invalidate];
    [retainQueue addObject:self];
    [dismissQueue removeObject:self];

    currentAlert = nil;
    [self addDismissAnimation];
}

-(void)removeAlertFromView
{
    id block = self.uponDismissalBlock;
    if (![block isEqual:[NSNull null]] && block)
    {
        ((void (^)())block)();
    }

    [self.maskView removeFromSuperview];
    [self.view removeFromSuperview];
    [retainQueue removeObject:self];

    if(displayQueue.count > 0)
    {
        MBAlertView *alert = [displayQueue objectAtIndex:0];
        currentAlert = alert;
        [currentAlert addToWindow];
    }
}

#pragma  mark - Buttons


-(void)didSelectButton:(MBAlertViewButton*)button
{
    if(button.tag >= _items.count)
        return;
    MBAlertViewItem *item = [_items objectAtIndex:button.tag];
    if(!item)
        return;

    id block = item.block;
    if (![block isEqual:[NSNull null]] && block)
    {
        if(item.dismissesAlert && self.shouldPerformBlockAfterDismissal && block)
            self.uponDismissalBlock = block;
        else ((void (^)())block)();
        [[NSNotificationCenter defaultCenter] postNotificationName:MBAlertViewDidDismissNotification object:nil];
    }
    else
    {
        [[NSNotificationCenter defaultCenter] postNotificationName:MBAlertViewDidDismissNotification object:nil];
    }

    if (item.dismissesAlert) {
        [self performSelector:@selector(dismiss) withObject:nil afterDelay:0.12];
    }
}


// if there is only one button on the alert, we're going to assume its just an OK option, so we'll let the user tap anywhere to dismiss the alert
-(void)didSelectBackgroundButton:(UIButton*)button
{
    if(_buttons.count == 1)
    {
        MBAlertViewButton *alertButton = [_buttons objectAtIndex:0];
        [self didSelectButton:alertButton];
    }
}

-(NSMutableArray*)items
{
    if(_items)
        return _items;
    _items = [[NSMutableArray alloc] init];
    return _items;
}


- (MBAlertViewItem*) buttonItemAtIndex : (NSUInteger) index;
{
    if (index < [self.items count]) {
        return [self.items objectAtIndex:index];
    }
    return nil;
}

-(void)addButtonWithText:(NSString*)text type:(MBAlertViewItemType)type block:(id)block
{
    MBAlertViewItem *item = [[MBAlertViewItem alloc] initWithTitle:text type:type block:block];
    [self.items addObject:item];
}

-(void)addCustomButton:(UIButton*)button dismissesAlert:(BOOL)dismisses block:(id)block ;
{
    MBAlertViewItem *item = [[MBAlertViewItem alloc] initWithTitle:button.titleLabel.text type:MBAlertViewItemTypeCustom block:block];
    item.dismissesAlert = dismisses;
    [self.items addObject:item];
    item.customButton = button;
}


-(int)defaultAutoResizingMask
{
    return UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleBottomMargin;
}


#pragma mark - Layout

#define kBodyFont [UIFont boldSystemFontOfSize:20]
#define kSpaceBetweenButtons 15

-(BOOL)isFullScreen
{
    return CGSizeEqualToSize(self.size, CGSizeZero);
}

-(void)loadView
{
    CGRect bounds = [[UIScreen mainScreen] bounds]; // portrait bounds
    UIInterfaceOrientation orientation = [[UIApplication sharedApplication] statusBarOrientation];
    if (UIInterfaceOrientationIsLandscape(orientation)) {
        bounds.size = CGSizeMake(MAX(bounds.size.height, bounds.size.width), MIN(bounds.size.height, bounds.size.width));
    }
    else{
        bounds.size = CGSizeMake(MIN(bounds.size.height, bounds.size.width), MAX(bounds.size.height, bounds.size.width));
    }

    self.view = [[UIView alloc] initWithFrame:bounds];
    [self.view setBackgroundColor:[UIColor clearColor]];
    if (self.isAutoresizing) {
        self.view.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleBottomMargin | UIViewAutoresizingFlexibleTopMargin;
    }
    else{
        self.view.autoresizingMask = UIViewAutoresizingFlexibleBottomMargin + UIViewAutoresizingFlexibleTopMargin + UIViewAutoresizingFlexibleRightMargin + UIViewAutoresizingFlexibleLeftMargin;
    }

    BOOL isFullScreen = [self isFullScreen];

    if(orientation == UIDeviceOrientationLandscapeLeft || orientation == UIDeviceOrientationLandscapeRight)
    {
//        self.size = CGSizeMake(self.size.width, self.size.height);
        CGRect rect = CGRectMake(self.view.bounds.size.width/2.0 - self.size.width/2.0 , (self.view.bounds.size.height/2.0 - (self.size.height)/2.0), self.size.width, self.size.height);
        _backgroundButton = [[UIButton alloc] initWithFrame:CGRectIntegral(rect)];
        _contentRect = _backgroundButton.frame;
    }
    else if(isFullScreen)
    {
        _contentRect = CGRectMake(0, 0, bounds.size.width, bounds.size.height);
        _backgroundButton = [[UIButton alloc] initWithFrame:CGRectMake(-100, -100, bounds.size.width + 200, bounds.size.height + 200)];
        self.size = _contentRect.size;
    }
    else
    {
        CGRect rect = CGRectMake(self.view.bounds.size.width/2.0 - self.size.width/2.0 , self.view.bounds.size.height/2.0 - self.size.height/2.0, self.size.width, self.size.height);
        _backgroundButton = [[UIButton alloc] initWithFrame:CGRectIntegral(rect)];
        _contentRect = _backgroundButton.frame;
    }

    if (self.backgroundImage) {
        [_backgroundButton setBackgroundColor:[UIColor clearColor]];
        CGSize refSize =self.backgroundImage.size;
        UIImage *bgImage = [self.backgroundImage resizableImageWithCapInsets:UIEdgeInsetsMake(refSize.height*0.4, refSize.width*0.4, refSize.height*0.4, refSize.width*0.4)];
        [_backgroundButton setBackgroundImage:bgImage forState:UIControlStateNormal];
    }
    else{
        [_backgroundButton setBackgroundColor:[UIColor blackColor]];
        _backgroundButton.layer.cornerRadius = isFullScreen? 0 : 8;

    }
    _backgroundButton.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleBottomMargin | UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleWidth;
    _backgroundButton.alpha = _backgroundAlpha > 0 ? _backgroundAlpha : 1;
    [_backgroundButton addTarget:self action:@selector(didSelectBackgroundButton:) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:_backgroundButton];
}

-(UIFont*)bodyFont
{
    if(_bodyFont)
        return _bodyFont;
    _bodyFont = [UIFont boldSystemFontThatFitsSize:[self labelConstraint] maxFontSize:22 minSize:20 text:self.bodyText];
    return _bodyFont;
}

-(UIFont*)titleFont
{
    if(_titleFont)
        return _titleFont;
    _titleFont = [UIFont boldSystemFontThatFitsSize:[self labelConstraint] maxFontSize:32 minSize:24 text:self.titleText];
    return _titleFont;
}

-(CGSize)labelConstraint
{
    return CGSizeMake(self.contentRect.size.width - 40, self.contentRect.size.height - 100);
}

-(CGSize)titleConstraint
{
    return CGSizeMake(self.contentRect.size.width - 10, self.size.height * 0.2);
}


-(UIButton*)bodyLabelButton
{
    if(_bodyLabelButton)
        return _bodyLabelButton;

    if (self.customBodyView) {

        CGSize size = self.customBodyView.frame.size;
        CGSize constraint = [self labelConstraint];
        if (size.width > constraint.width) {
            size.width = constraint.width;
        }
        if (size.height > constraint.height) {
            size.height = constraint.height;
        }
        CGRect frame = CGRectMake(_contentRect.origin.x + _contentRect.size.width/2.0 - size.width/2.0 + self.contentEdgeInsets.left,
                                  CGRectGetMidY(_contentRect) - (size.height - _iconImageView.frame.size.height  - kIconLabelMargin)/2.0 + self.contentEdgeInsets.top - self.contentEdgeInsets.bottom,
                                  size.width,
                                  size.height);
        frame = CGRectIntegral(frame);
        self.customBodyView.frame = (CGRect){CGPointZero, frame.size};
        _bodyLabelButton = [[UIButton alloc] initWithFrame:frame];
        _bodyLabelButton.autoresizingMask = [self defaultAutoResizingMask];
        [_bodyLabelButton addTarget:self action:@selector(didSelectBodyLabel:) forControlEvents:UIControlEventTouchUpInside];
        [_bodyLabelButton addSubview:self.customBodyView];
    }
    else{

        CGSize size = [_bodyText sizeWithFont:self.bodyFont constrainedToSize:[self labelConstraint]];
        NSString *txt = [_bodyText stringByTruncatingToSize:size withFont:self.bodyFont addQuotes:NO];
        _bodyLabelButton = [[UIButton alloc] initWithFrame:CGRectMake(_contentRect.origin.x + _contentRect.size.width/2.0 - size.width/2.0 + self.contentEdgeInsets.left,
                                                                      CGRectGetMidY(_contentRect) - (size.height - _iconImageView.frame.size.height  - kIconLabelMargin)/2.0 + self.contentEdgeInsets.top - self.contentEdgeInsets.bottom,
                                                                      size.width - self.contentEdgeInsets.right - self.contentEdgeInsets.left,
                                                                      size.height)];
        _bodyLabelButton.autoresizingMask = [self defaultAutoResizingMask];
        [_bodyLabelButton addTarget:self action:@selector(didSelectBodyLabel:) forControlEvents:UIControlEventTouchUpInside];
        [_bodyLabelButton setTitle:_bodyText forState:UIControlStateNormal];

        _bodyLabelButton.titleLabel.text = txt;
        _bodyLabelButton.titleLabel.font = self.bodyFont;
        _bodyLabelButton.titleLabel.numberOfLines = 0;
        _bodyLabelButton.titleLabel.textAlignment = NSTextAlignmentCenter;

    }
    _bodyLabelButton.titleLabel.lineBreakMode = UILineBreakModeWordWrap;
    [self.view addSubview:_bodyLabelButton];
    return _bodyLabelButton;
}



- (UILabel*) titleLabel
{
    if (!_titleLabel) {

        CGRect rect = _backgroundButton.frame;

        CGSize size = [self titleConstraint];
        NSString *txt = [_titleText stringByTruncatingToSize:size withFont:self.titleFont addQuotes:NO];
        CGRect frame = CGRectMake(CGRectGetMidX(_contentRect) - size.width/2, CGRectGetMinY(_contentRect)+5, size.width, size.height);
        _titleLabel = [[UILabel alloc] initWithFrame:frame];
        _titleLabel.autoresizingMask = [self defaultAutoResizingMask];//UIViewAutoresizingFlexibleBottomMargin + UIViewAutoresizingFlexibleLeftMargin + UIViewAutoresizingFlexibleRightMargin;
        _titleLabel.text = txt;
        _titleLabel.font = self.titleFont;
        _titleLabel.textAlignment = NSTextAlignmentCenter;
        _titleLabel.backgroundColor = [UIColor clearColor];
        [self.view addSubview:_titleLabel];

    }

    return _titleLabel;
}

-(UIImageView*)iconImageView
{
    if(_iconImageView)
        return _iconImageView;
    _iconImageView = [[UIImageView alloc] init];
    return _iconImageView;
}

-(void)layoutView
{
    if(_iconImageView)
    {
        [_iconImageView sizeToFit];
        CGRect rect = self.iconImageView.frame;
        rect.origin = CGPointMake(self.contentRect.origin.x + (self.contentRect.size.width/2.0 - rect.size.width/2.0) + self.contentEdgeInsets.left, CGRectGetMidY(_contentRect) - (self.bodyLabelButton.frame.size.height + rect.size.height  + kIconLabelMargin)/2.0 + self.contentEdgeInsets.top);
        _iconImageView.frame = rect;
        _iconImageView.autoresizingMask = [self defaultAutoResizingMask];
        [self.view addSubview:self.iconImageView];
    }

    UIColor *bodyColor = self.bodyTextColor? self.bodyTextColor : [UIColor whiteColor];
    UIColor *titleColor = self.titleTextColor? self.titleTextColor : [UIColor whiteColor];
    [self.bodyLabelButton setTitleColor:bodyColor forState:UIControlStateNormal];
    [self.titleLabel setTextColor:titleColor];

    [_bodyLabelButton setBackgroundColor:[UIColor clearColor]];
//    [self.view addSubview:_bodyLabelButton];
    _buttons = [[NSMutableArray alloc] init];

    [self.items enumerateObjectsUsingBlock:^(MBAlertViewItem *item, NSUInteger index, BOOL *stop)
     {
         if (item.type != MBAlertViewItemTypeCustom) {

             MBAlertViewButton *buttonLabel = [[MBAlertViewButton alloc] initWithTitle:item.title];
             [buttonLabel addTarget:self action:@selector(didSelectButton:) forControlEvents:UIControlEventTouchUpInside];
             [buttonLabel addTarget:self action:@selector(didHighlightButton:) forControlEvents:UIControlEventTouchDown];
             [buttonLabel addTarget:self action:@selector(didRemoveHighlightFromButton:) forControlEvents:UIControlEventTouchUpOutside | UIControlEventTouchDragExit | UIControlEventTouchCancel];
             buttonLabel.tag = index;
             [_buttons addObject:buttonLabel];
         }
         else{
             item.customButton.tag = index;
             [item.customButton addTarget:self action:@selector(didSelectButton:) forControlEvents:UIControlEventTouchUpInside];
//             [item.customButton addTarget:self action:@selector(didHighlightButton:) forControlEvents:UIControlEventTouchDown];
//             [item.customButton addTarget:self action:@selector(didRemoveHighlightFromButton:) forControlEvents:UIControlEventTouchUpOutside | UIControlEventTouchDragExit | UIControlEventTouchCancel];
             [item.customButton setTitle:item.title forState:UIControlStateNormal];
             [_buttons addObject:item.customButton];
         }
     }];
}

-(void)centerViews
{
    [_buttons enumerateObjectsUsingBlock:^(MBAlertViewButton *button, NSUInteger idx, BOOL *stop)
    {
        if(_iconImageView)
        {
            if ([self.titleLabel.text length]) {
                [_backgroundButton centerViewsVerticallyWithin:@[@{@"view" : _iconImageView, @"offset" : [NSNumber numberWithFloat:0]}, @{@"view" : self.bodyLabelButton, @"offset" : [NSNumber numberWithFloat:5]}, @{@"view" : button, @"offset" : [NSNumber numberWithFloat:20]}]];
            }
            else{
                [_backgroundButton centerViewsVerticallyWithin:@[@{@"view" : self.titleLabel, @"offset" : [NSNumber numberWithFloat:0]}, @{@"view" : _iconImageView, @"offset" : [NSNumber numberWithFloat:0]}, @{@"view" : self.bodyLabelButton, @"offset" : [NSNumber numberWithFloat:0]}, @{@"view" : button, @"offset" : [NSNumber numberWithFloat:5]}]];
            }
        }
        else if([self.titleLabel.text length])
        {
            float offset = MAX(0, (_backgroundButton.frame.size.height - self.titleLabel.frame.size.height - self.bodyLabelButton.frame.size.height - button.frame.size.height - 5.0 - 10.0) / 2.0);  //5px top offset, 10px bottom offset
            [_backgroundButton centerViewsVerticallyWithin:@[@{@"view" : self.bodyLabelButton, @"offset" : [NSNumber numberWithFloat:0]}, @{@"view" : button, @"offset" : [NSNumber numberWithFloat:offset]}]];
        }
        else{
            [_backgroundButton centerViewsVerticallyWithin:@[@{@"view" : self.titleLabel, @"offset" : [NSNumber numberWithFloat:0]}, @{@"view" : self.bodyLabelButton, @"offset" : [NSNumber numberWithFloat:0]}, @{@"view" : button, @"offset" : [NSNumber numberWithFloat:5]}]];
        }
    }];
}


// lays out button on rotation
-(void)layoutButtonsWrapper
{
    [UIView animateWithDuration:0.3 animations:^{
        [self performLayoutOfButtons];
    }];
    [self centerViews];
}

-(void)performLayoutOfButtons
{
    CGRect bounds = self.view.bounds;
    int totalWidth = 0;
    for(MBAlertViewButton *item in _buttons) {
        CGSize size = item.frame.size;
        totalWidth += size.width + kSpaceBetweenButtons;
    }

    totalWidth -= kSpaceBetweenButtons;

    int xOrigOfFirstItem = bounds.size.width/2.0 - totalWidth/2.0;
    __block float currentXOrigin = xOrigOfFirstItem;

    [self.items enumerateObjectsUsingBlock:^(MBAlertViewItem *item, NSUInteger index, BOOL *stop)
     {
         UIButton *buttonLabel = [_buttons objectAtIndex:index];
         int origin = 0;
         if(index == 0)
             origin = currentXOrigin;
         else origin = currentXOrigin + kSpaceBetweenButtons;

         currentXOrigin = origin + buttonLabel.bounds.size.width;
         int yOrigin = CGRectGetMaxY(_bodyLabelButton.frame);

         CGRect rect = buttonLabel.frame;
         rect.origin = CGPointMake(origin, yOrigin);
         buttonLabel.frame = rect;

         if (item.type != MBAlertViewItemTypeCustom) {
             ((MBAlertViewButton *)buttonLabel).alertButtonType = item.type;
         }
         if(!buttonLabel.superview)
             [self.view addSubview:buttonLabel];

     }];

 //   UIInterfaceOrientation orientation = [UIApplication sharedApplication].statusBarOrientation;
/*
    if(orientation == UIDeviceOrientationLandscapeLeft || orientation == UIDeviceOrientationLandscapeRight)
    {
        CGSize size = [_bodyText sizeWithFont:self.bodyFont constrainedToSize:[self labelConstraint]];
        if (self.bodyCustomImage)
            size = self.bodyCustomImage.size;

        bounds = CGRectMake(0, 0, _backgroundButton.frame.size.width, size.height + 140);
        int landscapeOffset = 10;

        self.size = bounds.size;
        CGRect rect = CGRectMake(self.view.bounds.size.width/2.0 - self.size.width/2.0 , (self.view.bounds.size.height/2.0 - (self.size.height)/2.0) + landscapeOffset, self.size.width, self.size.height);
        _backgroundButton.frame = rect;
        _contentRect = _backgroundButton.frame;

        self.titleLabel.frame = CGRectMake(self.titleLabel.frame.origin.x, _contentRect.origin.y+4, self.titleLabel.frame.size.width, self.titleLabel.frame.size.height);
    }
*/
    /*

    UIInterfaceOrientation orientation = [UIApplication sharedApplication].statusBarOrientation;

    if(orientation == UIDeviceOrientationLandscapeLeft || orientation == UIDeviceOrientationLandscapeRight)
    {
        CGSize size = [_bodyText sizeWithFont:self.bodyFont constrainedToSize:[self labelConstraint]];

        int heightIncrease = size.height - 50;

        self.size = CGSizeMake(self.size.width, self.size.height+heightIncrease);
        CGRect rect = CGRectMake(self.view.bounds.size.width/2.0 - self.size.width/2.0 , (self.view.bounds.size.height/2.0 - (self.size.height+heightIncrease)/2.0), self.size.width, self.size.height + heightIncrease);
        _backgroundButton.frame = rect;
        _contentRect = _backgroundButton.frame;
    }
     */
}


#define kDismissDuration 0.25

-(void)hideWithFade
{
    self.view.alpha = 0.0;
    [self.view addFadingAnimationWithDuration:[self isMemberOfClass:[MBHUDView class]] ? 0.25 : 0.20];
    [self performSelector:@selector(removeAlertFromView) withObject:nil afterDelay:kDismissDuration];
}

-(void)didRemoveHighlightFromButton:(MBAlertViewButton*)button
{
    [button.layer removeAllAnimations];
}

-(void)addDismissAnimation
{
    NSArray *frameValues = @[[NSValue valueWithCATransform3D:CATransform3DMakeScale(1.0, 1.0, 1)],
                            [NSValue valueWithCATransform3D:CATransform3DMakeScale(0.95, 0.95, 1)],
                            [NSValue valueWithCATransform3D:CATransform3DMakeScale(1.15, 1.15, 1)],
                            [NSValue valueWithCATransform3D:CATransform3DMakeScale(0.01, 0.01, 1.0)]];

    NSArray *frameTimes = @[@(0.0), @(0.1), @(0.5), @(1.0)];
    CAKeyframeAnimation *animation = [self animationWithValues:frameValues times:frameTimes duration:kDismissDuration];
    animation.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseIn];

    [self.view.layer addAnimation:animation forKey:@"popup"];

    [self performSelector:@selector(hideWithFade) withObject:nil afterDelay:0.15];
}

-(void)addBounceAnimationToLayer:(CALayer*)layer
{
    if (self.appearAnimation) {
        [layer addAnimation:self.appearAnimation forKey:@"popup"];
    }
    else{
        NSArray *frameValues = @[[NSValue valueWithCATransform3D:CATransform3DMakeScale(0.1, 0.1, 1)],
                                 [NSValue valueWithCATransform3D:CATransform3DMakeScale(1.35, 1.35, 1)],
                                 [NSValue valueWithCATransform3D:CATransform3DMakeScale(0.8, 0.8, 1)],
                                 [NSValue valueWithCATransform3D:CATransform3DMakeScale(1.0, 1.0, 1)]];
        NSArray *frameTimes = @[@(0.0), @(0.5), @(0.9), @(1.0)];
        [layer addAnimation:[self animationWithValues:frameValues times:frameTimes duration:0.4] forKey:@"popup"];
    }

}

-(void)didSelectBodyLabel:(UIButton*)bodyLabelButton
{
    NSArray *frameValues = @[[NSValue valueWithCATransform3D:CATransform3DMakeScale(1.0, 1.0, 1)],
                            [NSValue valueWithCATransform3D:CATransform3DMakeScale(1.08, 1.08, 1)],
                            [NSValue valueWithCATransform3D:CATransform3DMakeScale(0.95, 0.95, 1)],
                            [NSValue valueWithCATransform3D:CATransform3DMakeScale(1.02, 1.02, 1)],
                            [NSValue valueWithCATransform3D:CATransform3DMakeScale(1.0, 1.0, 1)]];
    NSArray *frameTimes = @[@(0.0), @(0.1), @(0.7), @(0.9), @(1.0)];
    [bodyLabelButton.layer addAnimation:[self animationWithValues:frameValues times:frameTimes duration:0.3] forKey:@"popup"];
}

-(void)didHighlightButton:(MBAlertViewButton*)button
{
    NSArray *frameValues = @[[NSValue valueWithCATransform3D:CATransform3DMakeScale(1.0, 1.0, 1)],
                            [NSValue valueWithCATransform3D:CATransform3DMakeScale(1.25, 1.25, 1.0)]];
    NSArray *frameTimes = @[@(0.0), @(0.5)];
    [button.layer addAnimation:[self animationWithValues:frameValues times:frameTimes duration:0.25] forKey:@"popup"];
}

-(CAKeyframeAnimation*)animationWithValues:(NSArray*)values times:(NSArray*)times duration:(CGFloat)duration
{
    CAKeyframeAnimation *animation = [CAKeyframeAnimation animationWithKeyPath:@"transform"];
    animation.values = values;
    animation.keyTimes = times;
    animation.fillMode = kCAFillModeForwards;
    animation.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseOut];
    animation.removedOnCompletion = NO;
    animation.duration = duration;
    return animation;
}

- (void)setRotation:(NSNotification*)notification
{
    [self performSelector:@selector(layoutButtonsWrapper) withObject:nil afterDelay:0.01];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    [self layoutView];
}

- (void)viewDidUnload
{
    [super viewDidUnload];
    // Release any retained subviews of the main view.
}

-(BOOL)shouldAutorotate
{
    return YES;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

@end