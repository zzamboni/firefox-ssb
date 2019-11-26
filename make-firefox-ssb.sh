#!/bin/bash
# Diego Zamboni, 2019
#
# Create a crude Firefox-based Site-Specific Browser (SSB).
# Usage:
#    make-firefox-ssb.sh NewApp [iconfile] [defaultURL]

# - NewApp is the name that the new app will have. It will be a copy of
#   /Applications/Firefox.app, with the necessary modifications.
# - iconfile has to be (for now) a local image file containing the
#   icon for the new app.
# - defaultURL is the URL that will be opened upon startup by the new
#   app.
#
# The new app will be placed under DESTDIR, defaults to ~/Applications/FirefoxSSBs/

DESTDIR=~/Applications/FirefoxSSBs

appname=$1
if [[ -z "$appname" ]]; then
    echo "Usage: $0 AppName [iconfile [defaultURL]]" >&2
    exit 1
fi
icon=$2
url=$3

make_icns() {
    f=$1
    rm -rf Contents/Resources/$appname.iconset
    mkdir Contents/Resources/$appname.iconset
    sips -z 16 16     $f --out Contents/Resources/$appname.iconset/icon_16x16.png
    sips -z 32 32     $f --out Contents/Resources/$appname.iconset/icon_16x16@2x.png
    sips -z 32 32     $f --out Contents/Resources/$appname.iconset/icon_32x32.png
    sips -z 64 64     $f --out Contents/Resources/$appname.iconset/icon_32x32@2x.png
    sips -z 128 128   $f --out Contents/Resources/$appname.iconset/icon_128x128.png
    sips -z 256 256   $f --out Contents/Resources/$appname.iconset/icon_128x128@2x.png
    sips -z 256 256   $f --out Contents/Resources/$appname.iconset/icon_256x256.png
    sips -z 512 512   $f --out Contents/Resources/$appname.iconset/icon_256x256@2x.png
    sips -z 512 512   $f --out Contents/Resources/$appname.iconset/icon_512x512.png
    sips -z 1024 1024 $f --out Contents/Resources/$appname.iconset/icon_512x512@2x.png
    iconutil -c icns Contents/Resources/$appname.iconset
    rm -R Contents/Resources/$appname.iconset
}

mkdir -p $DESTDIR
appdest=$DESTDIR/$appname.app
if [[ -d "$appdest" ]]; then
    echo "### Removing old copy of $appdest"
    rm -rf "$appdest"
fi
echo "### Copying Firefox.app as the base for $appname.app"
cp -a /Applications/Firefox.app "$appdest"
cd "$appdest"
echo "### Setting new application properties"
plutil -replace CFBundleName -string $appname Contents/Info.plist
plutil -replace CFBundleIdentifier -string org.zzamboni.$appname Contents/Info.plist
echo 'CFBundleName = "'$appname'";' > Contents/Resources/en.lproj/InfoPlist.strings
echo 'CFBundleDisplayName = "'$appname'";' >> Contents/Resources/en.lproj/InfoPlist.strings
if [[ -n "$icon" ]]; then
    echo "### Setting new application icon, creating $appname.icns from $icon"
    make_icns $icon >/dev/null
    plutil -replace CFBundleIconFile -string $appname.icns Contents/Info.plist
fi
if [[ -n "$url" ]]; then
    echo "### Setting new application homepage to $url"
    homepage='    "Homepage": {
      "URL": "'$url'",
      "Locked": false,
      "StartPage": "homepage"
    },'
else
    homepage=""
fi
mkdir Contents/Resources/distribution
cat <<EOF > Contents/Resources/distribution/policies.json
{
  "policies": {
    "DontCheckDefaultBrowser": true,
    "OverrideFirstRunPage": "",
$homepage
    "Preferences": {
      "datareporting.policy.dataSubmissionPolicyBypassNotification": true
    }
  }
}
EOF
echo "### New application $appdest created"
