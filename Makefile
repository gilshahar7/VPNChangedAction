ARCHS = arm64 armv7
include $(THEOS)/makefiles/common.mk

TWEAK_NAME = VPNChangedAction
VPNChangedAction_FILES = Tweak.xm
VPNChangedAction_LIBRARIES = activator

include $(THEOS_MAKE_PATH)/tweak.mk

after-install::
	install.exec "killall -9 SpringBoard"
