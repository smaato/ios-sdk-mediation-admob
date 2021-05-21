//
//  SMAAdMobSmaatoMediatedNativeAd.m
//  SmaatoSDKMopubBannerAdapter
//
//  Created by Smaato on 06.02.20.
//  Copyright © 2020 Smaato Inc. All rights reserved.￼
//  Licensed under the Smaato SDK License Agreement￼
//  https://www.smaato.com/sdk-license-agreement/
//

#import "SMAAdMobSmaatoMediatedNativeAd.h"

@interface SMAAdMobSmaatoMediatedNativeAd ()

@property (nonatomic) SMANativeAd *nativeAd;
@property (nonatomic) SMANativeAdRenderer *adRenderer;
@property (nonatomic, copy) NSArray<GADNativeAdImage *> *mainImages;
@property (nonatomic) GADNativeAdImage *iconImage;
@property (nonatomic) NSDecimalNumber *starRating;
@property (nonatomic, weak) UIViewController *presentingViewController;

@end

@implementation SMAAdMobSmaatoMediatedNativeAd

- (nonnull instancetype)initWithNativeAd:(SMANativeAd *)nativeAd
                              adRenderer:(SMANativeAdRenderer *)adRenderer
                           andMainImages:(NSArray<GADNativeAdImage *> *)mainImages
                            andIconImage:(GADNativeAdImage *)iconImage
{
    self = [super init];

    if (self) {
        self.nativeAd = nativeAd;
        self.adRenderer = adRenderer;
        self.mainImages = mainImages;
        self.iconImage = iconImage;
        self.starRating = [[NSDecimalNumber alloc] initWithDouble:self.adRenderer.nativeAssets.rating];
    }

    return self;
}

#pragma mark - Assets

- (NSString *)headline
{
    return self.adRenderer.nativeAssets.title;
}

- (NSString *)body
{
    return self.adRenderer.nativeAssets.mainText;
}

- (GADNativeAdImage *)icon
{
    return self.iconImage;
}

- (NSArray<GADNativeAdImage *> *)images
{
    return self.mainImages.count > 0 ? self.mainImages : nil;
}

- (NSString *)callToAction
{
    return self.adRenderer.nativeAssets.cta;
}

- (NSDecimalNumber *)starRating
{
    return self.starRating;
}

- (NSString *)price
{
    return nil;
}

- (NSString *)store
{
    return nil;
}

- (NSDictionary<NSString *, id> *)extraAssets
{
    return nil;
}

- (NSString *)advertiser
{
    return nil;
}

- (UIView *)adChoicesView
{
    return self.adRenderer.privacyView;
}

#pragma mark - <GADMediatedUnifiedNativeAd> Callbacks

- (void)didRenderInView:(UIView *)view
       clickableAssetViews:(NSDictionary<GADNativeAssetIdentifier, UIView *> *)clickableAssetViews
    nonclickableAssetViews:(NSDictionary<GADNativeAssetIdentifier, UIView *> *)nonclickableAssetViews
            viewController:(UIViewController *)viewController
{
    [self.adRenderer registerViewForImpression:view];
    [self.adRenderer registerViewsForClickAction:clickableAssetViews.allValues];
    self.presentingViewController = viewController;
}

- (void)didRecordClickOnAssetWithName:(GADNativeAssetIdentifier)assetName
                                 view:(UIView *)view
                       viewController:(UIViewController *)viewController
{
    // Method is not applicable because Smaato SDK handles click itself
}

- (void)didRecordImpression
{
    // Method is not applicable because Smaato SDK tracks impression itself
}

#pragma mark - <SMANativeAdDelegate> methods

- (void)nativeAd:(SMANativeAd *)nativeAd didLoadWithAdRenderer:(SMANativeAdRenderer *)renderer
{
    // Method should be called before SMAAdMobSmaatoMediatedNativeAd instance creating
}

- (void)nativeAd:(SMANativeAd *)nativeAd didFailWithError:(NSError *)error
{
    // Method should be called instead of SMAAdMobSmaatoMediatedNativeAd instance creating
}

- (void)nativeAdDidTTLExpire:(SMANativeAd *)nativeAd
{
    // No corresponding delegate method from MoPub SDK available.
}

- (void)nativeAdDidClick:(SMANativeAd *)nativeAd
{
    [GADMediatedUnifiedNativeAdNotificationSource mediatedNativeAdDidRecordClick:self];
}

- (void)nativeAdDidImpress:(SMANativeAd *)nativeAd
{
    [GADMediatedUnifiedNativeAdNotificationSource mediatedNativeAdDidRecordImpression:self];
}

- (void)nativeAdWillPresentModalContent:(SMANativeAd *)nativeAd
{
    [GADMediatedUnifiedNativeAdNotificationSource mediatedNativeAdWillPresentScreen:self];
}

- (void)nativeAdDidPresentModalContent:(SMANativeAd *)nativeAd
{
    // No corresponding delegate method from AdMob SDK available.
}

- (void)nativeAdDidDismissModalContent:(SMANativeAd *)nativeAd
{
    [GADMediatedUnifiedNativeAdNotificationSource mediatedNativeAdWillDismissScreen:self];
    [GADMediatedUnifiedNativeAdNotificationSource mediatedNativeAdDidDismissScreen:self];
}

- (void)nativeAdWillLeaveApplicationFromAd:(SMANativeAd *)nativeAd
{
    [GADMediatedUnifiedNativeAdNotificationSource mediatedNativeAdWillLeaveApplication:self];
}

- (UIViewController *)presentingViewControllerForNativeAd:(SMANativeAd *)nativeAd
{
    return self.presentingViewController;
}

@end
