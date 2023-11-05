#!/bin/bash

## Get the directory of the currently executing script
DIR="$(dirname "$0")"

# Change to that directory
cd "$DIR" || exit

obj="host.o"

# Build for macos-arm64
rm -rf zig-out/
zig build -Dtarget=aarch64-macos
cp zig-out/$obj platform/macos-arm64.o

# Build for macos-x64
rm -rf zig-out/
zig build -Dtarget=x86_64-macos
cp zig-out/$obj platform/macos-x64.o

# Build for linux-x64
rm -rf zig-out/
zig build -Dtarget=x86_64-linux
cp zig-out/$obj platform/linux-x64.o

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
