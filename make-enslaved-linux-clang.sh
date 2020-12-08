#!/bin/bash

# Paths
PATH_TO_KERNEL_SOURCE="${HOME}/android_kernel_motorola_msm8937"
PATH_TO_TOOLCHAIN="${HOME}/aarch64-linux-android-4.9-961622e926a1b21382dba4dd9fe0e5fb3ee5ab7c"
PATH_TO_ANYKERNEL="${HOME}/AnyKernel3"
PATH_TO_CLANG="${HOME}/linux-x86-android-10.0.0_r3-clang-r353983c"
DEVICE_NAME="cedric"

PATH_TO_COMPILER="${PATH_TO_TOOLCHAIN}/bin/aarch64-linux-android-"

DATEANDTIME=$(date +%H%M-%d%m%y)

ZIPNAME="${1}-${DATEANDTIME}"

# Verify Paths

echo "Verifying paths..."

if [ ! -d "$PATH_TO_KERNEL_SOURCE" ];
then
  echo "ERROR: ${PATH_TO_KERNEL_SOURCE} does not exist"
  exit 1
fi

if [ ! -d "$PATH_TO_TOOLCHAIN" ];
then
  echo "ERROR: ${PATH_TO_TOOLCHAIN} does not exist"
  exit 1
fi

if [ ! -d "$PATH_TO_ANYKERNEL" ];
then
  echo "ERROR: ${PATH_TO_ANYKERNEL} does not exist"
  exit 1
fi


# Check if /out already exists
if [ -d "$PATH_TO_KERNEL_SOURCE/out" ];
then
  echo "/out already exists. Deleting /out ..."  
  rm -rf "${PATH_TO_KERNEL_SOURCE}/out"
fi


cd $PATH_TO_KERNEL_SOURCE

# Create Configs

echo "Creating configs..."

make O=out ARCH=arm64 CROSS_COMPILE=$PATH_TO_COMPILER "${DEVICE_NAME}_defconfig"

if [ $? -ne 0 ]; then
    echo "ERROR: Couldn't create configs"
    exit 1
fi


# Compile Kernel
echo "Compiling Kernel..."
make O=out ARCH=arm64 CC="${PATH_TO_CLANG}/bin/clang" CLANG_TRIPLE=aarch64-linux-gnu- CROSS_COMPILE=$PATH_TO_COMPILER -j4

if [ $? -ne 0 ]; then
    echo "ERROR: Couldn't compile"
    rm -rf out
    exit 1
fi


# Copy Image.gz to Anykernel3/

echo "Copying Image.gz to AnyKernel3/"

cp "${PATH_TO_KERNEL_SOURCE}/out/arch/arm64/boot/Image.gz" "$PATH_TO_ANYKERNEL/"

# Save CHANGELOG to AnyKernel3

git --no-pager log --oneline fork/add-fixes^..HEAD > "${PATH_TO_ANYKERNEL}/CHANGELOG.txt"


cd $PATH_TO_ANYKERNEL


# Delete already existing zips
for f in ./*.zip; do
    if [ -e "$f" ];
    then
        rm $f
    fi
done


# Make zip file

echo "Zipping kernel..."

zip -r9 "${ZIPNAME}.zip" * -x .git README.md *placeholder *.zip

if [ $? -ne 0 ]; then
  echo "ERROR: Couldn't zip kernel"
  exit 1
else
  echo "${ZIPNAME}.zip created!"
fi

echo "Ah yes, enslaved linux !"


# Check if device is connected and copy the .zip

echo "Checking if ${DEVICE_NAME} is connected..."

DEV_NAME_FROM_ADB=$(adb shell getprop ro.product.device)

if [ $? -ne 0 ]; then
  echo "ERROR: No Devices Connected!"
  exit 1
fi

if [ $DEV_NAME_FROM_ADB == $DEVICE_NAME ]; then
  echo "${DEVICE_NAME} is connected"

  # Reboot to recovery (if not in recovery)

  echo "Checking if ${DEVICE_NAME} is in recovery mode..."

  DEV_STATE_FROM_ADB=$(adb get-state)

  if [ $DEV_STATE_FROM_ADB != "recovery" ]; then
    echo "Rebooting ${DEVICE_NAME} to recovery..."
    adb reboot recovery
    adb wait-for-recovery
    echo "$DEVICE_NAME is in recovery mode"
    sleep 10
  else
    echo "$DEVICE_NAME is in recovery mode"
  fi
  
  # Copying .zip to external_sd/

  adb push "${PATH_TO_ANYKERNEL}/${ZIPNAME}.zip" "/external_sd/${ZIPNAME}.zip"

  if [ $? -ne 0 ]; then
  	echo "ERROR: Couldn't copy ${ZIPNAME}.zip"
    exit 1
  else
    echo "${ZIPNAME}.zip copied to ${DEVICE_NAME}"
  fi

else
  echo "ERROR: ${DEVICE_NAME} is not connected"
  exit 1
fi

echo "You can now flash your kernel!. Enjoy your enslaved linux!"
