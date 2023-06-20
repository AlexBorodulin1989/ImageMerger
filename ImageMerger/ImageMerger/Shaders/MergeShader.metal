//
//  Shaders.metal
//  ImageMerger
//
//  Created by Aleksandr Borodulin on 19.06.2023.
//

#include <metal_stdlib>
using namespace metal;

constant bool supportsNonuniformThreadgroups [[ function_constant(0) ]];
kernel void mergeTextures(array<texture2d<float, access::sample>, 4> sourceImages [[texture(0)]],
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

    uint2 offset = uint2(position.x / texturePieceSize.x, position.y / texturePieceSize.y);

    float4 color = sourceImages[offset.x + offset.y * 2].read(position - uint2(texturePieceSize.x * offset.x, texturePieceSize.y * offset.y));

    destination.write(color, position);
}
