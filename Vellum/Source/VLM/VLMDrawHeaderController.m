//
//  VLMDrawHeaderController.m
//  Ejecta
//
//  Created by David Lu on 4/28/13.
//
//

#import "VLMDrawHeaderController.h"
#import "DDPageControl.h"

#define HEADER_LABEL_WIDTH 175.0f

@interface VLMDrawHeaderController ()
@property (nonatomic, strong) NSArray *titles;
@property (nonatomic, strong) UIView *titleview;
@property (nonatomic, strong) UIButton *leftbutton;
@property (nonatomic, strong) UIButton *rightbutton;
@property (nonatomic, strong) UIView *cancelbutton;
@property (nonatomic, strong) UIView *titlemask;
@property (nonatomic, strong) UILabel *ghostlabel;
@property (nonatomic) NSInteger index;
@property CGRect titleframe;
@property CGRect titlemaskframe;
@end

@implementation VLMDrawHeaderController
@synthesize titles;
@synthesize index;
@synthesize titleview;
@synthesize titleframe;
@synthesize titlemask;
@synthesize titlemaskframe;
@synthesize pagecontrol;
@synthesize delegate;
@synthesize leftbutton;
@synthesize rightbutton;
@synthesize isPopoverVisible;
@synthesize cancelbutton;
@synthesize ghostlabel;

- (id) initWithHeadings:(NSArray *)headings{
    self = [self init];
    if (self){
        self.index = 0;
        self.titles = [NSArray arrayWithArray:headings];
        self.isPopoverVisible = NO;
    }
    return self;
}


- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        self.index = 0;
        self.isPopoverVisible = NO;
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    CGFloat HEADER_HEIGHT = 60.0f;
    CGFloat winw = [[UIScreen mainScreen] bounds].size.width;
    self.index = 0;

	[self.view setFrame:CGRectMake(0, 0, winw, HEADER_HEIGHT)];
    [self.view setBackgroundColor:[UIColor whiteColor]];
    [self.view setClipsToBounds:YES];
    
    
    UIButton *pb = [[UIButton alloc] initWithFrame:CGRectMake(0, 0, HEADER_HEIGHT, HEADER_HEIGHT)];
    [pb setBackgroundImage:[UIImage imageNamed:@"button_plus_off"] forState:UIControlStateNormal];
    [pb setBackgroundImage:[UIImage imageNamed:@"button_plus_on"] forState:UIControlStateHighlighted];
    [self.view addSubview:pb];
    [pb addTarget:self action:@selector(plusTapped:) forControlEvents:UIControlEventTouchUpInside];
    self.leftbutton = pb;
    
    UIButton *ab = [[UIButton alloc] initWithFrame:CGRectMake(winw-HEADER_HEIGHT, 0, HEADER_HEIGHT, HEADER_HEIGHT)];
    [ab setBackgroundImage:[UIImage imageNamed:@"button_action_off"] forState:UIControlStateNormal];
    [ab setBackgroundImage:[UIImage imageNamed:@"button_action_on"] forState:UIControlStateHighlighted];
    [ab addTarget:self action:@selector(actionTapped:) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:ab];
    self.rightbutton = ab;
    
    UIView *cancel = [[UIView alloc] initWithFrame:CGRectMake(0, 0, winw, HEADER_HEIGHT)];
    cancel.backgroundColor = [UIColor whiteColor];
    cancel.userInteractionEnabled = NO;
    [self.view addSubview:cancel];
    cancel.alpha = 0;
    self.cancelbutton = cancel;
    
    UITapGestureRecognizer *canceltapped = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleCancelPopover:)];
    [self.cancelbutton addGestureRecognizer:canceltapped];
    

    // - - - -
    
    UIView *titleviewmask = [[UIView alloc] initWithFrame:CGRectMake(winw/2-HEADER_LABEL_WIDTH/2, 0, HEADER_LABEL_WIDTH, HEADER_HEIGHT)];
    [titleviewmask setClipsToBounds:YES];
    [titleviewmask setBackgroundColor:[UIColor clearColor]];
    [self.view addSubview:titleviewmask];
    self.titleframe = CGRectMake(0, 0, 300.0f, HEADER_HEIGHT);
    self.titleview = [[UIView alloc] initWithFrame:self.titleframe];
    [titleviewmask addSubview:titleview];
    [titleview setBackgroundColor:[UIColor clearColor]];
    [self setupHeadingView];
    self.titlemask = titleviewmask;
    self.titlemaskframe = titleviewmask.frame;
    
    self.pagecontrol = [[DDPageControl alloc] init];
    [self.pagecontrol setCenter:CGPointMake(titleviewmask.frame.size.width/2, HEADER_HEIGHT - 14 + 3)];
    [self.pagecontrol setNumberOfPages:10];
    [self.pagecontrol setCurrentPage:0];
    //[self.pagecontrol setDefersCurrentPageDisplay:YES];
    [self.pagecontrol setOnColor:[UIColor colorWithWhite:0.0f alpha:1.0f]];
    [self.pagecontrol setOffColor:[UIColor colorWithWhite:0.9f alpha:1.0f]];
    [self.pagecontrol setIndicatorDiameter:5.0f];
    [self.pagecontrol setIndicatorSpace:7.0f];
    [self.pagecontrol setUserInteractionEnabled:NO];
    [titleviewmask addSubview:self.pagecontrol];
    
    self.ghostlabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, HEADER_LABEL_WIDTH, HEADER_HEIGHT)];
    [ghostlabel setFont:[UIFont fontWithName:@"Helvetica-Bold" size:18.0f]];
    [ghostlabel setTextColor:[UIColor blackColor]];
    [ghostlabel setTextAlignment:UITextAlignmentCenter];
    [ghostlabel setBackgroundColor:[UIColor clearColor]];
    [ghostlabel setAlpha:0.0f];
    [ghostlabel setUserInteractionEnabled:NO];
    [self.titlemask addSubview:ghostlabel];

    
    UISwipeGestureRecognizer *sgr = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(nextPage)];
    [sgr setDirection:UISwipeGestureRecognizerDirectionLeft];
    [titleviewmask addGestureRecognizer:sgr];
    
    UISwipeGestureRecognizer *sgr2 = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(prevPage)];
    [sgr2 setDirection:UISwipeGestureRecognizerDirectionRight];
    [titleviewmask addGestureRecognizer:sgr2];
    
    UITapGestureRecognizer *tgr = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tapped)];
    [titleviewmask addGestureRecognizer:tgr];
    
    UILongPressGestureRecognizer *lpr = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(longPress:)];
    [lpr setNumberOfTapsRequired:0];
    [lpr setNumberOfTouchesRequired:1];
    [titleviewmask addGestureRecognizer:lpr];

    
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


