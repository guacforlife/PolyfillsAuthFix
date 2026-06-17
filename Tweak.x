// PolyfillsAuthFix — keep PoomSmart's Polyfills from breaking web authentication.
//
// Polyfills (com.ps.polyfills) reads its settings from the com.apple.UIKit
// preferences domain. Its "Header Injection" feature (active on iOS 11.0–16.3)
// registers a custom WKURLSchemeHandler for http/https that proxies ALL web
// traffic through NSURLSession. That re-routing breaks sites with strict
// authentication — most visibly new Google account sign-in in Safari and in the
// in-app (SafariViewService) web view, which fail with "something went wrong".
//
// This tweak forces PolyfillsHeaderInjectionEnabled = NO in com.apple.UIKit so
// the scheme handler never installs, while leaving every JavaScript polyfill
// fully active. Two independent layers, so it works regardless of tweak load order:
//   1. Hook the preference reads and return NO for that exact key + domain.
//   2. Persist the value to NO at load (SpringBoard sets it before Safari starts).
// Harmless if Polyfills is not installed (nothing reads the key).

#import <CoreFoundation/CoreFoundation.h>

static CFStringRef const kPFDomain = CFSTR("com.apple.UIKit");
static CFStringRef const kPFHeaderKey = CFSTR("PolyfillsHeaderInjectionEnabled");

static inline BOOL PFIsHeaderInjectionPref(CFStringRef key, CFStringRef applicationID) {
    return key && applicationID
        && CFStringCompare(key, kPFHeaderKey, 0) == kCFCompareEqualTo
        && CFStringCompare(applicationID, kPFDomain, 0) == kCFCompareEqualTo;
}

// Polyfills' ModHeader reads via CFPreferencesGetAppBooleanValue(headerInjectionKey, domain, &exists)
%hookf(Boolean, CFPreferencesGetAppBooleanValue, CFStringRef key, CFStringRef applicationID, Boolean *keyExistsAndHasValidFormat) {
    if (PFIsHeaderInjectionPref(key, applicationID)) {
        if (keyExistsAndHasValidFormat) *keyExistsAndHasValidFormat = true;
        return false;
    }
    return %orig;
}

// Safety net for any code path that reads the value object instead of the boolean
%hookf(CFPropertyListRef, CFPreferencesCopyAppValue, CFStringRef key, CFStringRef applicationID) {
    if (PFIsHeaderInjectionPref(key, applicationID)) {
        return (CFPropertyListRef)CFRetain(kCFBooleanFalse);
    }
    return %orig;
}

%ctor {
    // Persist the stored value off as well; in SpringBoard this runs before Safari ever launches.
    CFPreferencesSetAppValue(kPFHeaderKey, kCFBooleanFalse, kPFDomain);
    CFPreferencesAppSynchronize(kPFDomain);
}
