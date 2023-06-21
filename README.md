# AVAssetWriter leaks segment data when used in Swift

Minimal sample to demonstrate memory is leaked when the `AVAssetWriterDelegate` is implemented in Swift.

All macOS versions since 11 are affected, until Apple fixed it in macOS 13.3 and newer.

## Reproduction conditions

- The `AVAssetWriter` must be configured to output segment data to it's delegate
- The `AVAssetWriterDelegate` must be implemented in Swift
- The app must run on macOS version 13.2.1 or older

## Demonstrating the issue

This repository contains a sample app demonstrating the issue:
- Open the sample project
- Build & run the app
- Hit the "Start" button for one of the variants

You will see the memory steadily increasing when hitting the "Start with leak" button, the other buttons demonstrate a variant with a workaround. You will see the memory usage stabilize after a moment when clicking these buttons.

## Workaround

- Use Objective-C to implement the `AVAssetWriterDelegate` and box the segment data so it's never bridged.
- Deallocate the memory yourselves on macOS version that are affected.

## Authors

[Nonstrict B.V.](https://nonstrict.eu), [Mathijs Kadijk](https://github.com/mac-cain13) & [Tom Lokhorst](https://github.com/tomlokhorst), released under [MIT License](LICENSE.md).
