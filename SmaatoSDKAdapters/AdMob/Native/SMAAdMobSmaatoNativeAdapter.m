//
//  SMAAdMobSmaatoNativeAdapter.m
//  SmaatoSDKAdapters
//
//  Created by Smaato Inc on 06.02.20.
//  Copyright © 2020 Smaato Inc. All rights reserved.￼
//  Licensed under the Smaato SDK License Agreement￼
//  https://www.smaato.com/sdk-license-agreement/
//

#import <GoogleMobileAds/GoogleMobileAds.h>
#import <SmaatoSDKNative/SmaatoSDKNative.h>
#import "SMAAdMobSmaatoNativeAdapter.h"
#import "SMAAdMobSmaatoMediatedNativeAd.h"

static NSString *const kSMAAdMobCustomEventInfoAdSpaceIdKey = @"adspaceId";
static NSString *const kSMAAdMobNativeAdapterVersion = @"8.12.0.0";

typedef void (^SMASMAAdMobMediatedNativeAdDeferredCallback)(id<GADMediatedUnifiedNativeAd> mediatedAd);

@interface SMAAdMobSmaatoNativeAdapter () <GADCustomEventNativeAd, SMANativeAdDelegate>

@property (nonatomic) SMANativeAd *nativeAd;
@property (nonatomic, weak) UIViewController *presentingViewController;
@property (nonatomic) GADNativeAdImageAdLoaderOptions *imageLoaderOptions;
@property (nonatomic, copy) NSString *adSpaceId;
@property (nonatomic) NSMutableArray<SMASMAAdMobMediatedNativeAdDeferredCallback> *deferredCallbacks;

@end

@implementation SMAAdMobSmaatoNativeAdapter

@synthesize delegate;

+ (NSString *)version
{
    return kSMAAdMobNativeAdapterVersion;
}

- (NSString *)fetchValueForKey:(NSString *)definedKey fromEventInfo:(NSDictionary *)info
{
    __block NSString *value;
    [info enumerateKeysAndObjectsUsingBlock:^(NSString *_Nonnull key, id _Nonnull obj, BOOL *_Nonnull stop) {
        if ([definedKey caseInsensitiveCompare:key] == NSOrderedSame) {
            value = obj;
            *stop = YES;
        }
    }];
    return value;
}

- (BOOL)checkCredentialsWithAdSpaceId:(NSString *)adSpaceId
{
    if (adSpaceId) {
        return YES;
    }

    NSString *errorMessage = @"AdSpaceId can not be extracted. Please check your configuration on AdMob dashboard.";
    NSLog(@"[SmaatoSDK] [Error] %@: %@", [self smaatoMediationNetworkName], errorMessage);

    if ([self.delegate respondsToSelector:@selector(customEventBanner:didFailAd:)]) {
        NSDictionary *userInfo = @{ NSLocalizedDescriptionKey : errorMessage };
        NSError *error = [NSError errorWithDomain:[self smaatoMediationNetworkName] code:kSMAErrorCodeInvalidRequest userInfo:userInfo];

        [self.delegate customEventNativeAd:self didFailToLoadWithError:error];
    }

    return NO;
}

- (NSDictionary *)dictionaryFromServerParameter:(NSString *)serverParameter
{
    NSMutableDictionary *parsedServerParameters = [NSMutableDictionary new];
    [[serverParameter componentsSeparatedByString:@"&"]
        enumerateObjectsUsingBlock:^(NSString *_Nonnull obj, NSUInteger idx, BOOL *_Nonnull stop) {
            NSArray *pair = [obj componentsSeparatedByString:@"="];
            if (pair.count > 1) {
                id key = pair[0];
                id value = pair[1];
                parsedServerParameters[key] = value;
            }
        }];

    return [parsedServerParameters copy];
}

- (NSString *)smaatoMediationNetworkName
{
    return NSStringFromClass([self class]);
}

