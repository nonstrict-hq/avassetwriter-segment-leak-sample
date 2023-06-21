//
//  ContentView.swift
//  avassetwriter-segment-leak
//
//  Created by Nonstrict on 21/06/2023.
//

import SwiftUI
import AVFoundation

struct ContentView: View {
    @State private var isRunning = false

    var body: some View {
        VStack {
            if #available(macOS 13.3, *) {
                Text("\(Image(systemName: "exclamationmark.triangle")) You're running macOS 13.3 or newer, the leak has been fixed in this version of macOS.")
                    .foregroundColor(.red)
            }

            HStack(alignment: .top) {
                VStack {
                    Button("Start with leak") {
                        start(using: LeakingDelegate())
                    }
                    .disabled(isRunning)
                    Text("Leaks segment data on on macOS 13.2 and earlier.")
                }
                .frame(maxWidth: 200)

                VStack {
                    Button("Start with ObjC delegate") {
                        let objcDelegate = ObjCDelegate()
                        objcDelegate.delegate = printBoxedSegmentDataInfoDelegateInstance
                        start(using: objcDelegate)
                    }
                    .disabled(isRunning)
                    Text("ObjC delegate that boxes segment data prevents leak.")
                }
                .frame(maxWidth: 200)

                VStack {
                    Button("Start with deallocation") {
                        start(using: DeallocatingDelegate())
                    }
                    .disabled(isRunning)
                    Text("Delegate that deallocates segment data itself.")
                }
                .frame(maxWidth: 200)
            }
            .padding()

            if #available(macOS 12, *) {
                TimelineView(.periodic(from: .now, by: 1)) { _ in
                    Text("Memory usage: \(memoryFootprint().formatted(.byteCount(style: .memory)))")
                }
            }
        }
        .padding()
    }

    func start(using delegate: AVAssetWriterDelegate) {
        isRunning = true
        Task.detached {
            let source = SampleBufferSource()
            let writer = Writer(dimensions: source.dimensions, delegate: delegate)
            source.start { sampleBuffer in
                writer.append(sampleBuffer)
            }
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}

// From https://stackoverflow.com/a/40992791/586489
private func memoryFootprint() -> UInt64 {
    // The `TASK_VM_INFO_COUNT` and `TASK_VM_INFO_REV1_COUNT` macros are too
    // complex for the Swift C importer, so we have to define them ourselves.
    let TASK_VM_INFO_COUNT = mach_msg_type_number_t(MemoryLayout<task_vm_info_data_t>.size / MemoryLayout<integer_t>.size)
    guard let offset = MemoryLayout.offset(of: \task_vm_info_data_t.min_address) else {return 0}
    let TASK_VM_INFO_REV1_COUNT = mach_msg_type_number_t(offset / MemoryLayout<integer_t>.size)
    var info = task_vm_info_data_t()
    var count = TASK_VM_INFO_COUNT
    let kr = withUnsafeMutablePointer(to: &info) { infoPtr in
        infoPtr.withMemoryRebound(to: integer_t.self, capacity: Int(count)) { intPtr in
            task_info(mach_task_self_, task_flavor_t(TASK_VM_INFO), intPtr, &count)
        }
    }
    guard
        kr == KERN_SUCCESS,
        count >= TASK_VM_INFO_REV1_COUNT
    else { return 0 }

    let usedBytes = Float(info.phys_footprint)
    let usedBytesInt: UInt64 = UInt64(usedBytes)
    return usedBytesInt
}
