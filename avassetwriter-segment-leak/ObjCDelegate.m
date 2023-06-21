//
//  ObjCDelegate.m
//  avassetwriter-segment-leak
//
//  Created by Nonstrict on 21/06/2023.
//

#import "ObjCDelegate.h"
@import AVFoundation;

// MARK: -
/// Private extension on the box so we can only touch the actual segment data from ObjC
@interface BoxedSegmentData ()
@property (nonatomic, strong) NSData *data;
@end

// MARK: -
@implementation ObjCDelegate
@synthesize delegate;

- (void)assetWriter:(AVAssetWriter *)writer didOutputSegmentData:(NSData *)segmentData segmentType:(AVAssetSegmentType)segmentType segmentReport:(AVAssetSegmentReport *)segmentReport {
    // Wrap the NSData inside a ObjC object so someone can't accidentally bridge it to Swift and create a leak, but we're still able to pass it around.
    BoxedSegmentData *boxedSegmentData = [[BoxedSegmentData alloc] init];
    boxedSegmentData.data = segmentData;

    // Call the Swift delegate with the BoxedSegmentData
    [delegate assetWriter:writer didOutputSegmentData:boxedSegmentData segmentType:segmentType segmentReport:segmentReport];
}
@end

// MARK: -
@implementation BoxedSegmentData
@synthesize data;

- (NSUInteger)length {
    return data.length;
}
@end
