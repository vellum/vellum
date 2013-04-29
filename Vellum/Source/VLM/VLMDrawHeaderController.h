//
//  VLMDrawHeaderController.h
//  Ejecta
//
//  Created by David Lu on 4/28/13.
//
//

#import <UIKit/UIKit.h>

@protocol VLMHeaderDelegate
- (void)updateIndex:(NSInteger)index AndTitle:(NSString *)title;
@end

@interface VLMDrawHeaderController : UIViewController

@property (nonatomic, retain) NSObject<VLMHeaderDelegate> *delegate;

- (id) initWithHeadings:(NSArray *)headings;
- (void) setHeadings:(NSArray *)headings;
- (void) nextPage;
- (void) prevPage;

@end