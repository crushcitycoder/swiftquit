#!/bin/zsh
set -euo pipefail

script_dir=${0:A:h}
project_root=${script_dir:h}
derived_data_path="$project_root/.build/DerivedData"
app_path="$derived_data_path/Build/Products/Release/Swift Quit Fork.app"
helper_path="$app_path/Contents/Library/LoginItems/LaunchAtLoginHelper.app"
install_dir=${INSTALL_DIR:-/Applications}
install_path="$install_dir/Swift Quit Fork.app"
previous_install_path="$install_dir/Swift Quit Fork.previous.app"

xcodebuild \
  -project "$project_root/Swift Quit.xcodeproj" \
  -scheme "Swift Quit" \
  -configuration Release \
  -derivedDataPath "$derived_data_path" \
  build

codesign --force --sign - "$helper_path"
codesign --force --sign - \
  --entitlements "$project_root/Swift Quit/Swift_Quit.entitlements" \
  "$app_path"
codesign --verify --deep --strict --verbose=2 "$app_path"

if [[ -e "$install_path" ]]; then
  if [[ -e "$previous_install_path" ]]; then
    print -u2 "Refusing to replace $install_path while $previous_install_path exists."
    exit 1
  fi

  mv "$install_path" "$previous_install_path"
fi

ditto "$app_path" "$install_path"
print "Installed $install_path"
