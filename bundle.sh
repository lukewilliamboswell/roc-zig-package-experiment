
# Build for macOS arm64
zig build
cp zig-out/lib/libbasic-graphics.a platform/macos-arm64.o  

# RUN
roc run --prebuilt-platform examples/rocLovesGraphics.roc


# BUNDLE
# roc build --bundle .tar.br platform/main.roc

# FROM roc-lang/roc/crates/compiler/roc_target/src/lib.rs
#[strum(serialize = "linux-x32")] 
#[strum(serialize = "linux-x64")]
#[strum(serialize = "linux-arm64")]
#[strum(serialize = "macos-x64")]
#[strum(serialize = "macos-arm64")]
#[strum(serialize = "windows-x32")]
#[strum(serialize = "windows-x64")]
#[strum(serialize = "windows-arm64")]
#[strum(serialize = "wasm32")]