#pragma mark - ()

- (void) setHeadings:(NSArray *)headings{
    self.titles = [NSArray arrayWithArray:headings];
    [self setupHeadingView];
}

- (void) setupHeadingView{
    CGFloat HEADER_HEIGHT = 60.0f;
    int count = [self.titles count];
    [self.titleview setFrame:CGRectMake(0, 0, count*HEADER_LABEL_WIDTH, HEADER_HEIGHT)];

    NSArray* subViews = self.titleview.subviews;
    for( UIView *aView in subViews ) {
        [aView removeFromSuperview];
    }
    
    for ( int i = 0; i < [self.titles count]; i++ ){
        NSString *t = self.titles[i];
        UILabel *A = [[UILabel alloc] initWithFrame:CGRectMake(i*HEADER_LABEL_WIDTH, 0, HEADER_LABEL_WIDTH, HEADER_HEIGHT)];
        [A setText:t];
        [A setFont:[UIFont fontWithName:@"Helvetica-Bold" size:18.0f]];
        [A setTextColor:[UIColor blackColor]];
        [A setTextAlignment:UITextAlignmentCenter];
        [A setBackgroundColor:[UIColor clearColor]];
        [self.titleview addSubview:A];
    }
    [self.pagecontrol setNumberOfPages:[self.titles count]];
    [self.pagecontrol setCurrentPage:0];
    

}

- (void) setSelectedIndex:(NSInteger)selectedIndex andTitle:(NSString *)title{
    NSLog(@"setselected %d",selectedIndex);
    [self setSelectedIndex:selectedIndex andTitle:title animated:YES];
}
- (void) setSelectedIndex:(NSInteger)selectedIndex andTitle:(NSString *)title animated:(BOOL)shouldAnimate{
    if (selectedIndex != -1){
        self.index = selectedIndex;
        [self.pagecontrol setCurrentPage:self.index];
        
        if (self.ghostlabel.alpha == 1)
        {
            [self.titleview setFrame:CGRectOffset(titleframe, -self.index*HEADER_LABEL_WIDTH, 0)];
        }
        [UIView animateWithDuration: shouldAnimate ? 0.25f : 0
                              delay:0.0f
                            options:UIViewAnimationCurveEaseInOut|UIViewAnimationOptionBeginFromCurrentState
                         animations:^{
                             if (self.ghostlabel.alpha == 0){
                                 [self.titleview setFrame:CGRectOffset(titleframe, -self.index*HEADER_LABEL_WIDTH, 0)];
                             }
                             [self.pagecontrol setAlpha:1.0f];
                             [self.titleview setAlpha:1.0f];
                             [self.ghostlabel setAlpha:0.0f];
                         }
                         completion:^(BOOL finished){
                         }
         ];
        
        
    } else {
        NSLog(@"hi");
        [self.ghostlabel setText:title];
        
        [UIView animateWithDuration:shouldAnimate ? 0.25f : 0
                              delay:0.0f
                            options:UIViewAnimationCurveEaseInOut|UIViewAnimationOptionBeginFromCurrentState
                         animations:^{
                             [self.pagecontrol setAlpha:0.0f];
                             [self.titleview setAlpha:0.0f];
                             [self.ghostlabel setAlpha:1.0f];
                         }
                         completion:^(BOOL finished){
                         }
         ];
        
        //[self.titleview setFrame:CGRectOffset(titleframe, -self.index*HEADER_LABEL_WIDTH, 0)];
        //[self.pagecontrol setCurrentPage:self.index];
        
    }

}

