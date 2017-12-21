# DMSSDK

The DMS SDK provides models and classes to work with the ARC DMS system.

## Setup
1. Download the DMS SDK to a folder called `DMSSDK` in the root folder of your project
2. Drag `DMSSDK.xcodeproj` into your project
3. Drag `ThunderRequest.xcodeproj` from `DMSSDK/ThunderRequest` into your project
4. In your project settings press `+` on Embedded binaries and add `DMSSDK.framework` and `ThunderRequest.framework`
5. Add `DMSSDKBaseURL` to the info plist of your main project that the DMSSDK is embedded in
6. Ensure that `DMSSDK.framework` and `ThunderRequest.framework` are listed under the `Target Dependencies` section of your `Build Phases`

## Code Documentation
The documentation for the project is available [here](https://americanredcross.github.io/dmssdk-ios-framework/)

## Usage

### Directory.swift

A model representation of directory data from the DMS. These objects contain a `directories` property and may recurse to any number of levels depending on the content in your DMS.

### ContentManager.swift

Responsible for downloading bundles from your DMS. This controller will use the value of `DMSSDKBaseURL` from your main project’s Info.plist. It feature methods to initialise downloads and get information about available content updates as well as providing data about available languages in your DMS.

### DirectoryManager.swift

By default this manager will look for a structure.json in the `CIEBundle` repository. You can also manually initialise this controller with your own JSON data.

The manager is responsible for converting the JSON into `Directory` objects which can then be used to display DMS content however you wish.

## License
This project is released under the BSD 3-Clause License. See [LICENSE](LICENSE) for details.
