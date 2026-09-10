#!/bin/bash
# Does this build actually contain the permission fixes?
#
# Three rejections in a row quoted UI text that had already been removed from the
# source, and there was no way to tell whether Apple was reviewing a stale binary
# or describing a screen we had missed, because nobody could look inside the build
# that shipped. This looks.
#
# UI string literals end up in the compiled binary, so their presence or absence is
# a fact about the artifact rather than a claim about the repository. Debug builds
# put them in Yolkling.debug.dylib and release builds in the main executable, so
# every Mach-O in the bundle is scanned.
#
#   ./check_build_contains.sh                   # newest archive
#   ./check_build_contains.sh path/to/App.ipa   # an exported ipa
set -u
TARGET="${1:-}"; TMP=""
if [ -n "$TARGET" ] && [[ "$TARGET" == *.ipa ]]; then
  TMP=$(mktemp -d); unzip -oq "$TARGET" -d "$TMP"; APP="$TMP/Payload/Yolkling.app"
else
  ARCH=$(ls -dt ~/Library/Developer/Xcode/Archives/*/*.xcarchive 2>/dev/null | head -1)
  [ -z "$ARCH" ] && { echo "No archive found."; exit 1; }
  APP="$ARCH/Products/Applications/Yolkling.app"
fi
[ -d "$APP" ] || { echo "No app at $APP"; exit 1; }
echo "BUILD $(/usr/libexec/PlistBuddy -c 'Print :CFBundleVersion' "$APP/Info.plist" 2>/dev/null)"
echo

# Every Mach-O directly in the app bundle (executable + debug dylib).
scan() { grep -c -- "$1" <(for f in "$APP"/*; do [ -f "$f" ] && strings -a "$f" 2>/dev/null; done) ; }

fail=0
# The button label Apple objected to. Any hit means the build predates the fix.
n=$(scan "connect health")
if [ "$n" -gt 0 ]; then printf '  %-44s FOUND -- STALE BUILD\n' '"connect health" gone?'; fail=1
else printf '  %-44s ok\n' '"connect health" gone?'; fi

# Text that only exists in the fixed build. Absence means the build predates it.
n=$(scan "you can say no on the next screen")
if [ "$n" -eq 0 ]; then printf '  %-44s MISSING -- STALE BUILD\n' 'permission reassurance present?'; fail=1
else printf '  %-44s ok\n' 'permission reassurance present?'; fi

[ -n "$TMP" ] && rm -rf "$TMP"
echo
if [ $fail -eq 0 ]; then echo "PASS. This build has the permission fixes."
else echo "FAIL. This build does NOT have the fixes. Do not submit it."; fi
exit $fail
