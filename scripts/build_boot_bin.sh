#!/bin/bash
set -ex

CMD=$1
BIT_FILE=$2
HDF_FILE=$3
UBOOT_FILE=$4

BUILD_DIR=build/
OUTPUT_DIR=output/

usage() {
	echo "usage: $0 command system_top.bit system_top.hdf u-boot.elf"
	echo "valid commands:"
	echo "   scripts      :    generate tcl scripts"
	echo "   create_fsbl  :    generate ZYNQ fsbl"
	echo "   build_fslb   :    build ZYNQ fsbl"
	echo "   build_bootbin:    build ZYNQ boot.bin"

	exit 1
}

depends() {
	echo Xilinx $1 must be installed and in your PATH
	echo try: source /opt/Xilinx/Vivado/201x.x/settings64.sh
	exit 1
}

check_xsdk() {
	### Check for required Xilinx tools
	command -v xsct >/dev/null 2>&1 || depends xsct
	command -v bootgen >/dev/null 2>&1 || depends bootgen
}

gen_scripts() {
	cp $HDF_FILE $BUILD_DIR/

	### Create create_fsbl.tcl file used by xsdk to create the fsbl
	echo "hsi open_hw_design `basename $HDF_FILE`" > $BUILD_DIR/create_fsbl.tcl
	echo 'set cpu_name [lindex [hsi get_cells -filter {IP_TYPE == PROCESSOR && IP_NAME =~ "*ps7*"}] 0]' >> $BUILD_DIR/create_fsbl.tcl
	echo 'sdk setws ./build/sdk' >> $BUILD_DIR/create_fsbl.tcl
	echo "sdk createhw -name hw_0 -hwspec `basename $HDF_FILE`" >> $BUILD_DIR/create_fsbl.tcl
	echo 'sdk createapp -name fsbl -hwproject hw_0 -proc $cpu_name -os standalone -lang C -app {Zynq FSBL}' >> $BUILD_DIR/create_fsbl.tcl
	echo 'configapp -app fsbl build-config release' >> $BUILD_DIR/create_fsbl.tcl

	### Create build_fsbl_project.tcl file used by xsdk to build the fsbl
	echo "hsi open_hw_design `basename $HDF_FILE`" > $BUILD_DIR/build_fsbl.tcl
	echo 'set cpu_name [lindex [hsi get_cells -filter {IP_TYPE == PROCESSOR && IP_NAME =~ "*ps7*"}] 0]' >> $BUILD_DIR/build_fsbl.tcl
	echo 'sdk setws ./build/sdk' >> $BUILD_DIR/build_fsbl.tcl
	echo 'configapp -app fsbl build-config release' >> $BUILD_DIR/build_fsbl.tcl
	echo 'sdk projects -build -type all' >> $BUILD_DIR/build_fsbl.tcl

	### Create zynq.bif file used by bootgen
	echo 'the_ROM_image:' > $OUTPUT_DIR/zynq.bif
	echo '{' >> $OUTPUT_DIR/zynq.bif
	echo '[bootloader] fsbl.elf' >> $OUTPUT_DIR/zynq.bif
	echo 'system_top.bit' >> $OUTPUT_DIR/zynq.bif
	echo '[load=0x4000000] u-boot.bin' >> $OUTPUT_DIR/zynq.bif
	echo '}' >> $OUTPUT_DIR/zynq.bif
}

### Generate fsbl sources
create_fsbl() {
	cd $BUILD_DIR
	xsct create_fsbl.tcl
}

### Build fsbl.elf
build_fsbl() {
	cd $BUILD_DIR
	xsct build_fsbl.tcl
}

### Build BOOT.BIN
build_bootbin() {
	### Copy hdf/fsbl/u-boot.elf/system_top.bit into the output folder
	cp $UBOOT_FILE $OUTPUT_DIR/u-boot.bin
	cp $HDF_FILE $OUTPUT_DIR/
	cp $BUILD_DIR/build/sdk/fsbl/Release/fsbl.elf $OUTPUT_DIR/fsbl.elf
	cp "${BIT_FILE}" $OUTPUT_DIR/system_top.bit

	cd $OUTPUT_DIR
	bootgen -arch zynq -image zynq.bif -o BOOT.BIN -w
}

### Check command line parameters
#echo $HDF_FILE | grep -q -e ".hdf" -e ".xsa" || usage
#echo $UBOOT_FILE | grep -q -e ".elf" -e "uboot" || usage

if [ ! -f $HDF_FILE ]; then
    echo $HDF_FILE: File not found!
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
