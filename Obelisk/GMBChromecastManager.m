//
//  GMBChromecastManager.m
//  Obelisk
//
//  Created by Garret Buell on 6/16/14.
//
//

#import "GMBChromecastManager.h"
#import "GMBUtility.h"

@interface GMBChromecastManager ()

@property(nonatomic, copy) void (^launchedBlock)(void);

@end

@implementation GMBChromecastManager

+ (GMBChromecastManager *)sharedManager {
  static GMBChromecastManager *_sharedInstance = nil;
  static dispatch_once_t oncePredicate;
  dispatch_once(&oncePredicate,
                ^{ _sharedInstance = [[GMBChromecastManager alloc] init]; });
  return _sharedInstance;
}

- (void)dealloc {
  self.launchedBlock = NULL;
}

- (id)init {
  if (self = [super init]) {
    self.deviceScanner = [[GCKDeviceScanner alloc] init];
    [self.deviceScanner addListener:self];
  }
  return self;
}

- (void)startDeviceScan {
  [self.deviceScanner startScan];
  [NSTimer scheduledTimerWithTimeInterval:5.0
                                   target:self
                                 selector:@selector(stopDeviceScan:)
                                 userInfo:nil
                                  repeats:NO];
}

- (void)stopDeviceScan:(NSTimer *)timer {
  if (self.deviceScanner.scanning) {
    NSLog(@"Stopping scan for devices");
    [self.deviceScanner stopScan];
    NSUInteger count = [self.deviceScanner.devices count];
    [GMBUtility showDropdownNotification:
                    [NSString stringWithFormat:@"Found %i %s", count,
                                               count == 1 ? "Chromecast"
                                                          : "Chromecasts"]];
  }
}

- (BOOL)isConnected {
  return self.deviceManager.isConnected;
}

- (void)updateStatsFromDevice {
  if (self.isConnected && self.mediaControlChannel &&
      self.mediaControlChannel.mediaStatus) {
    _mediaInformation = self.mediaControlChannel.mediaStatus.mediaInformation;
    NSLog(@"Stream length is: %f", _mediaInformation.streamDuration);
    NSLog(@"Sending media status update");
    [[NSNotificationCenter defaultCenter]
        postNotificationName:@"MediaStatusUpdate"
                      object:self
                    userInfo:nil];
  }
}

- (void)connectToDevice {
  if (self.selectedDevice == nil) {
    return;
  }

  NSDictionary *info = [[NSBundle mainBundle] infoDictionary];
  self.deviceManager = [[GCKDeviceManager alloc]
         initWithDevice:self.selectedDevice
      clientPackageName:[info objectForKey:@"CFBundleIdentifier"]];
  self.deviceManager.delegate = self;
  [self.deviceManager connect];
}

- (void)stopPlayback {
  NSLog(@"Stop playback called");
  if (self.selectedDevice && self.deviceManager) {
    NSLog(@"Disconnecting device:%@", self.selectedDevice.friendlyName);
    // New way of doing things: We're not going to stop the applicaton. We're
    // just going to leave it.
    [self.deviceManager leaveApplication];
    [self.deviceManager disconnect];

    [self deviceDisconnected];
  }
}

- (void)connectToDeviceAndPlay:(GMBVideoItem *)video {
  __weak GMBChromecastManager *self_ = self;
  self.launchedBlock = ^{ [self_ castVideo:video]; };
  [self connectToDevice];
}

- (void)deviceDisconnected {
  NSLog(@"Device disconnected");
  self.mediaControlChannel = nil;
  self.deviceManager = nil;
  self.selectedDevice = nil;
  self.launchedBlock = NULL;
}

