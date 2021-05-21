//
//  SMAAdMobSmaatoMediatedNativeAd.h
//  SmaatoSDKMopubBannerAdapter
//
//  Created by Smaato Inc on 06.02.20.
//  Copyright © 2020 Smaato Inc. All rights reserved.￼
//  Licensed under the Smaato SDK License Agreement￼
//  https://www.smaato.com/sdk-license-agreement/
//

#import <Foundation/Foundation.h>
#import <GoogleMobileAds/GoogleMobileAds.h>
#import <SmaatoSDKNative/SmaatoSDKNative.h>

@interface SMAAdMobSmaatoMediatedNativeAd : NSObject <GADMediatedUnifiedNativeAd, SMANativeAdDelegate>

/**
Unavailable.
Use \c initWithNativeAd: to create instances of \c SMAAdMobSmaatoMediatedNativeAd class.
*/
- (nonnull instancetype)init NS_UNAVAILABLE;

/**
Designated initializer. Creates instance of \c SMAAdMobSmaatoMediatedNativeAd
class with the provided \c SMANativeAdAssets .

@param nativeAd The native ad renderer object that should be retained if there is an intention to receive the
                callbacks about ad life cycle
@param adRenderer The native ad renderer object
@param mainImages An array of \c GADNativeAdImage objects that represent main image creatives of native ad
@param iconImage  \c GADNativeAdImage object that represents icon image creatives of native ad
@return The initialized \c SMAAdMobSmaatoMediatedNativeAd
*/
- (nonnull instancetype)initWithNativeAd:(SMANativeAd *_Nonnull)nativeAd
                              adRenderer:(SMANativeAdRenderer *_Nonnull)adRenderer
                           andMainImages:(NSArray<GADNativeAdImage *> *_Nullable)mainImages
                            andIconImage:(GADNativeAdImage *_Nullable)iconImage NS_DESIGNATED_INITIALIZER;

@end
