//
//  Generated file. Do not edit.
//

#import "GeneratedPluginRegistrant.h"

#if __has_include(<get_ip/GetIpPlugin.h>)
#import <get_ip/GetIpPlugin.h>
#else
@import get_ip;
#endif

#if __has_include(<path_provider/FLTPathProviderPlugin.h>)
#import <path_provider/FLTPathProviderPlugin.h>
#else
@import path_provider;
#endif

#if __has_include(<sqflite/SqflitePlugin.h>)
#import <sqflite/SqflitePlugin.h>
#else
@import sqflite;
#endif

#if __has_include(<ssh/SshPlugin.h>)
#import <ssh/SshPlugin.h>
#else
@import ssh;
#endif

@implementation GeneratedPluginRegistrant

+ (void)registerWithRegistry:(NSObject<FlutterPluginRegistry>*)registry {
  [GetIpPlugin registerWithRegistrar:[registry registrarForPlugin:@"GetIpPlugin"]];
  [FLTPathProviderPlugin registerWithRegistrar:[registry registrarForPlugin:@"FLTPathProviderPlugin"]];
  [SqflitePlugin registerWithRegistrar:[registry registrarForPlugin:@"SqflitePlugin"]];
  [SshPlugin registerWithRegistrar:[registry registrarForPlugin:@"SshPlugin"]];
}

@end
