 MBAlertView
===================

MBAlertView is a fun and simple block-based alert and HUD library for iOS, as seen in [Notestand.](https://itunes.apple.com/us/app/notestand-notes-discussions/id586976282?mt=8)

[![](http://i.imgur.com/3s3eJ.png)](http://i.imgur.com/3s3eJ.png)
[![](http://i.imgur.com/7CbbT.png)](http://i.imgur.com/7CbbT.png) 
[![](http://i.imgur.com/lq53u.png)](http://i.imgur.com/lq53u.png)
[![](http://i.imgur.com/Aqfnr.png)](http://i.imgur.com/Aqfnr.png)

### Features
<ul>
	<li>Nested alerts and HUDs</li>
	<li>Block based</li>
	<li>Images</li>
	<li>Nice animations</li>
	<li>Doesn't use any PNG files. Everything is drawn with code.</li>
</ul>

### Extended Features in this fork

``` objective-c
// create an alert view with 'title' and 'message', using default colors, layout and no buttons
    MBAlertView *alert = [MBAlertView alertWithTitle:title message:message];

// set the title font
    alert.titleFont = [UIFont fontWithName:@"MyCustomFont-Regular"  size:22];

// set custom background image for the alert view.
    alert.backgroundImage = [UIImage imageNamed:@"Popup_Box_Background"];

// set the size for the alert view, in this case match the background image size
	alert.size = alert.backgroundImage.size;

/* By default, the message of the alert is centered in the alert's bounds. 
   However, our Popup_Box_Background contains drop shadow, 
   which offsets the actual center from the visible center of the popup rect (without the shadow).
   offset the content upward a bit by setting contentEdgeInsets 
*/
    alert.contentEdgeInsets = UIEdgeInsetsMake(0, 0, 14, 0);

// add custom cancel button
   UIImage *image = [UIImage imageNamed:@"Cancel_Button_Background"];
   UIButton *button = [[UIButton alloc] initWithFrame:(CGRect){CGPointZero, image.size}];
   [button setBackgroundImage:image forState:UIControlStateNormal];
   [button.titleLabel setFont:[UIFont fontWithName:@"MyCustomFont-Regular" size:16]];
   [button setTitle:cancelTitle forState:UIControlStateNormal];
    
   [alert addCustomButton:button block:^{
   		// any button automatically dismisses the alert view
   		// this block is useful for additional handler code after the alert is dismissed. 
   }]; 
 
   [alert addToDisplayQueue];
```


## Usage

There are two factory methods to get you started:

### Alerts

``` objective-c
// Create an alert with a standard canel button
+(MBAlertView*)alertWithTitle:(NSString*)title message:(NSString*)body cancelTitle:(NSString*)cancelTitle cancelBlock:(id)cancelBlock;

// Create an alert with no buttons (you can add buttons using addButtonWithText: or addCustomButton:)
+(MBAlertView*)alertWithTitle:(NSString*)title message:(NSString*)body;
[alert addToDisplayQueue];
```

### HUDs

``` objective-c
[MBHUDView hudWithBody:@"Wait." type:MBAlertViewHUDTypeActivityIndicator hidesAfter:4.0 show:YES];
```

You can see more in the easy to follow demo.

## License
MBAlertView is available under the MIT license.