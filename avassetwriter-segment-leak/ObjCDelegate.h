//
//  ObjCDelegate.h
//  avassetwriter-segment-leak
//
//  Created by Nonstrict on 21/06/2023.
//

#import <Foundation/Foundation.h>
@import AVFoundation;

NS_ASSUME_NONNULL_BEGIN

/// Class that boxes the segment data provided by `AVAssetWriterDelegate` to prevent it accidentally being bridged to Swift and create a memory leak.
@interface BoxedSegmentData : NSObject

@property (readonly, nonatomic) NSUInteger length;

// TODO: Add more methods here if you want to work with the data, for example `writeToURL` could be useful

@end

/// Delegate to implement in Swift to receive boxed segment data boxed.
@protocol BoxingAssetWriterDelegate <NSObject>
- (void)assetWriter:(AVAssetWriter *)writer didOutputSegmentData:(BoxedSegmentData *)segmentData segmentType:(AVAssetSegmentType)segmentType segmentReport:(nullable AVAssetSegmentReport *)segmentReport;
@end

@interface ObjCDelegate : NSObject <AVAssetWriterDelegate>
@property (nonatomic, weak, nullable) NSObject<BoxingAssetWriterDelegate>* delegate;
@end

NS_ASSUME_NONNULL_END
