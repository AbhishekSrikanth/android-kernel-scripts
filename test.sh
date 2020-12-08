#!/bin/bash

VAR=$(adb get-state)

echo "${VAR}"

echo $?