- (NSString *)getAdNetworkId
{
    return self.adSpaceId;
}

#pragma mark - GADCustomEventNativeAd

- (void)requestNativeAdWithParameter:(NSString *)serverParameter
                             request:(GADCustomEventRequest *)request
                             adTypes:(NSArray *)adTypes
                             options:(NSArray *)options
                  rootViewController:(UIViewController *)rootViewController
{
    self.deferredCallbacks = [NSMutableArray new];

    // Persisting instance of presenting view controller
    self.presentingViewController = rootViewController;

    // Extract key-value pairs from passed server parameter string
    NSDictionary *info = [self dictionaryFromServerParameter:serverParameter];

    self.adSpaceId = [self fetchValueForKey:kSMAAdMobCustomEventInfoAdSpaceIdKey fromEventInfo:info];

    // Verify ad space information
    if (![self checkCredentialsWithAdSpaceId:self.adSpaceId]) {
        return;
    }

    // Create and configure ad object
    self.nativeAd = [[SMANativeAd alloc] init];
    self.nativeAd.delegate = self;

    // Pass user location
    if (request.userHasLocation) {
        SMALocation *userLocation = [[SMALocation alloc] initWithLatitude:request.userLatitude
                                                                longitude:request.userLongitude
                                                       horizontalAccuracy:request.userLocationAccuracyInMeters
                                                                timestamp:[NSDate date]];
        SmaatoSDK.userLocation = userLocation;
    }

    /**
     Optional:
     You can also set specific user profile targeting parameters here.
     Please check the Smaato wiki for all available properties and further details.

     Examples:
     SmaatoSDK.userAge = 30;
     SmaatoSDK.userGender = kSMAGenderMale;
     */

    SMAAdRequestParams *adRequestParams = [SMAAdRequestParams new];

    // Passing mediation information
    adRequestParams.mediationNetworkName = [self smaatoMediationNetworkName];
    adRequestParams.mediationAdapterVersion = kSMAAdMobNativeAdapterVersion;
    adRequestParams.mediationNetworkSDKVersion = [NSString stringWithFormat:@"%s", GoogleMobileAdsVersionString];

    for (GADNativeAdImageAdLoaderOptions *imageOptions in options) {
        if (![imageOptions isKindOfClass:[GADNativeAdImageAdLoaderOptions class]]) {
            continue;
        }
        self.imageLoaderOptions = imageOptions;
    }

    SMANativeAdRequest *adRequest = [[SMANativeAdRequest alloc] initWithAdSpaceId:self.adSpaceId];
    adRequest.allowMultipleImages = self.imageLoaderOptions.shouldRequestMultipleImages;
    adRequest.returnUrlsForImageAssets = self.imageLoaderOptions.disableImageLoading;
    [self.nativeAd loadWithAdRequest:adRequest requestParams:adRequestParams];
}

- (BOOL)handlesUserClicks
{
    return YES;
}

- (BOOL)handlesUserImpressions
{
    return YES;
}

#pragma mark - SMANativeAdDelegate

- (void)nativeAd:(SMANativeAd *)nativeAd didLoadWithAdRenderer:(SMANativeAdRenderer *)renderer
{
    [self handleResponse:renderer];
}

- (void)nativeAd:(SMANativeAd *)nativeAd didFailWithError:(NSError *)error
{
    if ([self.delegate respondsToSelector:@selector(customEventNativeAd:didFailToLoadWithError:)]) {
        [self.delegate customEventNativeAd:self didFailToLoadWithError:error];
    }
}

- (void)nativeAdDidTTLExpire:(SMANativeAd *)nativeAd
{
    if ([self.delegate respondsToSelector:@selector(customEventNativeAd:didFailToLoadWithError:)]) {
        NSString *errorMessage = @"Native TTL has expired.";
        NSDictionary *userInfo = @{ NSLocalizedDescriptionKey : errorMessage };
        NSError *error = [NSError errorWithDomain:[self smaatoMediationNetworkName] code:kSMAErrorCodeNoAdAvailable userInfo:userInfo];

        [self.delegate customEventNativeAd:self didFailToLoadWithError:error];
    }
}

