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
cp ~/build-tools/dtc /usr/bin/dtc

# Build
cd ~/kernel

rel_date=$(date "+%Y%m%e-%H%S"|sed 's/[ ][ ]*/0/g')
short_commit="$(cut -c-8 <<< "$(git rev-parse HEAD)")"

echo
echo "Setting defconfig"
echo
make epichook_defconfig || exit 1

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
git config --global user.email "yuhan@rsyhan.me"
git config --global user.name "Yuhan Zhang"
git clone https://$GIT_ID:$GIT_PWD@github.com/rsyhan/Yuhan_OnePlus7Pro_Kernel
mkdir Yuhan_OnePlus7Pro_Kernel/Flyme-sm6150-$rel_date-$short_commit
cp ~/kernel/EpicHook*.zip Yuhan_OnePlus7Pro_Kernel/Flyme-sm6150-$rel_date-$short_commit
cd Yuhan_OnePlus7Pro_Kernel
git add . && git commit -s -m "[Flyme-sm6150-$rel_date] Redmi K20 EpicHook Kernel Drone CI Release $short_commit" --signoff
git push https://$GIT_ID:$GIT_PWD@github.com/rsyhan/Yuhan_OnePlus7Pro_Kernel HEAD:master
