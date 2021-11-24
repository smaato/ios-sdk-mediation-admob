//
//  SMAAdMobSmaatoInterstitialAdapter.m
//  SmaatoSDKAdapters
//
//  Created by Smaato Inc on 26.11.18.
//  Copyright © 2018 Smaato Inc. All rights reserved.￼
//  Licensed under the Smaato SDK License Agreement￼
//  https://www.smaato.com/sdk-license-agreement/
//

#import <GoogleMobileAds/GoogleMobileAds.h>
#import <SmaatoSDKInterstitial/SmaatoSDKInterstitial.h>
#import "SMAAdMobSmaatoInterstitialAdapter.h"

static NSString *const kSMAAdMobCustomEventInfoPublisherIdKey = @"publisherId";
static NSString *const kSMAAdMobCustomEventInfoAdSpaceIdKey = @"adspaceId";
static NSString *const kSMAAdMobSmaatoInterstitialAdapterVersion = @"8.13.0.0";

@interface SMAAdMobSmaatoInterstitialAdapter () <SMAInterstitialDelegate, GADCustomEventInterstitial>
@property (nonatomic) SMAInterstitial *interstitial;
@end

@implementation SMAAdMobSmaatoInterstitialAdapter
@synthesize delegate;

+ (NSString *)version
{
    return kSMAAdMobSmaatoInterstitialAdapterVersion;
}

- (void)requestInterstitialAdWithParameter:(NSString *)serverParameter
                                     label:(NSString *)serverLabel
                                   request:(GADCustomEventRequest *)request
{
    // Extract key-value pairs from passed server parameter string
    NSDictionary *info = [self dictionaryFromServerParameter:serverParameter];

    // Extract ad space information
    NSString *adSpaceId = [self fetchValueForKey:kSMAAdMobCustomEventInfoAdSpaceIdKey fromEventInfo:info];

    // Verify ad space information
    if (![self checkCredentialsWithAdSpaceId:adSpaceId]) {
        return;
    }

    // Pass user location
    if (request.userHasLocation) {
        SMALocation *userLocation = [[SMALocation alloc] initWithLatitude:request.userLatitude
                                                                longitude:request.userLongitude
                                                       horizontalAccuracy:request.userLocationAccuracyInMeters
                                                                timestamp:[NSDate date]];
        SmaatoSDK.userLocation = userLocation;
    }

    // OPTIONAL: Pass mediation information
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
    adRequestParams.mediationAdapterVersion = kSMAAdMobSmaatoInterstitialAdapterVersion;
    adRequestParams.mediationNetworkSDKVersion = [NSString stringWithFormat:@"%s", GoogleMobileAdsVersionString];

    // Load ad
    [SmaatoSDK loadInterstitialForAdSpaceId:adSpaceId delegate:self requestParams:adRequestParams];
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

    if ([self.delegate respondsToSelector:@selector(customEventInterstitial:didFailAd:)]) {
        NSDictionary *userInfo = @{ NSLocalizedDescriptionKey : errorMessage };
        NSError *error = [NSError errorWithDomain:[self smaatoMediationNetworkName] code:kSMAErrorCodeInvalidRequest userInfo:userInfo];

        [self.delegate customEventInterstitial:self didFailAd:error];
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

- (void)presentFromRootViewController:(UIViewController *)rootViewController
{
    if (self.interstitial.availableForPresentation) {
        [self.interstitial showFromViewController:rootViewController];
    }
}

#pragma mark - SMAInterstitialDelegate

- (void)interstitialDidLoad:(SMAInterstitial *)interstitial
{
    self.interstitial = interstitial;
    if ([self.delegate respondsToSelector:@selector(customEventInterstitialDidReceiveAd:)]) {
        [self.delegate customEventInterstitialDidReceiveAd:self];
    }
}

- (void)interstitial:(SMAInterstitial *)interstitial didFailWithError:(NSError *)error
{
    if ([self.delegate respondsToSelector:@selector(customEventInterstitial:didFailAd:)]) {
        [self.delegate customEventInterstitial:self didFailAd:error];
    }
}

- (void)interstitialDidTTLExpire:(SMAInterstitial *)interstitial
{
    // No corresponding method from AdMob SDK available.
}

- (void)interstitialWillAppear:(SMAInterstitial *)interstitial
{
    if ([self.delegate respondsToSelector:@selector(customEventInterstitialWillPresent:)]) {
        [self.delegate customEventInterstitialWillPresent:self];
    }
}

- (void)interstitialWillDisappear:(SMAInterstitial *)interstitial
{
    if ([self.delegate respondsToSelector:@selector(customEventInterstitialWillDismiss:)]) {
        [self.delegate customEventInterstitialWillDismiss:self];
    }
}

- (void)interstitialDidDisappear:(SMAInterstitial *)interstitial
{
    if ([self.delegate respondsToSelector:@selector(customEventInterstitialDidDismiss:)]) {
        [self.delegate customEventInterstitialDidDismiss:self];
    }
}

- (void)interstitialDidClick:(SMAInterstitial *)interstitial
{
    if ([self.delegate respondsToSelector:@selector(customEventInterstitialWasClicked:)]) {
        [self.delegate customEventInterstitialWasClicked:self];
    }
}

- (void)interstitialWillLeaveApplication:(SMAInterstitial *)interstitial
{
    if ([self.delegate respondsToSelector:@selector(customEventInterstitialWillLeaveApplication:)]) {
        [self.delegate customEventInterstitialWillLeaveApplication:self];
    }
}

@end
