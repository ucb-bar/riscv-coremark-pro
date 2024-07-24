#!/usr/bin/env bash

set -ex

RDIR=$(git rev-parse --show-toplevel)

function build_coremark_pro
{
    CMDIR=coremark-pro-$1
    BUILDDIR=build-$1

    git submodule update --init $CMDIR
    for PATCH in "patches"/*.patch; do
        if [ -f $PATCH ]; then
	    echo "Applying $PATCH"
	    # Apply the patch with --reverse to check if it's already applied
	    if git -C $CMDIR apply --check --reverse < $RDIR/"$PATCH" 2>/dev/null; then
	        echo "Patch $PATCH is already applied"
	    else
	        # Apply the patch
	        if git -C $CMDIR apply --check < $RDIR/"$PATCH"; then
		    git -C $CMDIR apply < $RDIR/"$PATCH"
		    echo "Patch $PATCH applied successfully"
	        else
		    echo "Failed to apply the patch $PATCH"
	        fi
	    fi
        fi
    done

    cp makefiles/* $CMDIR/util/make

    echo "Building $CMDIR for riscv64 baremetal"

    rm -rf $CMDIR/builds
    make -C $CMDIR TARGET=riscv64 -j16 build USE_RVV=1
    mkdir -p $BUILDDIR
    cp $CMDIR/builds/riscv64/riscv-gcc64/bin/*.riscv $BUILDDIR

    for BINARY in $BUILDDIR/*.riscv; do
        if [ -f $BINARY ]; then
	    riscv64-unknown-elf-objdump -D $BINARY > $BINARY.dump
        fi
    done
}

build_coremark_pro base
build_coremark_pro rvv
