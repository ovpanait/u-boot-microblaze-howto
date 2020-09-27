SCRIPTS_DIR = $(realpath scripts)
SCRIPTS := $(shell find $(SCRIPTS_DIR))

PATCHES_DIR = $(realpath patches)
FSBL_PATCHES_DIR = $(PATCHES_DIR)/fsbl

# Script parameters
BIT_FILE ?= $(realpath system_top.bit)
HDF_FILE ?= $(realpath design.xsa)
UBOOT_FILE ?= $(realpath u-boot)
UBOOT_LOADADDR ?= 0x4000000

BUILD_DIR = build/
OUT_DIR = output/

GEN_SCRIPTS = $(OUT_DIR)/zynq.bif $(BUILD_DIR)/create_fsbl.tcl $(BUILD_DIR)/build_fsbl.tcl
FSBL_SRC = $(BUILD_DIR)/build/sdk/fsbl/src
FSBL_ELF = $(BUILD_DIR)/build/sdk/fsbl/Release/fsbl.elf
BOOT_BIN = $(OUT_DIR)/BOOT.BIN

all: $(BOOT_BIN)

$(GEN_SCRIPTS): $(SCRIPTS)
	rm -rf $(BUILD_DIR) $(OUT_DIR)
	mkdir -p $(BUILD_DIR) $(OUT_DIR)
	$(SCRIPTS_DIR)/build_boot_bin.sh scripts $(BIT_FILE) $(HDF_FILE) $(UBOOT_FILE) $(UBOOT_LOADADDR)

$(FSBL_SRC): $(GEN_SCRIPTS)
	$(SCRIPTS_DIR)/build_boot_bin.sh create_fsbl $(BIT_FILE) $(HDF_FILE) $(UBOOT_FILE) $(UBOOT_LOADADDR)

$(FSBL_ELF): $(FSBL_SRC)
	cd $(FSBL_SRC); \
	git init; git add -A; git commit -s -m "init"; \
	git am $(FSBL_PATCHES_DIR)/*
	$(SCRIPTS_DIR)/build_boot_bin.sh build_fsbl $(BIT_FILE) $(HDF_FILE) $(UBOOT_FILE) $(UBOOT_LOADADDR)

$(BOOT_BIN): $(FSBL_ELF) $(UBOOT_FILE) $(BIT_FILE) $(HDF_FILE)
	$(SCRIPTS_DIR)/build_boot_bin.sh build_bootbin $(BIT_FILE) $(HDF_FILE) $(UBOOT_FILE) $(UBOOT_LOADADDR)


.PHONY: clean

clean:
	rm -rf build output
