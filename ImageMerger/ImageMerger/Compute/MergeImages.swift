//
//  MergeImages.swift
//  ImageMerger
//
//  Created by Aleksandr Borodulin on 19.06.2023.
//

import Metal

final class MergeImages {

    private var deviceSupportsNonuniformThreadgroups: Bool
    private let pipelineState: MTLComputePipelineState

    init(library: MTLLibrary) throws {
        self.deviceSupportsNonuniformThreadgroups = library.device.supportsFamily(.apple4)
        let constantValues = MTLFunctionConstantValues()
        constantValues.setConstantValue(&self.deviceSupportsNonuniformThreadgroups,
                                        type: .bool,
                                        index: 0)

        let function = try library.makeFunction(name: "mergeTextures",
                                                constantValues: constantValues)

        self.pipelineState = try library.device.makeComputePipelineState(function: function)
    }

    func encode(sourceImages: [MTLTexture],
                destination: MTLTexture,
                in commandBuffer: MTLCommandBuffer) {

        for index in 0..<sourceImages.count {
            let image = sourceImages[index]
            guard let encoder = commandBuffer.makeComputeCommandEncoder()
            else {
                return
            }

            encoder.setTexture(image, index: 0)

            encoder.setTexture(destination,
                               index: 1)

            var offset = SIMD2<uint>(uint(index % 16), uint(index / 16))

            encoder.setBytes(&offset,
                             length: MemoryLayout<SIMD2<uint>>.stride,
                             index: 0)

            let gridSize = MTLSize(width: destination.width,
                                   height: destination.height,
                                   depth: 1)

            let threadGroupWidth = self.pipelineState.threadExecutionWidth
            let threadGroupHeight = self.pipelineState.maxTotalThreadsPerThreadgroup / threadGroupWidth
            let threadGroupSize = MTLSize(width: threadGroupWidth,
                                          height: threadGroupHeight,
                                          depth: 1)
            encoder.setComputePipelineState(self.pipelineState)

            if self.deviceSupportsNonuniformThreadgroups {
                encoder.dispatchThreads(gridSize,
                                        threadsPerThreadgroup: threadGroupSize)
            } else {
                let threadGroupCount = MTLSize(width: (gridSize.width + threadGroupWidth - 1) / threadGroupSize.width,
                                               height: (gridSize.height + threadGroupSize.height - 1) / threadGroupSize.height,
                                               depth: 1)
                encoder.dispatchThreadgroups(threadGroupCount,
                                             threadsPerThreadgroup: threadGroupSize)
            }

            encoder.endEncoding()
        }
    }
}
