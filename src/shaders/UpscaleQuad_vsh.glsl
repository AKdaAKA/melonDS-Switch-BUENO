#version 460
const vec4 Positions[4] = vec4[](
    vec4(-1.0, -1.0, 0.5, 1.0),
    vec4( 1.0, -1.0, 0.5, 1.0),
    vec4(-1.0,  1.0, 0.5, 1.0),
    vec4( 1.0,  1.0, 0.5, 1.0)
);
const vec2 TexCoords[4] = vec2[](
    vec2(0.0, 0.0),
    vec2(1.0, 0.0),
    vec2(0.0, 1.0),
    vec2(1.0, 1.0)
);
layout(location = 0) out vec2 vTexCoord;
void main()
{
    gl_Position = Positions[gl_VertexID];
    vTexCoord   = TexCoords[gl_VertexID];
}
