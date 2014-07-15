//
//  GMBPlayViewController.m
//  Obelisk
//
//  Created by Garret Buell on 6/15/14.
//
//

#import "GMBChromecastManager.h"
#import "GMBPlayViewController.h"
#import "SCPlaybackViewController.h"
#import "SCPlaybackItem.h"

@interface GMBPlayViewController ()
@property(nonatomic, strong) SCPlaybackViewController *playbackViewController;
@end

@implementation GMBPlayViewController

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
  self.playbackViewController = [[SCPlaybackViewController alloc] init];
  [self.playbackViewController willMoveToParentViewController:self];
  [self addChildViewController:self.playbackViewController];
  [self.view addSubview:self.playbackViewController.view];
  [self.playbackViewController didMoveToParentViewController:self];

  self.playbackViewController.view.frame = CGRectMake(
      0.f, CGRectGetHeight(self.view.bounds) -
               CGRectGetHeight(self.playbackViewController.view.bounds) -
               CGRectGetHeight(self.tabBarController.tabBar.frame),
      CGRectGetWidth(self.view.bounds),
      CGRectGetHeight(self.playbackViewController.view.bounds));

  SCPlaybackItem *playbackItem = [[SCPlaybackItem alloc] init];
  self.playbackViewController.playbackItem = playbackItem;
  self.playbackViewController.playbackItem.totalTime = 0.f;
  self.playbackViewController.playbackItem.elapsedTime = 0.f;
}

- (void)viewWillAppear:(BOOL)animated {
  if ([GMBChromecastManager sharedManager].mediaControlChannel) {
    NSLog(@"Requesting status");
    if ([[GMBChromecastManager sharedManager]
                .mediaControlChannel requestStatus] == kGCKInvalidRequestID) {
      NSLog(@"Invalid request id");
    }
  }
  [super viewWillAppear:animated];
}

- (void)didReceiveMemoryWarning {
  [super didReceiveMemoryWarning];
  // Dispose of any resources that can be recreated.
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
