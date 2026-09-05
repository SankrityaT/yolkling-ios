#!/bin/bash
# Verify a build really carries the Family Controls entitlement, BEFORE uploading.
#
# Four submissions were rejected for a missing entitlement that was present
# everywhere we looked: approved on both App IDs, enabled, and inside the archive.
# The gap is that `Distribute App` RE-SIGNS the app on export, so the artifact Apple
# scans is the exported .ipa, not the archive. A distribution profile cached before
# Family Controls (Distribution) was approved silently drops the entitlement there.
#
#   ./check_entitlement.sh                 # newest archive (what you built)
#   ./check_entitlement.sh path/to/App.ipa # exported ipa  (what Apple scans)
#
# NOTE ON PROFILE TYPE. With automatic signing Xcode signs the ARCHIVE with a
# development profile and only re-signs with the distribution profile during
# Distribute App. So profile:DEVELOPMENT on an archive is normal and is reported
# here for information only. It is a failure only on an exported .ipa.
set -u
TARGET="${1:-}"
TMP=""
if [ -n "$TARGET" ] && [[ "$TARGET" == *.ipa ]]; then
  TMP=$(mktemp -d); unzip -oq "$TARGET" -d "$TMP"; APP="$TMP/Payload/Yolkling.app"
  echo "Checking EXPORTED IPA (this is what Apple scans)"
else
  ARCH=$(ls -dt ~/Library/Developer/Xcode/Archives/*/*.xcarchive 2>/dev/null | head -1)
  [ -z "$ARCH" ] && { echo "No archive found."; exit 1; }
  APP="$ARCH/Products/Applications/Yolkling.app"
  echo "Checking ARCHIVE (note: export re-signs, so also check the .ipa)"
fi
echo "BUILD $(/usr/libexec/PlistBuddy -c 'Print :CFBundleVersion' "$APP/Info.plist" 2>/dev/null)"
fail=0
for b in "$APP" "$APP/Extensions/"*.appex; do
  [ -e "$b" ] || continue
  ent=MISSING
  codesign -d --entitlements - "$b" 2>/dev/null | grep -q family-controls && ent=OK
  kind=DISTRIBUTION
  p="$b/embedded.mobileprovision"
  if [ -e "$p" ]; then
    security cms -D -i "$p" 2>/dev/null | plutil -extract ProvisionedDevices raw - >/dev/null 2>&1 && kind=DEVELOPMENT
  fi
  # Entitlement must always survive. Profile type only matters on the exported
  # ipa: a development-signed archive is what automatic signing normally produces.
  [ "$ent" = OK ] || fail=1
  if [ -n "$TMP" ] && [ "$kind" != DISTRIBUTION ]; then fail=1; fi
  printf "  %-34s entitlement:%-8s profile:%s\n" "$(basename "$b")" "$ent" "$kind"
done
[ -n "$TMP" ] && rm -rf "$TMP"
echo
if [ $fail -eq 0 ]; then
  if [ -n "$TMP" ]; then
    echo "PASS. This is the artifact Apple scans. Safe to upload."
  else
    echo "Archive looks right. Now export and run this again on the .ipa,"
    echo "because Distribute App re-signs and only the ipa proves what ships."
  fi
else
  echo "FAIL. Do not upload."
fi
exit $fail
