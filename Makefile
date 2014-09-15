ARCHS = armv7 armv7s arm64
TARGET = iphone:clang:latest:7.0

THEOS_BUILD_DIR = Packages

TWEAK_NAME = LongTouchHome
LongTouchHome_FILES = Event.xm
LongTouchHome_LIBRARIES = activator
LongTouchHome_PRIVATE_FRAMEWORKS = SpringBoardUIServices

#ADDITIONAL_CFLAGS = -std=c99

include theos/makefiles/common.mk
include $(THEOS_MAKE_PATH)/tweak.mk

internal-stage::
	#PreferenceLoader plist
	$(ECHO_NOTHING)mkdir -p $(THEOS_STAGING_DIR)/Library/PreferenceLoader/Preferences$(ECHO_END)
	$(ECHO_NOTHING)cp Preferences.plist $(THEOS_STAGING_DIR)/Library/PreferenceLoader/Preferences/LongTouchHome.plist$(ECHO_END)

after-install::
	install.exec "killall -9 SpringBoard"
