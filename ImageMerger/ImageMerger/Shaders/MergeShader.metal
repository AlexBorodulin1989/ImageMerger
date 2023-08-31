//
//  Shaders.metal
//  ImageMerger
//
//  Created by Aleksandr Borodulin on 19.06.2023.
//

#include <metal_stdlib>
using namespace metal;

constant bool supportsNonuniformThreadgroups [[ function_constant(0) ]];
kernel void mergeTextures(texture2d<float, access::sample> sourceImage [[texture(0)]],
                          texture2d<float, access::write> destination [[ texture(64) ]],
                          constant uint2& offset [[ buffer(0) ]],
                          uint2 position [[ thread_position_in_grid ]]) {
    const auto textureSize = ushort2(destination.get_width(),
                                     destination.get_height());

    if (!supportsNonuniformThreadgroups) {
        if (position.x >= textureSize.x || position.y >= textureSize.y) {
            return;
        }
    }

    const auto sourceSize = uint2(sourceImage.get_width(),
                                  sourceImage.get_height());

    float4 sourceColor = sourceImage.read(position);

    destination.write(sourceColor, position + offset * sourceSize);
}
