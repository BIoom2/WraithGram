#import <Foundation/Foundation.h>

@class MTSignal;
@class MTContext;

@interface MTBackupAddressSignals : NSObject

+ (MTSignal * _Nonnull)fetchBackupIps:(bool)isTestingEnvironment currentContext:(MTContext * _Nonnull)currentContext additionalSource:(MTSignal * _Nullable)additionalSource phoneNumber:(NSString * _Nullable)phoneNumber mainDatacenterId:(NSInteger)mainDatacenterId;

// WRAITH: process-wide switch for the DNS-over-HTTPS source (dns.google.com) of the backup address
// discovery. Set before the networks are created; thread-safe (atomic).
+ (void)setGoogleDnsDisabled:(bool)disabled;

@end
