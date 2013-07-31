//
//  VLMColorData.h
//  Vellum
//
//  Created by David Lu on 7/31/13.
//
//

#import <Foundation/Foundation.h>

@interface VLMColorData : NSObject

@property (nonatomic, strong) NSString *name;
@property (nonatomic, strong) NSString *labeltext;
@property (nonatomic) CGFloat opacity;
- (id)init;
- (id)initWithName:(NSString*)colorname Label:(NSString*)colorlabel Opacity:(CGFloat)coloropacity;
@end

