//
//  GMBChromecastManager.h
//  Obelisk
//
//  Created by Garret Buell on 6/16/14.
//
//

#import <Foundation/Foundation.h>
#import "GoogleCast/GoogleCast.h"
#import "GMBVideoItem.h"

@interface GMBChromecastManager
    : NSObject<GCKDeviceScannerListener, GCKDeviceManagerDelegate,
               GCKMediaControlChannelDelegate, UIActionSheetDelegate>

+ (GMBChromecastManager *)sharedManager;

- (void)startDeviceScan;
- (void)connectToDevice;
- (void)connectToDeviceAndPlay:(GMBVideoItem *)video;
- (BOOL)isConnected;
- (void)castVideo:(GMBVideoItem *)video;
- (void)stopPlayback;

@property GCKMediaControlChannel *mediaControlChannel;
@property GCKApplicationMetadata *applicationMetadata;
@property GCKDevice *selectedDevice;
@property(nonatomic, strong) GCKDeviceScanner *deviceScanner;
@property(nonatomic, strong) GCKDeviceManager *deviceManager;
@property(nonatomic, readonly) GCKMediaInformation *mediaInformation;

@end
