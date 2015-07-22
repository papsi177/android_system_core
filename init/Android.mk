# Copyright 2005 The Android Open Source Project

LOCAL_PATH:= $(call my-dir)
include $(CLEAR_VARS)

LOCAL_SRC_FILES:= \
	builtins.c \
	init.c \
	devices.c \
	property_service.c \
	util.c \
	parser.c \
	keychords.c \
	signal_handler.c \
	init_parser.c \
	ueventd.c \
	ueventd_parser.c \
	watchdogd.c \
	vendor_init.c

LOCAL_CFLAGS    += -Wno-unused-parameter

ifeq ($(strip $(INIT_BOOTCHART)),true)
LOCAL_SRC_FILES += bootchart.c
LOCAL_CFLAGS    += -DBOOTCHART=1
endif

ifneq (,$(filter userdebug eng,$(TARGET_BUILD_VARIANT)))
LOCAL_CFLAGS += -DALLOW_LOCAL_PROP_OVERRIDE=1 -DALLOW_DISABLE_SELINUX=1
endif

# Enable ueventd logging
#LOCAL_CFLAGS += -DLOG_UEVENTS=1

SYSTEM_CORE_INIT_DEFINES := BOARD_CHARGING_MODE_BOOTING_LPM \
    BOARD_CHARGING_CMDLINE_NAME \
    BOARD_CHARGING_CMDLINE_VALUE

$(foreach system_core_init_define,$(SYSTEM_CORE_INIT_DEFINES), \
  $(if $($(system_core_init_define)), \
    $(eval LOCAL_CFLAGS += -D$(system_core_init_define)=\"$($(system_core_init_define))\") \
  ) \
)

ifneq ($(TARGET_NR_SVC_SUPP_GIDS),)
LOCAL_CFLAGS += -DNR_SVC_SUPP_GIDS=$(TARGET_NR_SVC_SUPP_GIDS)
endif

ifneq ($(TARGET_IGNORE_RO_BOOT_SERIALNO),)
LOCAL_CFLAGS += -DIGNORE_RO_BOOT_SERIALNO
endif

LOCAL_MODULE:= init

LOCAL_FORCE_STATIC_EXECUTABLE := true
LOCAL_MODULE_PATH := $(TARGET_ROOT_OUT)
LOCAL_UNSTRIPPED_PATH := $(TARGET_ROOT_OUT_UNSTRIPPED)

LOCAL_STATIC_LIBRARIES := \
	libfs_mgr \
	liblogwrap \
	libcutils \
	liblog \
	libc \
	libselinux \
	libmincrypt \
	libext4_utils_static \
	libext2_uuid_static \
	liblz4-static \
	libsparse_static \
	libz \
	libext2_blkid \
	libext2_uuid_static

LOCAL_ADDITIONAL_DEPENDENCIES += $(LOCAL_PATH)/Android.mk
ifneq ($(strip $(TARGET_PLATFORM_DEVICE_BASE)),)
LOCAL_CFLAGS += -D_PLATFORM_BASE="\"$(TARGET_PLATFORM_DEVICE_BASE)\""
endif
ifneq ($(strip $(TARGET_INIT_VENDOR_LIB)),)
LOCAL_WHOLE_STATIC_LIBRARIES += $(TARGET_INIT_VENDOR_LIB)
endif
ifneq ($(strip $(TARGET_PROP_PATH_FACTORY)),)
LOCAL_CFLAGS += -DOVERRIDE_PROP_PATH_FACTORY=\"$(TARGET_PROP_PATH_FACTORY)\"
endif

include $(BUILD_EXECUTABLE)

# Make a symlink from /sbin/ueventd and /sbin/watchdogd to /init
SYMLINKS := \
	$(TARGET_ROOT_OUT)/sbin/ueventd \
	$(TARGET_ROOT_OUT)/sbin/watchdogd

$(SYMLINKS): INIT_BINARY := $(LOCAL_MODULE)
$(SYMLINKS): $(LOCAL_INSTALLED_MODULE) $(LOCAL_PATH)/Android.mk
	@echo "Symlink: $@ -> ../$(INIT_BINARY)"
	@mkdir -p $(dir $@)
	@rm -rf $@
	$(hide) ln -sf ../$(INIT_BINARY) $@

ALL_DEFAULT_INSTALLED_MODULES += $(SYMLINKS)

# We need this so that the installed files could be picked up based on the
# local module name
ALL_MODULES.$(LOCAL_MODULE).INSTALLED := \
    $(ALL_MODULES.$(LOCAL_MODULE).INSTALLED) $(SYMLINKS)
