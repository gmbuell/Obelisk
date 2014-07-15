//
//  GMBUtility.m
//  Obelisk
//
//  Created by Garret Buell on 6/17/14.
//
//

#import "GMBUtility.h"

@implementation GMBUtility

+ (void)showDropdownNotification:(NSString *)text {
  [[NSNotificationCenter defaultCenter]
      postNotificationName:@"DropdownNotification"
                    object:self
                  userInfo:@{
                    @"dropdownNotification" : text
                  }];
}

@end
