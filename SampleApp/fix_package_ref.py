#!/usr/bin/env python3
"""
Minimal, deterministic patch for xcodegen's local SPM package bug.

xcodegen 2.45.0+ creates:
  ✓ XCLocalSwiftPackageReference (correctly in packageReferences)
  ✗ XCSwiftPackageProductDependency WITHOUT a `package =` link to it
  ✗ A conflicting PBXFileReference folder pointing at the same path

This script links the product dependency to the local package reference and
removes the conflicting folder reference. UUIDs are resolved dynamically.
"""

import re, os, sys

pbx = os.path.join(os.path.dirname(os.path.abspath(__file__)),
                   "SampleApp.xcodeproj", "project.pbxproj")
content = open(pbx).read()

# Already patched?
if re.search(r'XCSwiftPackageProductDependency;\s*\n\s*package\s*=', content):
    print("Already patched — skipping.")
    sys.exit(0)

# 1. Find the XCLocalSwiftPackageReference UUID.
local_uuid = None
for m in re.finditer(r'([0-9A-F]{24}) /\* XCLocalSwiftPackageReference.*?\*/ = \{', content):
    local_uuid = m.group(1)
    break
if not local_uuid:
    print("ERROR: XCLocalSwiftPackageReference not found", file=sys.stderr)
    sys.exit(1)
print(f"  Local package ref: {local_uuid}")

# 2. Link the product dependency to the local package reference.
content = content.replace(
    "isa = XCSwiftPackageProductDependency;\n\t\t\tproductName = BottomShelfer;",
    f'isa = XCSwiftPackageProductDependency;\n'
    f'\t\t\tpackage = {local_uuid} /* XCLocalSwiftPackageReference ".." */;\n'
    f'\t\t\tproductName = BottomShelfer;',
)
print("  Linked product dependency → local package reference")

# 3. Remove the conflicting folder reference (PBXFileReference, path = ..).
for uuid in re.findall(r'([0-9A-F]{24}) /\* BottomShelfer \*/ = \{isa = PBXFileReference;[^\n]*path = \.\.;', content):
    content = re.sub(
        rf'\t\t{uuid} /\* BottomShelfer \*/ = \{{isa = PBXFileReference;[^\n]*\n',
        '', content)
    content = re.sub(
        rf'\t\t\t\t{uuid} /\* BottomShelfer \*/,\n',
        '', content)
    print(f"  Removed conflicting folder reference: {uuid}")

open(pbx, "w").write(content)
print("Done.")
