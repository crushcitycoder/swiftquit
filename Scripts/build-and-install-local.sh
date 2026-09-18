#!/bin/zsh
set -euo pipefail

script_dir=${0:A:h}
project_root=${script_dir:h}
derived_data_path="$project_root/.build/DerivedData"
app_path="$derived_data_path/Build/Products/Release/Swift Quit Fork.app"
helper_path="$app_path/Contents/Library/LoginItems/LaunchAtLoginHelper.app"
install_dir=${INSTALL_DIR:-/Applications}
install_path="$install_dir/Swift Quit Fork.app"
backup_dir=${BACKUP_DIR:-"$project_root/.build/PreviousInstall"}
previous_install_path="$backup_dir/Swift Quit Fork.app"

xcodebuild \
  -project "$project_root/Swift Quit.xcodeproj" \
  -scheme "Swift Quit" \
  -configuration Release \
  -derivedDataPath "$derived_data_path" \
  build

app_bundle_identifier=$(/usr/libexec/PlistBuddy -c 'Print :CFBundleIdentifier' "$app_path/Contents/Info.plist")
helper_bundle_identifier=$(/usr/libexec/PlistBuddy -c 'Print :CFBundleIdentifier' "$helper_path/Contents/Info.plist")

codesign --force --sign - \
  --requirements "=designated => identifier \"$helper_bundle_identifier\"" \
  "$helper_path"
codesign --force --sign - \
  --entitlements "$project_root/Swift Quit/Swift_Quit.entitlements" \
  --requirements "=designated => identifier \"$app_bundle_identifier\"" \
  "$app_path"
codesign --verify --deep --strict --verbose=2 "$app_path"

if [[ -e "$install_path" ]]; then
  if [[ -e "$previous_install_path" ]]; then
    print -u2 "Refusing to replace $install_path while $previous_install_path exists."
    exit 1
  fi

  mkdir -p "$backup_dir"
  mv "$install_path" "$previous_install_path"
fi

ditto "$app_path" "$install_path"
print "Installed $install_path"
