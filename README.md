# DMSSDK

The DMS SDK provides models and classes to work with the ARC DMS system.

## Setup
1. Download the DMS SDK to a folder called `DMSSDK` in the root folder of your project
2. Drag `DMSSDK.xcodeproj` into your project
3. Drag `ThunderRequest.xcodeproj` from `DMSSDK/ThunderRequest` into your project
4. In your project settings press `+` on Embedded binaries and add `DMSSDK.framework and `ThunderRequest.framework`
1. Add `DMSSDKBaseURL` to the info plist of your main project that the DMSSDK is embedded in