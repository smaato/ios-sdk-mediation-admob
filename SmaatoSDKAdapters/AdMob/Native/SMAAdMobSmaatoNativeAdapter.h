//
//  SMAAdMobSmaatoNativeAdapter.h
//  SmaatoSDKMopubBannerAdapter
//
//  Created by Smaato Inc on 06.02.20.
//  Copyright © 2020 Smaato Inc. All rights reserved.￼
//  Licensed under the Smaato SDK License Agreement￼
//  https://www.smaato.com/sdk-license-agreement/
//

#import <Foundation/Foundation.h>
#import <GoogleMobileAds/GoogleMobileAds.h>

@interface SMAAdMobSmaatoNativeAdapter : NSObject <GADCustomEventNativeAd>
@property (class, nonatomic, readonly) NSString *version;
@end
