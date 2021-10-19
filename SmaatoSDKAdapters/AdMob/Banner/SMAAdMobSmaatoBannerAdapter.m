//
//  SMAAdMobSmaatoBannerAdapter.m
//  SmaatoSDKAdapters
//
//  Created by Smaato Inc on 20.11.18.
//  Copyright © 2018 Smaato Inc. All rights reserved.￼
//  Licensed under the Smaato SDK License Agreement￼
//  https://www.smaato.com/sdk-license-agreement/
//

#import <GoogleMobileAds/GoogleMobileAds.h>
#import <SmaatoSDKBanner/SmaatoSDKBanner.h>
#import "SMAAdMobSmaatoBannerAdapter.h"

static NSString *const kSMAAdMobCustomEventInfoAdSpaceIdKey = @"adspaceId";
static NSString *const kSMAAdMobBannerAdapterVersion = @"8.11.0.0";

@interface SMAAdMobSmaatoBannerAdapter () <GADCustomEventBanner, SMABannerViewDelegate>
@property (nonatomic) SMABannerView *bannerView;
@end

@implementation SMAAdMobSmaatoBannerAdapter

@synthesize delegate;

+ (NSString *)version
{
    return kSMAAdMobBannerAdapterVersion;
}

- (void)requestBannerAd:(GADAdSize)adSize
              parameter:(NSString *)serverParameter
                  label:(NSString *)serverLabel
                request:(GADCustomEventRequest *)request
{
    // Convert ad size format
    SMABannerAdSize convertedAdSize = [self SMABannerAdSizeFromRequestedSize:adSize];

    // Extract key-value pairs from passed server parameter string
    NSDictionary *info = [self dictionaryFromServerParameter:serverParameter];

    // Extract ad space information
    NSString *adSpaceId = [self fetchValueForKey:kSMAAdMobCustomEventInfoAdSpaceIdKey fromEventInfo:info];

    // Verify ad space information
    if (![self checkCredentialsWithAdSpaceId:adSpaceId]) {
        return;
    }

    // Create and configure ad view object
    self.bannerView = [[SMABannerView alloc] initWithFrame:CGRectMake(0.0f, 0.0f, adSize.size.width, adSize.size.height)];
    self.bannerView.delegate = self;
    self.bannerView.autoreloadInterval = kSMABannerAutoreloadIntervalDisabled;

    // Pass user location
    if (request.userHasLocation) {
        SMALocation *userLocation = [[SMALocation alloc] initWithLatitude:request.userLatitude
                                                                longitude:request.userLongitude
                                                       horizontalAccuracy:request.userLocationAccuracyInMeters
                                                                timestamp:[NSDate date]];
        SmaatoSDK.userLocation = userLocation;
    }

    /**
     Optional: You can also set specific user profile targeting parameters here.
     Please check the Smaato wiki for all available properties and further details.

     Examples:
     SmaatoSDK.userAge = 30;
     SmaatoSDK.userGender = kSMAGenderMale;
    */

    // Passing mediation information
    SMAAdRequestParams *adRequestParams = [SMAAdRequestParams new];
    adRequestParams.mediationNetworkName = [self smaatoMediationNetworkName];
    adRequestParams.mediationAdapterVersion = kSMAAdMobBannerAdapterVersion;
    adRequestParams.mediationNetworkSDKVersion = [NSString stringWithFormat:@"%s", GoogleMobileAdsVersionString];

    // Load ad
    [self.bannerView loadWithAdSpaceId:adSpaceId adSize:convertedAdSize requestParams:adRequestParams];
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

        [self.delegate customEventBanner:self didFailAd:error];
    }

    return NO;
}

- (SMABannerAdSize)SMABannerAdSizeFromRequestedSize:(GADAdSize)requestedSize
{
    CGSize requestAdSize = requestedSize.size;

    if ((int)(requestAdSize.height) >= 600 && (int)(requestAdSize.width) >= 120) {
        return kSMABannerAdSizeSkyscraper_120x600;
    } else if ((int)(requestAdSize.height) >= 250 && (int)(requestAdSize.width) >= 300) {
        return kSMABannerAdSizeMediumRectangle_300x250;
    } else if ((int)(requestAdSize.height) >= 90 && (int)(requestAdSize.width) >= 728) {
        return kSMABannerAdSizeLeaderboard_728x90;
    } else {
        return kSMABannerAdSizeXXLarge_320x50;
    }
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

#pragma mark - SMABannerViewDelegate

- (UIViewController *)presentingViewControllerForBannerView:(SMABannerView *)bannerView
{
    return (UIViewController *)self.delegate.viewControllerForPresentingModalView;
}

- (void)bannerViewDidLoad:(SMABannerView *)bannerView
{
    if ([self.delegate respondsToSelector:@selector(customEventBanner:didReceiveAd:)]) {
        [self.delegate customEventBanner:self didReceiveAd:bannerView];
    }
}

- (void)bannerViewDidClick:(SMABannerView *)bannerView
{
    if ([self.delegate respondsToSelector:@selector(customEventBannerWasClicked:)]) {
        [self.delegate customEventBannerWasClicked:self];
    }
}

- (void)bannerView:(SMABannerView *)bannerView didFailWithError:(NSError *)error
{
    if ([self.delegate respondsToSelector:@selector(customEventBanner:didFailAd:)]) {
        [self.delegate customEventBanner:self didFailAd:error];
    }
}

- (void)bannerViewWillPresentModalContent:(SMABannerView *)bannerView
{
    if ([self.delegate respondsToSelector:@selector(customEventBannerWillPresentModal:)]) {
        [self.delegate customEventBannerWillPresentModal:self];
    }
}

- (void)bannerViewDidPresentModalContent:(SMABannerView *)bannerView
{
    // No corresponding method from AdMob SDK available.
}

- (void)bannerViewDidDismissModalContent:(SMABannerView *)bannerView
{
    if ([self.delegate respondsToSelector:@selector(customEventBannerDidDismissModal:)]) {
        [self.delegate customEventBannerDidDismissModal:self];
    }
}

- (void)bannerWillLeaveApplicationFromAd:(SMABannerView *)bannerView
{
    if ([self.delegate respondsToSelector:@selector(customEventBannerWillLeaveApplication:)]) {
        [self.delegate customEventBannerWillLeaveApplication:self];
    }
}

- (void)bannerViewDidTTLExpire:(SMABannerView *)bannerView
{
    if ([self.delegate respondsToSelector:@selector(customEventBanner:didFailAd:)]) {
        NSString *errorMessage = @"Banner TTL has expired.";
        NSDictionary *userInfo = @{ NSLocalizedDescriptionKey : errorMessage };
        NSError *error = [NSError errorWithDomain:[self smaatoMediationNetworkName] code:kSMAErrorCodeNoAdAvailable userInfo:userInfo];

        [self.delegate customEventBanner:self didFailAd:error];
    }
}

@end
