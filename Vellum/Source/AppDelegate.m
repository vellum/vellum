
#import "AppDelegate.h"
#import "VLMMainViewController.h"
#import "GAI.h"
#import "VLMConstants.h"

@implementation AppDelegate
@synthesize window;
@synthesize mainViewController;

#pragma mark -
#pragma mark Application lifecycle

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    // Optionally set the idle timer disabled, this prevents the device from sleep when
    // not being interacted with by touch. ie. games with motion control.
    [application setIdleTimerDisabled:YES];
    
    VLMMainViewController *vc = [[VLMMainViewController alloc] init];
    [self setMainViewController:vc];
    [window setRootViewController:vc];
    
    
    // google
    // Optional: automatically send uncaught exceptions to Google Analytics.
    [GAI sharedInstance].trackUncaughtExceptions = YES;
    // Optional: set debug to YES for extra debugging information.
    [GAI sharedInstance].debug = YES;
    /*
    // Optional: set Google Analytics dispatch interval to e.g. 20 seconds.
    [GAI sharedInstance].dispatchInterval = 20;
    */
    // Create tracker instance.
    //id<GAITracker> tracker = [[GAI sharedInstance] trackerWithTrackingId:@"UA-41031955-1"];

    [self establishAppearanceDefaults];
    return YES;
}


#pragma mark -
#pragma mark appearance

- (void)establishAppearanceDefaults{
    
    // background images
    UIImage *clear = [[UIImage imageNamed:@"clear.png"] resizableImageWithCapInsets:UIEdgeInsetsMake(0, 0, 0, 0)];
    UIImage *clearfixed = [UIImage imageNamed:@"clear.png"];
    
    // set navbar background
    [[UINavigationBar appearance] setBackgroundImage:[UIImage imageNamed:@"gray_header_background.png"] forBarMetrics:UIBarMetricsDefault];
    // interestingly, backbutton needs its own adjustment
    
    // set navbar typography
    [[UINavigationBar appearance] setTitleTextAttributes: [NSDictionary dictionaryWithObjectsAndKeys:
                                                           [UIColor colorWithWhite:0.2f alpha:1.0f], UITextAttributeTextColor,
                                                           [UIColor clearColor], UITextAttributeTextShadowColor,
                                                           [UIFont fontWithName:@"Helvetica-Bold" size:18.f], UITextAttributeFont,
                                                           nil
                                                           ]];
    
    
    // bar button item background
[[UIBarButtonItem appearance] setBackgroundImage:clear forState:UIControlStateNormal barMetrics:UIBarMetricsDefault];
    [[UIBarButtonItem appearance] setBackgroundImage:clear forState:UIControlStateSelected barMetrics:UIBarMetricsDefault];
    
    
    // set plain bar button item typography
    [[UIBarButtonItem appearance] setTitleTextAttributes:[NSDictionary dictionaryWithObjectsAndKeys:
                                                          [UIColor clearColor], UITextAttributeTextShadowColor,
                                                          [UIColor colorWithWhite:0.2f alpha:1.0f], UITextAttributeTextColor,
                                                          [UIFont fontWithName:@"Helvetica-Bold" size:12.0f], UITextAttributeFont,
                                                          nil] // end dictionary
                                                forState:UIControlStateNormal
     ];
    [[UIBarButtonItem appearance] setTitleTextAttributes:[NSDictionary dictionaryWithObjectsAndKeys:
                                                          [UIColor clearColor], UITextAttributeTextShadowColor,
                                                          [UIColor colorWithWhite:1.0f alpha:1.0f], UITextAttributeTextColor,
                                                          [UIFont fontWithName:@"Helvetica-Bold" size:12.0f], UITextAttributeFont,
                                                          nil] // end dictionary
                                                forState:UIControlStateHighlighted
     ];
    [[UIBarButtonItem appearance] setTitleTextAttributes:[NSDictionary dictionaryWithObjectsAndKeys:
                                                          [UIColor clearColor], UITextAttributeTextShadowColor,
                                                          [UIColor colorWithWhite:1.0f alpha:1.0f], UITextAttributeTextColor,
                                                          [UIFont fontWithName:@"Helvetica-Bold" size:12.0f], UITextAttributeFont,
                                                          nil] // end dictionary
                                                forState:UIControlStateHighlighted
     ];
    [[UIBarButtonItem appearance] setTitleTextAttributes:[NSDictionary dictionaryWithObjectsAndKeys:
                                                          [UIColor clearColor], UITextAttributeTextShadowColor,
                                                          [UIColor colorWithWhite:0.2f alpha:0.2f], UITextAttributeTextColor,
                                                          [UIFont fontWithName:@"Helvetica-Bold" size:12.0f], UITextAttributeFont,
                                                          nil] // end dictionary
                                                forState:UIControlStateDisabled
     ];
    [[UIBarButtonItem appearance] setTitlePositionAdjustment:UIOffsetMake(0.0f, BAR_BUTTON_ITEM_VERTICAL_OFFSET) forBarMetrics:UIBarMetricsDefault];
    
    [[UIBarButtonItem appearance] setBackButtonBackgroundVerticalPositionAdjustment:BAR_BUTTON_ITEM_VERTICAL_OFFSET forBarMetrics:UIBarMetricsDefault];
    
    [[UIBarButtonItem appearance] setBackButtonBackgroundImage:clearfixed forState:UIControlStateNormal barMetrics:UIBarMetricsDefault];

    
}

@end
