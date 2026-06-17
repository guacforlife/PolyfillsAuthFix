TARGET = iphone:clang:14.5:14.0
ARCHS = arm64 arm64e
THEOS_PACKAGE_SCHEME = rootless

TWEAK_NAME = PolyfillsAuthFix

PolyfillsAuthFix_FILES = Tweak.x
PolyfillsAuthFix_CFLAGS = -fobjc-arc
PolyfillsAuthFix_FRAMEWORKS = CoreFoundation

include $(THEOS)/makefiles/common.mk
include $(THEOS_MAKE_PATH)/tweak.mk
