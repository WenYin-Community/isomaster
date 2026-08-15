#!/bin/bash
# Create a release source tarball from the current git tree.
# Usage: release.sh VERSION
# Output: ../releases/isomaster-VERSION.tar.bz2 (override dir with OUT_DIR)

set -e

VERSION=$1

if [ -z "$VERSION" ]
then
    echo "Usage: release.sh VERSION"
    exit 1
fi

if [ -n "$(git status --porcelain)" ]
then
    echo "Error: working tree is not clean; commit or stash your changes first."
    exit 1
fi

OUT_DIR=${OUT_DIR:-../releases}
mkdir -p "$OUT_DIR"

# Export the committed tree, excluding build artifacts and generated files.
# The source tarball must contain only files that are actually tracked.
git archive HEAD \
    --format=tar \
    --prefix="isomaster-$VERSION/" \
    --output="$OUT_DIR/isomaster-$VERSION.tar" \
    . \
    ':(exclude)*.o' \
    ':(exclude)*.a' \
    ':(exclude)*.mo' \
    ':(exclude)isomaster.c' \
    ':(exclude)settings.c' \
    ':(exclude)file-item.c' \
    ':(exclude)iso-operations.c' \
    ':(exclude)util.c' \
    ':(exclude)isomaster' \
    ':(exclude)iconpath.c' \
    ':(exclude)iconpath.h' \
    ':(exclude)version.inc' \
    ':(exclude)tests/test_bk'

bzip2 -f "$OUT_DIR/isomaster-$VERSION.tar"

echo "isomaster-$VERSION.tar.bz2 created in $OUT_DIR"
