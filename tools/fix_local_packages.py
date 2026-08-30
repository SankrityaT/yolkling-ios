#!/usr/bin/env python3
"""Rewrite XcodeGen's local-package wiring into the shape native Xcode writes.

Run this after every `xcodegen generate`.

XcodeGen 2.46 emits local Swift packages in a hybrid of two styles: a modern
XCLocalSwiftPackageReference, plus a legacy drag-in folder PBXFileReference,
with the XCSwiftPackageProductDependency entries carrying only a productName
(no `package` pointer). `xcodebuild` resolves that by name-matching, but the
Xcode IDE does not: it never loads the package into its graph and every build
fails instantly with "Missing package product 'YolklingCore'" while the exact
same project builds fine from the command line.

Native Xcode ("Add Local Package…") writes:
  - the XCLocalSwiftPackageReference (XcodeGen already does this)
  - product dependencies whose `package` points AT that reference
  - no folder PBXFileReference for the package

This script applies the last two. Idempotent; safe to run twice.
"""

import re
import sys
from pathlib import Path

PBXPROJ = Path(__file__).resolve().parent.parent / "Yolkling.xcodeproj/project.pbxproj"


def fix(source: str) -> tuple[str, list[str]]:
    notes = []

    for ref_id, rel_path in re.findall(
        r'(\w{24}) /\* XCLocalSwiftPackageReference "([^"]+)" \*/ = \{', source
    ):
        package_name = rel_path.rsplit("/", 1)[-1]

        # 1. Point the product dependencies at the local package reference.
        orphan = (
            "\t\t\tisa = XCSwiftPackageProductDependency;\n"
            f"\t\t\tproductName = {package_name};"
        )
        wired = (
            "\t\t\tisa = XCSwiftPackageProductDependency;\n"
            f'\t\t\tpackage = {ref_id} /* XCLocalSwiftPackageReference "{rel_path}" */;\n'
            f"\t\t\tproductName = {package_name};"
        )
        count = source.count(orphan)
        if count:
            source = source.replace(orphan, wired)
            notes.append(f"{package_name}: wired {count} product dependencies to {ref_id}")

        # 2. Drop the legacy folder file reference (and its group membership).
        folder = re.search(
            r"(\w{24}) /\* %s \*/ = \{isa = PBXFileReference; lastKnownFileType = folder;[^}]*path = %s;[^}]*\};\n"
            % (re.escape(package_name), re.escape(rel_path)),
            source,
        )
        if folder:
            source = source.replace(folder.group(0), "")
            source = re.sub(r"\t+%s /\* %s \*/,\n" % (folder.group(1), re.escape(package_name)), "", source)
            notes.append(f"{package_name}: removed legacy folder reference {folder.group(1)}")

    return source, notes


def main() -> int:
    original = PBXPROJ.read_text()
    fixed, notes = fix(original)
    if fixed != original:
        PBXPROJ.write_text(fixed)
    for note in notes:
        print(note)
    if not notes:
        print("nothing to fix (already in native shape)")
    return 0


if __name__ == "__main__":
    sys.exit(main())
