#!/usr/bin/env bash

# forward emulator server
adb forward tcp:3001 tcp:3001

# take screenshots
flutter drive --target=test_driver/screenshot.dart

cd screenshots || exit

SHOTS=( add_server.png
        edit_server.png
        load_save.png
        run.png
        view_key.png )

for SHOT in "${SHOTS[@]}"; do
  echo "Adding title to $SHOT"
  convert "$SHOT" -page +0+0 ../res/title.png -flatten "$SHOT"
done
