//
//  MBAlertView.h
//  Notestand
//
//  Created by M B. Bitar on 9/8/12.
//  Copyright (c) 2012 progenius, inc. All rights reserved.
//

// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in
// all copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
// THE SOFTWARE.

#import <UIKit/UIKit.h>
#import "MBAlertViewItem.h"
#import <QuartzCore/QuartzCore.h>

// notifications called when an alert/hud appears/disappears
extern NSString *const MBAlertViewDidAppearNotification;
extern NSString *const MBAlertViewDidDismissNotification;

// use these as needed
extern CGFloat MBAlertViewMaxHUDDisplayTime;
extern CGFloat MBAlertViewDefaultHUDHideDelay;

@interface MBAlertView : UIViewController
// if yes, will wait until alert has disappeared before performing any button blocks
@property (nonatomic, assign) BOOL shouldPerformBlockAfterDismissal;

// perform something after the alert dismisses
@property (nonatomic, copy) id uponDismissalBlock;

// huds by default are put on super view controller. however sometimes a hud appears right before a modal disappears. in that case we'll add the hud to the window
@property (nonatomic, assign) BOOL addsToWindow;

// Set to YES to add a semi-transparent mask over the background. default is YES.
@property (nonatomic, assign) BOOL addsMask;

// offset for HUD icons, or image offset if supplied
@property (nonatomic, assign) CGSize iconOffset;

// title of the alert
@property (nonatomic, copy) NSString *titleText;
@property (nonatomic, strong) UIFont *titleFont;
@property (nonatomic, strong) UIColor *titleTextColor;

// body is the main text of the alert. Ignored if customBodyView is non-nil.
@property (nonatomic, copy) NSString *bodyText;
@property (nonatomic, strong) UIFont *bodyFont;
@property (nonatomic, strong) UIColor *bodyTextColor;
@property (nonatomic, strong) UIImage *bodyCustomImage;

// you can set a custom view for the body. Default is nil.
// if customBodyView.frame.size > self.size, it will be scaled down to fit inside the alert. Otherwise, if customBodyView.frame.size <= sel.size, it is centered in the alert.
@property (nonatomic, strong) UIView *customBodyView;

// just set the iconImageView's image to activate
@property (nonatomic, strong) UIImageView *iconImageView;

// if not assigned, will be full screen
@property (nonatomic, assign) CGSize size;

// the opacity of the background.
@property (nonatomic, assign) float backgroundAlpha;

// set the background image for the alert view. If none set, uses black color as background.
@property (nonatomic, strong) UIImage *backgroundImage;

// content edge insets will shift alert label icon accordingly
@property (nonatomic, assign) UIEdgeInsets contentEdgeInsets;

@property (nonatomic, assign) int titleInset;
@property (nonatomic, assign) int bodyInset;

// set to YES to autoresize the alert when orientation changes. Default is NO.
@property (nonatomic, assign, getter = isAutoresizing) BOOL autoresizing;

// customize animation for alert appearance
@property (nonatomic, strong) CAKeyframeAnimation *appearAnimation;
-(CAKeyframeAnimation*)animationWithValues:(NSArray*)values times:(NSArray*)times duration:(CGFloat)duration;

-(void)dismiss;
-(void)addToDisplayQueue;
-(void)addButtonWithText:(NSString*)text type:(MBAlertViewItemType)type block:(id)block;
-(void)addCustomButton:(UIButton*)button dismissesAlert:(BOOL)dismisses block:(id)block;

// accessing button items in the alert
- (MBAlertViewItem*) buttonItemAtIndex : (NSUInteger) index;


#pragma mark Class methods
// factory methods

// Create an alert with a standard canel button
+(MBAlertView*)alertWithTitle:(NSString*)title message:(NSString*)body cancelTitle:(NSString*)cancelTitle cancelBlock:(id)cancelBlock;

// Create an alert with no buttons (you can add buttons using addButtonWithText: or addCustomButton:)
+(MBAlertView*)alertWithTitle:(NSString*)title message:(NSString*)body;



// yes if there is currently an alert or hud on screen
+(BOOL)alertIsVisible;

// dismisses current hud in queue, whether or not its visible
+(void)dismissCurrentHUD;
+(void)dismissCurrentHUDAfterDelay:(float)delay;

// a helper method that returns a size
+(CGSize)halfScreenSize;
@end
