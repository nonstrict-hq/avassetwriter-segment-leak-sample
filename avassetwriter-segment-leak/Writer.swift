//
//  Writer.swift
//  avassetwriter-segment-leak
//
//  Created by Nonstrict on 13/03/2023.
//

import Foundation
import AVFoundation

/// Writer that uses an AVAssetWriter to get segmented data from the sample buffers appended to it
final class Writer {
    private let assetWriter: AVAssetWriter
    private let assetWriterInput: AVAssetWriterInput

    let delegate: AVAssetWriterDelegate
    
    init(dimensions: CMVideoDimensions, delegate: AVAssetWriterDelegate) {
        self.delegate = delegate

        assetWriter = AVAssetWriter(contentType: .mpeg4Movie)
        assetWriter.outputFileTypeProfile = .mpeg4AppleHLS
        assetWriter.preferredOutputSegmentInterval = CMTime(seconds: 2, preferredTimescale: 1)
        assetWriter.initialSegmentStartTime = .zero
        assetWriter.delegate = delegate
        
        assetWriterInput = AVAssetWriterInput(mediaType: .video, outputSettings: [
            AVVideoCodecKey: AVVideoCodecType.h264,
            AVVideoWidthKey: dimensions.width,
            AVVideoHeightKey: dimensions.height,
        ])
        assetWriterInput.expectsMediaDataInRealTime = true
        
        if assetWriter.canAdd(assetWriterInput) {
            assetWriter.add(assetWriterInput)
        } else {
            fatalError("Unable to add input to writer.")
        }
        
        assetWriter.startWriting()
        assetWriter.startSession(atSourceTime: .zero)
    }
    
    func append(_ sampleBuffer: CMSampleBuffer) {
        if assetWriterInput.isReadyForMoreMediaData {
            assetWriterInput.append(sampleBuffer)
        }

        if let assetWriterError = assetWriter.error {
            fatalError("Asset writer failed with error: \(assetWriterError)")
        }
    }
}

final class LeakingDelegate: NSObject, AVAssetWriterDelegate {
    func assetWriter(_ writer: AVAssetWriter, didOutputSegmentData segmentData: Data, segmentType: AVAssetSegmentType, segmentReport: AVAssetSegmentReport?) {
        print("[LeakingDelegate] Got a segment of size:", segmentData.count)
    }
}

final class DeallocatingDelegate: NSObject, AVAssetWriterDelegate {
    func assetWriter(_ writer: AVAssetWriter, didOutputSegmentData segmentData: Data, segmentType: AVAssetSegmentType, segmentReport: AVAssetSegmentReport?) {
        print("[DeallocatingDelegate] Got a segment of size:", segmentData.count)

        if #available(macOS 13.3, *) {
            // Leak is fixed, DO NOT deallocate manually as this will result in a crash
            print("[DeallocatingDelegate] Skipping manual deallocation, we're on a too recent version of macOS.")
        } else {
            // Deallocate manually when on leaking OS versions
            segmentData.withUnsafeBytes { raw in raw.baseAddress?.deallocate() }
        }
    }
}

let printBoxedSegmentDataInfoDelegateInstance = SegmentDataSafelyBridgedToSwiftDelegate()
final class SegmentDataSafelyBridgedToSwiftDelegate: NSObject, BoxingAssetWriterDelegate {
    func assetWriter(_ writer: AVAssetWriter, didOutputSegmentData segmentData: BoxedSegmentData, segmentType: AVAssetSegmentType, segmentReport: AVAssetSegmentReport?) {
        print("[SegmentDataSafelyBridgedToSwiftDelegate] Got a segment of size:", segmentData.length)
    }
}
