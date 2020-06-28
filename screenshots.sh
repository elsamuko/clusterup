#!/usr/bin/env bash

# forward emulator server
adb forward tcp:3001 tcp:3001

# take screenshots
flutter drive --target=test_driver/screenshot.dart