// Cast video
- (void)castVideo:(GMBVideoItem *)video {
  NSLog(@"Selected %@ (%@)", video.title, video.size);

  // Show alert if not connected
  if (!self.selectedDevice || !self.deviceManager ||
      !self.deviceManager.isConnected) {
    UIActionSheet *chooseDevice =
        [[UIActionSheet alloc] initWithTitle:@"Select Chromecast"
                                    delegate:nil
                           cancelButtonTitle:nil
                      destructiveButtonTitle:nil
                           otherButtonTitles:nil];
    for (GCKDevice *device in self.deviceScanner.devices) {
      [chooseDevice bk_addButtonWithTitle:device.friendlyName
                                  handler:^{
                                      self.selectedDevice = device;
                                      [self connectToDeviceAndPlay:video];
                                  }];
    }
    [chooseDevice
        setCancelButtonIndex:
            [chooseDevice
                bk_addButtonWithTitle:
                    @"Cancel" handler:^{
                        [GMBUtility showDropdownNotification:
                                        @"No chromecast selected for playback"];
                    }]];
    [chooseDevice
        showFromTabBar:((UITabBarController *)
                        [[[UIApplication sharedApplication] delegate] window]
                            .rootViewController).tabBar];

    return;
  }

  NSLog(@"Playing video");

  // Define Media metadata
  GCKMediaMetadata *metadata = [[GCKMediaMetadata alloc] init];

  [metadata setString:@"Big Buck Bunny (2008)" forKey:kGCKMetadataKeyTitle];

  [metadata
      setString:@"Big Buck Bunny tells the story of a giant rabbit with a "
      @"heart bigger than "
       "himself. When one sunny day three rodents rudely harass him, "
       "something "
       "snaps... and the rabbit ain't no bunny anymore! In the "
       "typical cartoon "
       "tradition he prepares the nasty rodents a comical revenge."
         forKey:kGCKMetadataKeySubtitle];

  [metadata
      addImage:
          [[GCKImage alloc]
              initWithURL:
                  [[NSURL alloc]
                      initWithString:
                          @"http://commondatastorage.googleapis.com/"
                           "gtv-videos-bucket/sample/images/BigBuckBunny.jpg"]
                    width:480
                   height:360]];

  // define Media information
  GCKMediaInformation *mediaInformation = [[GCKMediaInformation alloc]
      // initWithContentID:[NSString stringWithFormat:@"%@%@",
      //                                              @"http://gmbuell.com/video/",
      //                                              video.title]
      initWithContentID:@"http://commondatastorage.googleapis.com/"
      @"gtv-videos-bucket/sample/BigBuckBunny.mp4"
             streamType:GCKMediaStreamTypeNone
            contentType:@"video/mp4"
               metadata:metadata
         streamDuration:0
             customData:nil];

  // cast video
  [_mediaControlChannel loadMedia:mediaInformation
                         autoplay:TRUE
                     playPosition:0];
}

#pragma mark - GCKDeviceScannerListener
- (void)deviceDidComeOnline:(GCKDevice *)device {
  NSLog(@"device found!!!");
  [GMBUtility
      showDropdownNotification:[NSString stringWithFormat:@"Found: %@",
                                                          device.friendlyName]];
}

- (void)deviceDidGoOffline:(GCKDevice *)device {
  [GMBUtility
      showDropdownNotification:[NSString stringWithFormat:@"%@ disconnected",
                                                          device.friendlyName]];
  if (device == self.selectedDevice) {
    [self deviceDisconnected];
  }
}

#pragma mark - GCKDeviceManagerDelegate

- (void)deviceManagerDidConnect:(GCKDeviceManager *)deviceManager {
  NSLog(@"connected!!");
  [self.deviceManager launchApplication:kGCKMediaDefaultReceiverApplicationID];
}

- (void)deviceManager:(GCKDeviceManager *)deviceManager
    didConnectToCastApplication:(GCKApplicationMetadata *)applicationMetadata
                      sessionID:(NSString *)sessionID
            launchedApplication:(BOOL)launchedApplication {
  NSLog(@"application has launched");
  self.mediaControlChannel = [[GCKMediaControlChannel alloc] init];
  self.mediaControlChannel.delegate = self;
  [self.deviceManager addChannel:self.mediaControlChannel];

  if (self.launchedBlock) {
    self.launchedBlock();
    self.launchedBlock = nil;
  }

  [self.mediaControlChannel requestStatus];
}

- (void)deviceManager:(GCKDeviceManager *)deviceManager
    didFailToConnectToApplicationWithError:(NSError *)error {
  [GMBUtility showDropdownNotification:
                  [NSString stringWithFormat:@"Chromecast Error: %@", error]];

  [self deviceDisconnected];
}

- (void)deviceManager:(GCKDeviceManager *)deviceManager
    didFailToConnectWithError:(GCKError *)error {
  [GMBUtility showDropdownNotification:
                  [NSString stringWithFormat:@"Chromecast Error: %@", error]];

  [self deviceDisconnected];
}

- (void)deviceManager:(GCKDeviceManager *)deviceManager
    didDisconnectWithError:(GCKError *)error {
  NSLog(@"Received notification that device disconnected");

  if (error != nil) {
    [GMBUtility showDropdownNotification:
                    [NSString stringWithFormat:@"Chromecast Error: %@", error]];
  }

  [self deviceDisconnected];
}

- (void)deviceManager:(GCKDeviceManager *)deviceManager
    didReceiveStatusForApplication:
        (GCKApplicationMetadata *)applicationMetadata {
  NSLog(@"Device status received");
  self.applicationMetadata = applicationMetadata;
  [self updateStatsFromDevice];
}

#pragma - GCKMediaControlChannelDelegate methods

- (void)mediaControlChannel:(GCKMediaControlChannel *)mediaControlChannel
    didCompleteLoadWithSessionID:(NSInteger)sessionID {
  _mediaControlChannel = mediaControlChannel;
}

- (void)mediaControlChannelDidUpdateStatus:
            (GCKMediaControlChannel *)mediaControlChannel {
  NSLog(@"Media control channel status changed");
  _mediaControlChannel = mediaControlChannel;
  [self updateStatsFromDevice];
}

- (void)mediaControlChannelDidUpdateMetadata:
            (GCKMediaControlChannel *)mediaControlChannel {
  NSLog(@"Media control channel metadata changed");
  _mediaControlChannel = mediaControlChannel;
  [self updateStatsFromDevice];
}

@end