- (void)nativeAdDidImpress:(SMANativeAd *)nativeAd
{
    // This workaround helps to prevent ads impression analytics discrepancy issue between Smaato and Admob, because
    //\c nativeAdDidImpress: method might be called before \c nativeAd:didLoadWithAdRenderer: method will be
    // able to finish image creatives preloading (if needed) and create given \SMAAdMobSmaatoMediatedNativeAd
    // object and call \c customEventNativeAd:didReceiveMediatedUnifiedNativeAd: callback
    @synchronized(self.deferredCallbacks)
    {
        SMASMAAdMobMediatedNativeAdDeferredCallback callback = ^(id<GADMediatedUnifiedNativeAd> mediatedAd) {
            [GADMediatedUnifiedNativeAdNotificationSource mediatedNativeAdDidRecordImpression:mediatedAd];
        };
        [self.deferredCallbacks addObject:callback];
    }
}

- (UIViewController *)presentingViewControllerForNativeAd:(SMANativeAd *)nativeAd
{
    return self.presentingViewController;
}

#pragma mark - Private

- (void)handleResponse:(SMANativeAdRenderer *)renderer
{
    BOOL disableImageLoading = self.imageLoaderOptions.disableImageLoading;
    SMANativeAdAssets *assets = renderer.nativeAssets;
    CGFloat defaultImageScale = 1;

    GADNativeAdImage *iconImage = nil;
    if (disableImageLoading) {
        NSURL *iconURL = assets.icon.url;
        if (iconURL) {
            iconImage = [[GADNativeAdImage alloc] initWithURL:iconURL scale:defaultImageScale];
        }
    } else {
        UIImage *iconCreative = assets.icon.image;
        if (iconCreative) {
            iconImage = [[GADNativeAdImage alloc] initWithImage:iconCreative];
        }
    }

    NSMutableArray<GADNativeAdImage *> *mainImages = [NSMutableArray new];
    [assets.images enumerateObjectsUsingBlock:^(SMANativeImage *obj, NSUInteger idx, BOOL *stop) {
        GADNativeAdImage *image = nil;
        if (disableImageLoading) {
            NSURL *url = obj.url;
            if (url) {
                image = [[GADNativeAdImage alloc] initWithURL:url scale:defaultImageScale];
            }
        } else {
            UIImage *imageCreative = obj.image;
            if (imageCreative) {
                image = [[GADNativeAdImage alloc] initWithImage:imageCreative];
            }
        }
        if (image) {
            [mainImages addObject:image];
        }
    }];

    SMAAdMobSmaatoMediatedNativeAd *mediatedNativeAd = [[SMAAdMobSmaatoMediatedNativeAd alloc] initWithNativeAd:self.nativeAd
                                                                                                     adRenderer:renderer
                                                                                                  andMainImages:mainImages
                                                                                                   andIconImage:iconImage];

    if ([self.delegate respondsToSelector:@selector(customEventNativeAd:didReceiveMediatedUnifiedNativeAd:)]) {
        [self.delegate customEventNativeAd:self didReceiveMediatedUnifiedNativeAd:mediatedNativeAd];
    }

    self.nativeAd.delegate = mediatedNativeAd;
    [self callDeferredCallbacksWithMediatedNativeAd:mediatedNativeAd];
}

- (void)callDeferredCallbacksWithMediatedNativeAd:(id<GADMediatedUnifiedNativeAd>)mediatedAd
{
    @synchronized(self.deferredCallbacks)
    {
        if (mediatedAd) {
            for (SMASMAAdMobMediatedNativeAdDeferredCallback callback in self.deferredCallbacks) {
                callback(mediatedAd);
            }
            [self.deferredCallbacks removeAllObjects];
        }
    }
}

@end
