
# Graphics for Roc 💜

A simple platform for creating 2D images using Roc.

It generates a `.png` image file in the directory where you run `roc run` from.

My goal with this platform is to learn Roc platform dev, and to have a baseline platfrom that demonstrates everything required end-to-end including cross-platform packaging.  

Any PR's or ideas are welcome. Possible future directions include:
- [ ] Add support for other graphics formats (svg etc)
- [ ] Add support for other image formats (write to bmp, jpg etc)

## Example - Build and run locally

If you are running the example locally it will require that you have a prebuilt-platform library located next to the platform `main.roc`. 

If you have `zig version 0.11.0` installed you can build the prebuilt-platform using `bash bundle.sh`. This will cross-compile the platform for all supported platforms and also bundle these into a package for distribution.

Then you can run the example using `roc run --prebuilt-platform examples/rocLovesGraphics.roc`. 

## How to use

The platform main expects a record `Options` which contains basic information for generating an image. The image content is a `Str` and is expecting a [TinyVG](https://tinyvg.tech) in text format. See [roc-tinvyvg](https://github.com/lukewilliamboswell/roc-tinvyvg) package for how to generate this using Roc.

```roc
Options : {
    size ? [Inherit, Set {width : U32, height : U32}],
    title ? Str,
    antiAlias ? [X1, X4, X9, X16, X25],
    content : Str,
}

# E.g.
main = { title: "bird", content: tvgText }
```



