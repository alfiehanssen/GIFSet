# GIFSet

GIFSet is a simple toolset for creating GIFs and GIF-like videos. 

There are two short demo videos [here on YouTube](https://youtu.be/pVTasefaq3Q) and [here on Vimeo](https://vimeo.com/173255845/e4993196a0) (the Vimeo demo has some cool UI in the mix, if you watch one demo, watch the Vimeo demo).

<img src="https://cloud.githubusercontent.com/assets/991059/16546243/08f77946-4112-11e6-9282-54ac8214bac6.gif" width="200">

## Setup

###Cocoapod

Add this to your podfile:

```Ruby
target '{YourTarget}' do
    pod 'GIFSet', '{LatestVersionNumber}'
end
```

###Submodule

`git submodule add git@github.com:alfiehanssen/GIFSet.git` and add the source files to your project/target.

###Framework

`git clone git@github.com:alfiehanssen/GIFSet.git`, open the workspace, build the GIFSet scheme, and add the resulting GIFSet.framework to your project.

## Usage

Check out the [NSOperation](https://developer.apple.com/library/mac/documentation/Cocoa/Reference/NSOperation_class/) subclasses. See them used in the example app in this repo. Briefly, here's what they can do:

1. **GIFOperation:** creates a GIF of a specified duration from an array of images

2. **CompositionOperation:** Creates an [AVMutableComposition](https://developer.apple.com/library/mac/documentation/AVFoundation/Reference/AVMutableComposition_Class/) from an array of [AVAssets](https://developer.apple.com/library/ios/documentation/AVFoundation/Reference/AVAsset_Class/)

3. **ImageExtractionOperation:** Extracts a set of images at specific [CMTimes](https://developer.apple.com/library/mac/documentation/CoreMedia/Reference/CMTime/) from an [AVComposition](https://developer.apple.com/library/ios/documentation/AVFoundation/Reference/AVComposition_Class/index.html)

4. **ImageConcatenationOperation:** Concatenates an array of images into a GIF-like video of a specified duration

5. **VideoGIFFromVideoOperation:** Uses the above operations to create a GIF-like video given an [AVAsset](https://developer.apple.com/library/ios/documentation/AVFoundation/Reference/AVAsset_Class/) (to extract the images from), a number of images to extract, and a duration for the final output 

6. **GIFFromVideoOperation:** Uses the above operations to create a GIF given an [AVAsset](https://developer.apple.com/library/ios/documentation/AVFoundation/Reference/AVAsset_Class/) (to extract the images from), a number of images to extract, and a duration for the final output 

## TODO

- Determine if we can create a GIF-like video by reading and writing the asset using AVAssetReader/Writer. Instead of by extracting images which is time consuming.
- Test videos of various orientations, resolutions
- Unit tests

## Want to Contribute?

If you'd like to contribute, please follow the guidelines found in [CONTRIBUTING](CONTRIBUTING.md).

## Found an Issue?

Please file any and all issues found in this library to the git [issue tracker](https://github.com/alfiehanssen/GIFSet/issues).

## Questions?

Tweet at me here: [@alfiehanssen](https://twitter.com/alfiehanssen).

## License

`GIFSet` is available under the MIT license. See the [LICENSE](LICENSE) file for more info.

## Credits

The video used in the example app was shot by @ghking

The name GIFSet sorta sounds like DIPSET

![alt tag](https://49.media.tumblr.com/2c5825a52d6461d307c5dd6a70a57721/tumblr_n6ugpi4nKy1tdjtr0o1_400.gif)
