//
//  ContentViewModel.swift
//  ImageMerger
//
//  Created by Aleksandr Borodulin on 19.06.2023.
//

import Foundation
import CoreGraphics
import MetalKit

extension ContentViewModel {
    enum Error: Swift.Error {
        case commandQueueCreationFailed
    }
}

final class ContentViewModel: ObservableObject {
    @Published var image: CGImage?

    private let device: MTLDevice
    private let commandQueue: MTLCommandQueue
    private let textureManager: TextureManager
    private let mergeImages: MergeImages
    private var texturePair: (source: MTLTexture, destinatition: MTLTexture)?

    init() {
        guard let device = MTLCreateSystemDefaultDevice()
        else {
            fatalError("Cannot create device")
        }
        self.device = device

        do {
            let library = try device.makeDefaultLibrary(bundle: .main)
            guard let commandQueue = device.makeCommandQueue()
            else { throw Error.commandQueueCreationFailed }
            self.commandQueue = commandQueue
            self.mergeImages = try .init(library: library)
            self.textureManager = .init(device: device)
        } catch {
            fatalError(error.localizedDescription)
        }

        DispatchQueue.main.async { [weak self] in
            self?.merge()
        }
    }

    func merge() {
        let texture = Texture(device: self.device, imageName: "1-0-0.png")
        let source = texture.mtlTexture
        guard let destination = try? self.textureManager.matchingTexture(to: source, usage: .shaderWrite)
        else {
            return
        }

        self.texturePair = (source, destination)
        self.compute()
    }

    private func compute() {
        guard let source = self.texturePair?.source,
              let destination = self.texturePair?.destinatition,
              let commandBuffer = self.commandQueue.makeCommandBuffer()
        else {
            return
        }

        self.mergeImages.encode(source: source, destination: destination, in: commandBuffer)

        commandBuffer.addCompletedHandler { _ in
            guard let cgImage = try? self.textureManager.cgImage(from: destination)
            else {
                return
            }

            DispatchQueue.main.async {
                self.image = cgImage
            }
        }

        commandBuffer.commit()
    }
}
