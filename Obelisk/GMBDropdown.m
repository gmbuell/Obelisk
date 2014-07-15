//
//  GMBDropdown.m
//  Obelisk
//
//  Created by Garret Buell on 6/21/14.
//
//

#import "GMBDropdown.h"

@implementation GMBDropdown

- (id)initWithFrame:(CGRect)frame {
  self = [super initWithFrame:frame];
  if (self) {
    // Initialization code
    self.backgroundColor = [UIColor whiteColor];
    self.label = [[UILabel alloc] initWithFrame:self.bounds];
    self.label.textAlignment = NSTextAlignmentCenter;
    self.label.font = [UIFont systemFontOfSize:12];
    self.label.backgroundColor = [UIColor clearColor];
    [self addSubview:self.label];
    self.windowLevel = UIWindowLevelStatusBar;
  }
  return self;
}

- (void)drawRect:(CGRect)rect {
  [super drawRect:rect];
  CGContextRef context = UIGraphicsGetCurrentContext();
  [UIColorFromRGB(0xFF4136) setStroke];
  // CGContextStrokeRectWithWidth(context, self.bounds, 2);
  CGContextSetLineWidth(context, 3.0f);
  CGContextStrokeLineSegments(
      context,
      (const CGPoint[]) {
          CGPointMake(CGRectGetMinX(self.bounds), CGRectGetMaxY(self.bounds)),
          CGPointMake(CGRectGetMaxX(self.bounds), CGRectGetMaxY(self.bounds))},
      2);
}

@end
