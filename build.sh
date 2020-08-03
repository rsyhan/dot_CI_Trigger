#!/bin/bash

# EpicHook CI | Powered by Drone | 2020 -
# Setup
export HOME=/drone/src
export ARCH=arm64
export SUBARCH=arm64
export CROSS_COMPILE=~/build-tools/arm64-gcc/bin/aarch64-elf-
export CROSS_COMPILE_ARM32=~/build-tools/arm32-gcc/bin/arm-eabi-
export KBUILD_BUILD_USER=HanyanI
export KBUILD_BUILD_HOST=EpicHook-Build
export KJOBS="$((`grep -c '^processor' /proc/cpuinfo` * 2))"

# Build
cd ~/kernel

rel_date=$(date "+%Y%m%e-%H%S"|sed 's/[ ][ ]*/0/g')
short_commit="$(cut -c-8 <<< "$(git rev-parse HEAD)")"

echo
echo "Setting defconfig"
echo
make vendor/lineage_davinci_defconfig || exit 1

echo
echo "Compiling"
echo 
make -j${KJOBS} || exit 1

if [ -e arch/arm64/boot/Image.gz ] ; then
	echo
	echo "Building Kernel Package"
	echo
	mkdir kernelzip
	cp -rp ~/build-tools/anykernel/* kernelzip/
	cp arch/arm64/boot/Image.gz-dtb kernelzip/
	cd kernelzip
	7z a -mx9 EpicHook-tmp.zip *
	zipalign -v 4 EpicHook-tmp.zip ../EpicHook-$rel_date-$short_commit.zip
	rm EpicHook-tmp.zip
	cd ..
	ls -al EpicHook-$rel_date-$short_commit.zip
fi

echo
echo "Uploading"
echo

cd ~
curl -sL https://git.io/file-transfer | sh
./transfer bit kernel/EpicHook-*.zip