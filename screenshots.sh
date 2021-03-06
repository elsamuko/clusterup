#!/usr/bin/env bash

# start and forward emulator
# flutter emulators --launch Nexus_5_API_24
adb forward tcp:3001 tcp:3001

# take screenshots
flutter clean
flutter drive --target=test_driver/screenshot.dart

cd screenshots || exit

for SHOT in screenshot_*.png; do
  echo "Adding title to $SHOT"
  convert "$SHOT" -page +0+0 ../res/title.png -flatten "$SHOT"
done

echo "Screenshots done :)"
zenity --info --no-wrap --title "Cluster Up" --text "Screenshots done :)"
