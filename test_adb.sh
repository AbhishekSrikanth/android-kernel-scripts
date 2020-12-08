#!/bin/bash

DEVICE_NAME="cedric"
PATH_TO_ANYKERNEL="${HOME}/SandBox/AnyKernel3"

echo "Checking if ${DEVICE_NAME} is connected..."

DEV_NAME_FROM_ADB=$(adb shell getprop ro.product.device)

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

    # Copying .zip to external_sd/

    adb push "${PATH_TO_ANYKERNEL}/${1}.zip" "/external_sd/"

    if [ $? -ne 0 ]; then
      echo "ERROR: Couldn't copy ${1}.zip"
      exit 1
    else
      echo "${1}.zip copied to ${DEVICE_NAME}"
    fi

  else
    echo "$DEVICE_NAME is in recovery mode"

    # Copying .zip to external_sd/

    adb push "${PATH_TO_ANYKERNEL}/${1}.zip" "/external_sd/"

    if [ $? -ne 0 ]; then
      echo "ERROR: Couldn't copy ${1}.zip"
      exit 1
    else
      echo "${1}.zip copied to ${DEVICE_NAME}"
    fi
  fi

else
  echo "ERROR: ${DEVICE_NAME} is not connected"
  exit 1
fi

echo "You can now flash your kernel!. Enjoy enslaved linux!"