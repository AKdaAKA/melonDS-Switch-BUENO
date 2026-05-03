// Vertex shader for the upscale pass.
// Outputs a proper [0,1] UV to the fragment shader so the fsh never needs
// to know the output dimensions — it just samples SourceFb at vTexCoord.
// V is flipped (1-y) because deko3d framebuffers have origin at bottom-left
// while NDC Y=-1 maps to the screen top row.
#version 460

const vec4 Positions[4] = vec4[](
    vec4(-1.0, -1.0, 0.5, 1.0),
    vec4( 1.0, -1.0, 0.5, 1.0),
    vec4(-1.0,  1.0, 0.5, 1.0),
    vec4( 1.0,  1.0, 0.5, 1.0)
);

// NDC Y goes -1 (top) → +1 (bottom) in deko3d/Vulkan convention.
// Texture V goes 0 (top) → 1 (bottom).
// NDC (-1,-1) = screen top-left  → UV (0, 0)
// NDC ( 1,-1) = screen top-right → UV (1, 0)
// NDC (-1, 1) = screen bot-left  → UV (0, 1)
// NDC ( 1, 1) = screen bot-right → UV (1, 1)
const vec2 TexCoords[4] = vec2[](
    vec2(0.0, 1.0),
    vec2(1.0, 1.0),
    vec2(0.0, 0.0),
    vec2(1.0, 0.0)
);

layout(location = 0) out vec2 vTexCoord;

void main()
{
    gl_Position = Positions[gl_VertexID];
    vTexCoord   = TexCoords[gl_VertexID];
}
