empty :=
space := $(empty) $(empty)

export TARGET_ROOT := $(abspath $(dir $(lastword $(MAKEFILE_LIST))))

include ../../../init.mk

ifndef P4FACTORY
P4FACTORY := $(TARGET_ROOT)/../../..
endif
MAKEFILES_DIR := ${P4FACTORY}/makefiles

# This target's P4 name
export P4_INPUT := ../p4src/uixp.p4
export P4_NAME := uixp
export P4_PREFIX := uixp

include $(MAKEFILES_DIR)/bmv2_common.mk

clean-local:

