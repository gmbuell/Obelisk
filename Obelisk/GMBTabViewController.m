//
//  GMBTabViewController.m
//  Obelisk
//
//  Created by Garret Buell on 6/17/14.
//
//

#import "GMBTabViewController.h"
#import "GMBPlayViewController.h"
#import "GMBUtility.h"
#import "GMBChromecastManager.h"
#import "GMBDropdown.h"

@interface GMBTabViewController ()

// header animation properties
@property(strong, nonatomic) GMBDropdown *dropdown;

@end

@implementation GMBTabViewController

- (id)initWithNibName:(NSString *)nibNameOrNil
               bundle:(NSBundle *)nibBundleOrNil {
  self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
  if (self) {
    // Custom initialization
  }
  return self;
}

- (void)viewDidLoad {
  [super viewDidLoad];
  // Do any additional setup after loading the view.
  [self setupErrorHeader];
  [[NSNotificationCenter defaultCenter] addObserver:self
                                           selector:@selector(showNotification:)
                                               name:@"DropdownNotification"
                                             object:nil];

  self.delegate = self;
}

- (void)showNotification:(NSNotification *)notification {
  [self
      animateHeaderViewWithText:notification.userInfo[@"dropdownNotification"]];
}

- (void)didReceiveMemoryWarning {
  [super didReceiveMemoryWarning];
  // Dispose of any resources that can be recreated.
}

- (void)setupErrorHeader {
  // Animated header that displays error messages over status bar
  self.dropdown =
      [[GMBDropdown alloc] initWithFrame:CGRectMake(0, -20, 320, 20)];
  self.dropdown.rootViewController = self.selectedViewController;
  [self.dropdown makeKeyAndVisible];
  [self.dropdown resignKeyWindow];
}

// header animation
- (void)animateHeaderViewWithText:(NSString *)text {
  self.dropdown.label.text = text;

  [UIView animateWithDuration:.5
      delay:0
      options:0
      animations:^{ self.dropdown.frame = CGRectMake(0, 0, 320, 20); }
      completion:^(BOOL animateInFinished) {
          [UIView animateWithDuration:.5
              delay:2
              options:0
              animations:^{ self.dropdown.frame = CGRectMake(0, -20, 320, 20); }
              completion:^(BOOL animateOutFinished) {}];
          ;
      }];
}

- (void)tabBarController:(UITabBarController *)tabBarController
    didSelectViewController:(UIViewController *)viewController {
  self.dropdown.rootViewController = viewController;
  if (![[GMBChromecastManager sharedManager] isConnected] &&
      [viewController isKindOfClass:[UINavigationController class]] &&
      [((UINavigationController *)viewController).childViewControllers
          bk_any:^(UIViewController *child) {
              return [child isKindOfClass:[GMBPlayViewController class]];
          }]) {
    UIActionSheet *chooseDevice =
        [[UIActionSheet alloc] initWithTitle:@"Select Chromecast"
                                    delegate:nil
                           cancelButtonTitle:nil
                      destructiveButtonTitle:nil
                           otherButtonTitles:nil];
    for (GCKDevice *device in
         [GMBChromecastManager sharedManager].deviceScanner.devices) {
      [chooseDevice bk_addButtonWithTitle:device.friendlyName
                                  handler:^{
                                      [GMBChromecastManager sharedManager]
                                          .selectedDevice = device;
                                      [[GMBChromecastManager
                                              sharedManager] connectToDevice];
                                  }];
    }
    [chooseDevice
        setCancelButtonIndex:[chooseDevice addButtonWithTitle:@"Cancel"]];
    [chooseDevice showFromTabBar:self.tabBar];
  }
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little
preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.

}
 */

@end
