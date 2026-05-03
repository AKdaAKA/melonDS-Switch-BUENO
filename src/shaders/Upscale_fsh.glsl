// Fragment shader for the upscale pass.
// Receives a [0,1] UV from UpscaleQuad_vsh and samples the native-res
// FinalFramebuffer (RGBA8_Unorm) directly. No gl_FragCoord math needed.
#version 460

layout(binding = 0) uniform sampler2D SourceFb;
layout(location = 0) in  vec2 vTexCoord;
layout(location = 0) out vec4 FinalColor;

void main()
{
    FinalColor = texture(SourceFb, vTexCoord);
}
