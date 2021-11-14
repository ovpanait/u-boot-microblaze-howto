#!/bin/bash
set -ex

CMD=$1
BIT_FILE=$2
XSA_FILE=$3
UBOOT_FILE=$4
UBOOT_LOADADDR=$5

BUILD_DIR=build/
OUTPUT_DIR=output/
FSBL_SRC="${BUILD_DIR}/zynq_fsbl"

usage() {
	echo "usage: $0 command system_top.bit system_top.hdf u-boot.elf 0x4000000"
	echo "valid commands:"
	echo "   scripts      :    generate tcl scripts"
	echo "   create_fsbl  :    generate ZYNQ fsbl"
	echo "   build_fslb   :    build ZYNQ fsbl"
	echo "   build_bootbin:    build ZYNQ boot.bin"

	exit 1
}

depends() {
	echo Xilinx $1 must be installed and in your PATH
	echo try: source /opt/Xilinx/Vivado/20xx.x/settings64.sh
	exit 1
}

check_xsdk() {
	### Check for required Xilinx tools
	command -v xsct >/dev/null 2>&1 || depends xsct
	command -v bootgen >/dev/null 2>&1 || depends bootgen
}

gen_scripts() {
	cp $XSA_FILE $BUILD_DIR/

	### Create create_fsbl.tcl file used by xsdk to create the fsbl
	echo "hsi open_hw_design `basename $XSA_FILE`" > $BUILD_DIR/create_fsbl.tcl
	echo 'set cpu_name [lindex [hsi get_cells -filter {IP_TYPE == PROCESSOR && IP_NAME =~ "*ps7*"}] 0]' >> $BUILD_DIR/create_fsbl.tcl
	echo "platform create -name hw_0 -hw `basename $XSA_FILE` -os standalone -out ." >> $BUILD_DIR/create_fsbl.tcl
	echo 'app create -name zynq_fsbl -lang c -template {Zynq FSBL} -platform hw_0 -proc $cpu_name -plnx' >> $BUILD_DIR/create_fsbl.tcl

	### Create zynq.bif file used by bootgen
	echo 'the_ROM_image:' > $OUTPUT_DIR/zynq.bif
	echo '{' >> $OUTPUT_DIR/zynq.bif
	echo '[bootloader] fsbl.elf' >> $OUTPUT_DIR/zynq.bif
	echo 'system_top.bit' >> $OUTPUT_DIR/zynq.bif
	echo '[load='"${UBOOT_LOADADDR}"'] u-boot.bin' >> $OUTPUT_DIR/zynq.bif
	echo '}' >> $OUTPUT_DIR/zynq.bif
}

### Generate fsbl sources
create_fsbl() {
	cd $BUILD_DIR
	xsct -sdx -nodisp create_fsbl.tcl
}

### Build fsbl.elf
build_fsbl() {
	local TOOLCHAIN_PATH=""
	cd "${FSBL_SRC}"

	if [ -n "${VITIS_DIR}" ]; then
		TOOLCHAIN_PATH="${VITIS_DIR}/gnu/aarch32/lin/gcc-arm-none-eabi/bin"
	fi
	PATH="${TOOLCHAIN_PATH}:${PATH}" make
}

### Build BOOT.BIN
build_bootbin() {
	### Copy hdf/fsbl/u-boot.elf/system_top.bit into the output folder
	cp $UBOOT_FILE $OUTPUT_DIR/u-boot.bin
	cp $XSA_FILE $OUTPUT_DIR/
	cp "${FSBL_SRC}/executable.elf" "${OUTPUT_DIR}/fsbl.elf"
	cp "${BIT_FILE}" "${OUTPUT_DIR}/system_top.bit"

	cd $OUTPUT_DIR
	bootgen -arch zynq -image zynq.bif -o BOOT.BIN -w
}

### Check command line parameters
#echo $XSA_FILE | grep -q -e ".hdf" -e ".xsa" || usage
#echo $UBOOT_FILE | grep -q -e ".elf" -e "uboot" || usage

if [ ! -f $XSA_FILE ]; then
    echo $XSA_FILE: File not found!
    usage
fi

if [ ! -f $UBOOT_FILE ]; then
    echo $UBOOT_FILE: File not found!
    usage
fi

### Check xilinx environment
check_xsdk

case "$CMD" in
	"scripts")
		gen_scripts
		;;
	"create_fsbl")
		create_fsbl
		;;
	"build_fsbl")
		build_fsbl
		;;
	"build_bootbin")
		build_bootbin
		;;
	*)
		"ERROR: command $CMD not found!"
		usage
		;;
esac
