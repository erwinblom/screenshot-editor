#!/bin/zsh
set -eu
cd "${0:A:h}"
/usr/bin/shasum -a 256 -c Resources/app-icon.sha256
APP="${PWD}/FMT Screenshot Editor.app"
mkdir -p "$APP/Contents/MacOS" "$APP/Contents/Resources"
/usr/bin/swiftc -swift-version 5 -O -module-cache-path /private/tmp/fmt-swift-cache Sources/main.swift -o "$APP/Contents/MacOS/FMT Screenshot Editor" -framework AppKit -framework Carbon -framework CoreText -framework UniformTypeIdentifiers
cp Resources/fmt-target-logo.svg "$APP/Contents/Resources/"
cp Resources/Info.plist "$APP/Contents/Info.plist"
/usr/bin/swift -module-cache-path /private/tmp/fmt-swift-cache Sources/icon.swift
cp Resources/FMT.icns "$APP/Contents/Resources/"
/usr/bin/codesign --force --sign - --identifier nl.fastmovingtargets.screenshot.editor "$APP"
echo "Gebouwd: $APP"
