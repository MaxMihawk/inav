###############################################################
#
# Installers for tools
#
# NOTE: These are not tied to the default goals
#       and must be invoked manually
#
###############################################################

GCC_REQUIRED_VERSION ?= 9.2.1
ARM_SDK_DIR ?= $(TOOLS_DIR)/gcc-arm-none-eabi-9-2019-q4-major
ARM_SDK_URL_BASE  := https://armkeil.blob.core.windows.net/developer/Files/downloads/gnu-rm/9-2019q4/gcc-arm-none-eabi-9-2019-q4-major

.PHONY: arm_sdk_version

arm_sdk_version:
	$(V1) $(ARM_SDK_PREFIX)gcc --version

.PHONY: arm_sdk_install

# source: https://developer.arm.com/open-source/gnu-toolchain/gnu-rm/downloads
ifdef LINUX
  ARM_SDK_URL  := $(ARM_SDK_URL_BASE)-x86_64-linux.tar.bz2
endif

ifdef MACOSX
  ARM_SDK_URL  := $(ARM_SDK_URL_BASE)-mac.tar.bz2
endif

ifdef WINDOWS
  ARM_SDK_URL  := $(ARM_SDK_URL_BASE)-win32.zip
endif

ARM_SDK_FILE := $(notdir $(ARM_SDK_URL))
ARM_SDK_DOWNLOAD_PATH := $(DL_DIR)/$(ARM_SDK_FILE)

SDK_INSTALL_MARKER := $(ARM_SDK_DIR)/bin/arm-none-eabi-gcc-$(GCC_REQUIRED_VERSION)

.PHONY: arm_sdk_print_filename

arm_sdk_print_filename:
	@echo $(ARM_SDK_FILE)

.PHONY: arm_sdk_print_download_path

arm_sdk_print_download_path:
	@echo $(ARM_SDK_DOWNLOAD_PATH)

arm_sdk_install: | $(TOOLS_DIR)

arm_sdk_install: arm_sdk_download $(SDK_INSTALL_MARKER)

$(SDK_INSTALL_MARKER):
ifneq ($(OSFAMILY), windows)
    # binary only release so just extract it
	$(V1) tar -C $(TOOLS_DIR) -xjf "$(ARM_SDK_DOWNLOAD_PATH)"
else
	$(V1) unzip -q -d $(ARM_SDK_DIR) "$(ARM_SDK_DOWNLOAD_PATH)"
endif

.PHONY: arm_sdk_download
arm_sdk_download: | $(DL_DIR)
arm_sdk_download: $(ARM_SDK_DOWNLOAD_PATH)
$(ARM_SDK_DOWNLOAD_PATH):
    # download the source only if it's newer than what we already have
	$(V1) curl -L -k -o "$(ARM_SDK_DOWNLOAD_PATH)" -z "$(ARM_SDK_DOWNLOAD_PATH)" "$(ARM_SDK_URL)"


## arm_sdk_clean     : Uninstall Arm SDK
.PHONY: arm_sdk_clean
arm_sdk_clean:
	$(V1) [ ! -d "$(ARM_SDK_DIR)" ] || $(RM) -r $(ARM_SDK_DIR)
	$(V1) [ ! -d "$(DL_DIR)" ] || $(RM) -r $(DL_DIR)

##############################
#
# Set up paths to tools
#
##############################

ifeq ($(shell [ -d "$(ARM_SDK_DIR)" ] && echo "exists"), exists)
  ARM_SDK_PREFIX := $(ARM_SDK_DIR)/bin/arm-none-eabi-
else ifeq (,$(findstring print_,$(MAKECMDGOALS))$(filter targets,$(MAKECMDGOALS))$(findstring arm_sdk,$(MAKECMDGOALS)))
  GCC_VERSION = $(shell arm-none-eabi-gcc -dumpversion)
  ifeq ($(GCC_VERSION),)
    $(error **ERROR** arm-none-eabi-gcc not in the PATH. Run 'make arm_sdk_install' to install automatically in the tools folder of this repo)
  else ifneq ($(GCC_VERSION), $(GCC_REQUIRED_VERSION))
    $(error **ERROR** your arm-none-eabi-gcc is '$(GCC_VERSION)', but '$(GCC_REQUIRED_VERSION)' is expected. Override with 'GCC_REQUIRED_VERSION' in make/local.mk or run 'make arm_sdk_install' to install the right version automatically in the tools folder of this repo)
  endif

  # ARM tookchain is in the path, and the version is what's required.
  ARM_SDK_PREFIX ?= arm-none-eabi-
endif
