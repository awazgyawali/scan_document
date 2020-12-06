#import "ScanDocumentPlugin.h"
#if __has_include(<scan_document/scan_document-Swift.h>)
#import <scan_document/scan_document-Swift.h>
#else
// Support project import fallback if the generated compatibility header
// is not copied when this plugin is created as a library.
// https://forums.swift.org/t/swift-static-libraries-dont-copy-generated-objective-c-header/19816
#import "scan_document-Swift.h"
#endif

@implementation ScanDocumentPlugin
+ (void)registerWithRegistrar:(NSObject<FlutterPluginRegistrar>*)registrar {
  [SwiftScanDocumentPlugin registerWithRegistrar:registrar];
}
@end
