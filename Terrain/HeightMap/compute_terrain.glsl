#[compute]
#version 450

// Invocations in the (x, y, z) dimension
layout(local_size_x = 4, local_size_y = 4, local_size_z = 1) in;

// Input the arguments
// A binding to the buffer we create in our script
layout(set = 0, binding = 0, std430) readonly buffer FloatArray {
    float data[];
}
argBuffer;

// Separate buffers for image data
layout (set = 0, binding = 1, r8) restrict uniform readonly image2D noiseImage;
layout (set = 0, binding = 2, rgba8) restrict uniform readonly image2D baseImage;
layout (set = 0, binding = 3, rgba8) restrict uniform writeonly image2D outputImage;

// Output vertices
layout (set = 0, binding = 4, std430) writeonly buffer Vector4Array {
    vec4 data[];
}
vertexOutput;

// The code we want to execute in each invocation
void main() {
    // Extract arguments
    float mixValue = argBuffer.data[0];
    ivec2 imageSize = ivec2(argBuffer.data[1], argBuffer.data[2]);

    // Get pos and inputs per pos
    ivec2 pos = ivec2(gl_GlobalInvocationID.xy);
    float noiseHeight = imageLoad(noiseImage, pos).r;
    float baseHeight = imageLoad(baseImage, pos).r;

    // Generate outputs
    float newHeight = mix(noiseHeight, baseHeight, mixValue);
    vec4 newColor = vec4(vec3(noiseHeight), 1.0);

    // Store outputs
    imageStore(outputImage, pos, newColor);
    vertexOutput.data[pos.y * imageSize.x + pos.x] = vec4(
        (imageSize.x / 2) - pos.x,
        newHeight,
        (imageSize.y / 2) - pos.y,
        0.0
    );
    }