- (void) tapped{
    if (self.ghostlabel.alpha == 1){
        [self togglePopover];
        return;
    }
    self.index++;
    if (self.index > [self.titles count] - 1){
        self.index = 0;
    }
    [UIView animateWithDuration:0.25f
                          delay:0.0f
                        options:UIViewAnimationCurveEaseInOut|UIViewAnimationOptionBeginFromCurrentState
                     animations:^{
                         [self.pagecontrol setAlpha:1.0f];
                         [self.titleview setAlpha:1.0f];
                         [self.ghostlabel setAlpha:0.0f];
                     }
                     completion:^(BOOL finished){
                     }
     ];

    [self.titleview setFrame:CGRectOffset(titleframe, -self.index*HEADER_LABEL_WIDTH, 0)];
    [self.pagecontrol setCurrentPage:self.index];
    if (self.delegate){
        [self.delegate updateIndex:self.index AndTitle:self.titles[self.index]];
    }
}

- (void) nextPage{
    self.index++;
    if (self.index > [self.titles count] - 1){
        self.index = [self.titles count] - 1;
    }
    [self updatePage];
}

- (void) prevPage{
    self.index--;
    if (self.index < 0 ){
        self.index = 0;
    }
    [self updatePage];
}

- (void)updatePage{

    [UIView animateWithDuration:0.25f
                          delay:0.0f
                        options:UIViewAnimationCurveEaseInOut|UIViewAnimationOptionBeginFromCurrentState
                     animations:^{
                         [self.titleview setFrame:CGRectOffset(titleframe, -self.index*HEADER_LABEL_WIDTH, 0)];
                         [self.pagecontrol setAlpha:1.0f];
                         [self.titleview setAlpha:1.0f];
                         [self.ghostlabel setAlpha:0.0f];
                     }
                     completion:^(BOOL finished){
                         [self.pagecontrol setCurrentPage:self.index];
                     }
     ];
    if (self.delegate){
        [self.delegate updateIndex:self.index AndTitle:self.titles[self.index]];
    }
}

- (void)longPress:(id)sender{
    UILongPressGestureRecognizer *lpr = (UILongPressGestureRecognizer *)sender;
    if (lpr.state == UIGestureRecognizerStateBegan){
        [self togglePopover];
    }
}

- (void)handleCancelPopover:(id)sender{
    [self togglePopover];
}

- (void)togglePopover{

    self.isPopoverVisible = !self.isPopoverVisible;
    
    if ( self.isPopoverVisible ){
        [UIView beginAnimations:nil context:NULL];
        [UIView setAnimationDelay:0];
        [UIView setAnimationCurve:UIViewAnimationCurveEaseInOut];
        [UIView setAnimationDuration:0.3];
        [self.cancelbutton setAlpha:0.92];
        [self.cancelbutton setUserInteractionEnabled:YES];
        [UIView commitAnimations];

        [self.delegate showPopover];
    } else {
        [UIView beginAnimations:nil context:NULL];
        [UIView setAnimationDelay:0];
        [UIView setAnimationCurve:UIViewAnimationCurveEaseInOut];
        [UIView setAnimationDuration:0.3];
        [self.cancelbutton setAlpha:0];
        [self.cancelbutton setUserInteractionEnabled:NO];
        [UIView commitAnimations];
        [self.delegate hidePopover];
    }
    
}

- (void) resetToZero{
    if ( [self.titles count] > 0 ){
        self.index = 0;
        [self updatePage];
    }
}


#pragma mark - UIActionSheetDelegate

- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex {
    NSLog(@"clicked:%d", buttonIndex);
    if (buttonIndex ==0){
        [self.delegate clearScreen];
    }
    
}

#pragma mark - headerdelegate

- (void)plusTapped:(id)sender{
    NSLog(@"tap");
    UIActionSheet *actionSheet = [[UIActionSheet alloc] initWithTitle:nil delegate:self cancelButtonTitle:@"Cancel" destructiveButtonTitle:nil otherButtonTitles:@"Start Again", nil];

    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
        UIButton *btn = (UIButton *)sender;
        CGRect c = btn.frame;
        [actionSheet showFromRect:c inView:self.view animated:YES];
    } else {
        [actionSheet showInView:self.view.superview];
    }

}

- (void)actionTapped:(id)sender{
    
    NSLog(@"actiontapped");
    [self.delegate screenCapture:self];
}


#pragma mark - screenshotdelegate
- (void)screenShotFound:(UIImage *)found{
    NSArray* dataToShare = [NSArray arrayWithObject:found];
    UIActivityViewController* activityViewController = [[UIActivityViewController alloc] initWithActivityItems:dataToShare applicationActivities:nil];

    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
        UIPopoverController *popovercontroller = [[UIPopoverController alloc] initWithContentViewController:activityViewController];
        [popovercontroller presentPopoverFromRect:self.rightbutton.frame inView:self.view permittedArrowDirections:UIPopoverArrowDirectionAny animated:YES];
    } else {
        [self presentViewController:activityViewController animated:YES completion:^{}];
    }
}

@end
