#!/usr/bin/env bash

GIT_TAG=$(git describe --abbrev=0)

function doPrepare {
  echo "Clean"
  flutter clean
}

function createBundle {
  echo "Create bundle"
  flutter build appbundle
  cp "build/app/outputs/bundle/release/app-release.aab" "tmp/clusterup-$GIT_TAG.aab"
}

function createAPKs {
  echo "Create apks"
  flutter build apk --no-shrink --split-per-abi
  cp "build/app/outputs/apk/release/app-arm64-v8a-release.apk" "tmp/clusterup-arm64-v8a-$GIT_TAG.apk"
  cp "build/app/outputs/apk/release/app-armeabi-v7a-release.apk" "tmp/clusterup-armeabi-v7a-$GIT_TAG.apk"
}

doPrepare
createBundle
createAPKs
