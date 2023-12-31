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
    private var texturePair: (sourceImages: [MTLTexture], destinatition: MTLTexture)?

    let zoom = 3

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
        var textures = [MTLTexture]()

        for i in 0..<NSDecimalNumber(decimal: pow(2, zoom)).intValue {
            for c in 0..<NSDecimalNumber(decimal: pow(2, zoom)).intValue {
                textures.append(Texture(device: self.device, imageName: "\(zoom)-\(c)-\(i)_rect.png").mtlTexture)
            }
        }

        let firstTexture = textures.first!

        let eps: Double = 0.0001

        let dimensionSize = Int(sqrt(Double(textures.count) + eps))

        guard let destination = try? self.textureManager.matchingTexture(to: firstTexture,
                                                                         width: firstTexture.width * dimensionSize,
                                                                         height: firstTexture.height * dimensionSize,
                                                                         usage: .shaderWrite)
        else {
            return
        }

        self.texturePair = (textures, destination)
        self.compute()
    }

    private func compute() {
        guard let source = self.texturePair?.sourceImages,
              let destination = self.texturePair?.destinatition,
              let commandBuffer = self.commandQueue.makeCommandBuffer()
        else {
            return
        }

        self.mergeImages.encode(sourceImages: source, destination: destination, zoom: zoom, in: commandBuffer)

        commandBuffer.addCompletedHandler { _ in
            guard let cgImage = try? self.textureManager.cgImage(from: destination)
            else {
                return
            }

            DispatchQueue.main.async { [self] in
                self.image = cgImage
                let filePath = getDocumentsDirectory().appendingPathComponent("merged.png")
                print(filePath)
                try? cgImage.pngData()?.write(to: filePath)
            }
        }

        commandBuffer.commit()
    }

    func getDocumentsDirectory() -> URL {
        let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        return paths[0]
    }
}

extension CGImage {
    public func pngData() -> Data? {
        let cfdata: CFMutableData = CFDataCreateMutable(nil, 0)
        if let destination = CGImageDestinationCreateWithData(cfdata, kUTTypePNG as CFString, 1, nil) {
            CGImageDestinationAddImage(destination, self, nil)
            if CGImageDestinationFinalize(destination) {
                return cfdata as Data
            }
        }
        
        return nil
    }
}
