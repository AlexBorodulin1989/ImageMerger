//
//  Shaders.metal
//  ImageMerger
//
//  Created by Aleksandr Borodulin on 19.06.2023.
//

#include <metal_stdlib>
using namespace metal;

constant bool supportsNonuniformThreadgroups [[ function_constant(0) ]];
kernel void mergeTextures(texture2d<float, access::read> source1 [[ texture(0) ]],
                          texture2d<float, access::read> source2 [[ texture(1) ]],
                          texture2d<float, access::read> source3 [[ texture(2) ]],
                          texture2d<float, access::read> source4 [[ texture(3) ]],
                          texture2d<float, access::write> destination [[ texture(4) ]],
                          uint2 position [[ thread_position_in_grid ]]) {
    const auto textureSize = ushort2(destination.get_width(),
                                     destination.get_height());

    if (!supportsNonuniformThreadgroups) {
        if (position.x >= textureSize.x || position.y >= textureSize.y) {
            return;
        }
    }

    ushort2 texturePieceSize = textureSize / 2;

    if (position.x < texturePieceSize.x && position.y < texturePieceSize.y) {
        const auto sourceValue = source1.read(position);
        destination.write(sourceValue, position);
    } else if (position.x >= texturePieceSize.x && position.y < texturePieceSize.y) {
        const auto sourceValue = source2.read(position - uint2(texturePieceSize.x, 0));
        destination.write(sourceValue, position);
    } else if (position.x < texturePieceSize.x && position.y >= texturePieceSize.y) {
        const auto sourceValue = source3.read(position - uint2(0, texturePieceSize.y));
        destination.write(sourceValue, position);
    } else if (position.x >= texturePieceSize.x && position.y >= texturePieceSize.y) {
        const auto sourceValue = source4.read(position - uint2(texturePieceSize.x, texturePieceSize.y));
        destination.write(sourceValue, position);
    }
}
