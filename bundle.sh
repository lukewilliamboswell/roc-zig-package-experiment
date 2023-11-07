#!/bin/bash
set -e

## Get the directory of the currently executing script
DIR="$(dirname "$0")"

# Change to that directory
cd "$DIR" || exit

lib="libgraphics.a"

# Build for macos-arm64
rm -rf zig-out/
zig build -Dtarget=aarch64-macos
cp zig-out/lib/$lib platform/macos-arm64.a

# Build for macos-x64
rm -rf zig-out/
zig build -Dtarget=x86_64-macos
cp zig-out/lib/$lib platform/macos-x64.a

# Build for linux-x64 including surgical linker host
roc gen-stub-lib --target linux-x64 examples/rocLovesGraphics.roc

rm -rf zig-out/
zig build -Dtarget=x86_64-linux-gnu
cp zig-out/lib/$lib platform/linux-x64.a
cp zig-out/bin/dynhost platform/dynhost

roc preprocess-host --target linux-x64 examples/rocLovesGraphics.roc

# TEST RUN USING NATIVE
roc run --prebuilt-platform examples/rocLovesGraphics.roc

# BUNDLE
roc build --bundle .tar.br platform/main.roc

# TARGETS FROM roc-lang/roc/crates/compiler/roc_target/src/lib.rs
#[strum(serialize = "linux-x32")] 
#[strum(serialize = "linux-x64")]
#[strum(serialize = "linux-arm64")]
#[strum(serialize = "macos-x64")]
#[strum(serialize = "macos-arm64")]
#[strum(serialize = "windows-x32")]
#[strum(serialize = "windows-x64")]
#[strum(serialize = "windows-arm64")]
#[strum(serialize = "wasm32")]
