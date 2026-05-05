// Fragment shader for the upscale pass.
// Receives a [0,1] UV from UpscaleQuad_vsh and samples the native-res
// FinalFramebuffer (RGBA8_Unorm) directly. No gl_FragCoord math needed.
#version 460

layout(binding = 0) uniform sampler2D SourceFb;
layout(location = 0) in  vec2 vTexCoord;
layout(location = 0) out vec4 FinalColor;

// xBR parameters
const float XBR_SCALE = 4.0;
const float XBR_EQ_THRESHOLD = 15.0;

const vec3 rgbw = vec3(14.352, 28.176, 5.472);

const vec4 Ao = vec4( 1.0, -1.0, -1.0, 1.0 );
const vec4 Bo = vec4( 1.0,  1.0, -1.0,-1.0 );
const vec4 Co = vec4( 1.5,  0.5, -0.5, 0.5 );
const vec4 Ax = vec4( 1.0, -1.0, -1.0, 1.0 );
const vec4 Bx = vec4( 0.5,  2.0, -0.5,-2.0 );
const vec4 Cx = vec4( 1.0,  1.0, -0.5, 0.0 );
const vec4 Ay = vec4( 1.0, -1.0, -1.0, 1.0 );
const vec4 By = vec4( 2.0,  0.5, -2.0,-0.5 );
const vec4 Cy = vec4( 2.0,  0.0, -1.0, 0.5 );
const vec4 Ci = vec4(0.25, 0.25, 0.25, 0.25);

vec4 df(vec4 A, vec4 B) { return vec4(abs(A-B)); }
vec4 diff(vec4 A, vec4 B) { return step(vec4(0.001), abs(A-B)); }
vec4 eq(vec4 A, vec4 B) { return (step(df(A, B), vec4(XBR_EQ_THRESHOLD))); }
vec4 neq(vec4 A, vec4 B) { return (vec4(1.0) - eq(A, B)); }
vec4 wd(vec4 a, vec4 b, vec4 c, vec4 d, vec4 e, vec4 f, vec4 g, vec4 h) {
    return (df(a,b) + df(a,c) + df(d,e) + df(d,f) + 4.0*df(g,h));
}
float c_df(vec3 c1, vec3 c2) {
    vec3 d = abs(c1 - c2);
    return d.r + d.g + d.b;
}

void main()
{
    vec2 TextureSize = vec2(256.0, 192.0);
    float dx = 1.0 / TextureSize.x;
    float dy = 1.0 / TextureSize.y;
    
    vec2 texCoord = vTexCoord;
    texCoord.x *= 1.00000001; // Fix precision bounds
    
    vec2 fp = fract(texCoord * TextureSize);
    vec2 tc = (floor(texCoord * TextureSize) + 0.5) / TextureSize; // Center of current texel

    // 21 neighborhood samples
    vec3 A1 = texture(SourceFb, tc + vec2(-dx, -2.0*dy)).xyz;
    vec3 B1 = texture(SourceFb, tc + vec2(  0, -2.0*dy)).xyz;
    vec3 C1 = texture(SourceFb, tc + vec2( dx, -2.0*dy)).xyz;
    vec3 A  = texture(SourceFb, tc + vec2(-dx,     -dy)).xyz;
    vec3 B  = texture(SourceFb, tc + vec2(  0,     -dy)).xyz;
    vec3 C  = texture(SourceFb, tc + vec2( dx,     -dy)).xyz;
    vec3 D  = texture(SourceFb, tc + vec2(-dx,       0)).xyz;
    vec3 E  = texture(SourceFb, tc + vec2(  0,       0)).xyz;
    vec3 F  = texture(SourceFb, tc + vec2( dx,       0)).xyz;
    vec3 G  = texture(SourceFb, tc + vec2(-dx,      dy)).xyz;
    vec3 H  = texture(SourceFb, tc + vec2(  0,      dy)).xyz;
    vec3 I  = texture(SourceFb, tc + vec2( dx,      dy)).xyz;
    vec3 G5 = texture(SourceFb, tc + vec2(-dx,  2.0*dy)).xyz;
    vec3 H5 = texture(SourceFb, tc + vec2(  0,  2.0*dy)).xyz;
    vec3 I5 = texture(SourceFb, tc + vec2( dx,  2.0*dy)).xyz;
    vec3 A0 = texture(SourceFb, tc + vec2(-2.0*dx, -dy)).xyz;
    vec3 D0 = texture(SourceFb, tc + vec2(-2.0*dx,   0)).xyz;
    vec3 G0 = texture(SourceFb, tc + vec2(-2.0*dx,  dy)).xyz;
    vec3 C4 = texture(SourceFb, tc + vec2( 2.0*dx, -dy)).xyz;
    vec3 F4 = texture(SourceFb, tc + vec2( 2.0*dx,   0)).xyz;
    vec3 I4 = texture(SourceFb, tc + vec2( 2.0*dx,  dy)).xyz;

    vec4 b = vec4(dot(B,rgbw), dot(D,rgbw), dot(H,rgbw), dot(F,rgbw));
    vec4 c = vec4(dot(C,rgbw), dot(A,rgbw), dot(G,rgbw), dot(I,rgbw));
    vec4 d = b.yzwx;
    vec4 e = vec4(dot(E,rgbw));
    vec4 f = b.wxyz;
    vec4 g = c.zwxy;
    vec4 h = b.zwxy;
    vec4 i = c.wxyz;

    vec4 i4 = vec4(dot(I4,rgbw), dot(C1,rgbw), dot(A0,rgbw), dot(G5,rgbw));
    vec4 i5 = vec4(dot(I5,rgbw), dot(C4,rgbw), dot(A1,rgbw), dot(G0,rgbw));
    vec4 h5 = vec4(dot(H5,rgbw), dot(F4,rgbw), dot(B1,rgbw), dot(D0,rgbw));
    vec4 f4 = h5.yzwx; // Added missing f4 definition

    vec4 fx   = (Ao*fp.y + Bo*fp.x);
    vec4 fx_l = (Ax*fp.y + Bx*fp.x);
    vec4 fx_u = (Ay*fp.y + By*fp.x);

    vec4 irlv1, irlv0;
    irlv1 = irlv0 = diff(e,f) * diff(e,h);
    
    // CORNER_C logic
    irlv1 = (irlv0 * ( neq(f,b) * neq(f,c) + neq(h,d) * neq(h,g) + eq(e,i) * (neq(f,f4) * neq(f,i4) + neq(h,h5) * neq(h,i5)) + eq(e,g) + eq(e,c)) );

    vec4 irlv2l = diff(e,g) * diff(d,g);
    vec4 irlv2u = diff(e,c) * diff(b,c);

    vec4 delta = vec4(1.0/XBR_SCALE);
    vec4 delta_l = vec4(0.5/XBR_SCALE, 1.0/XBR_SCALE, 0.5/XBR_SCALE, 1.0/XBR_SCALE);
    vec4 delta_u = delta_l.yxwz;

    vec4 fx45i = clamp((fx + delta - Co - Ci)/(2.0*delta), 0.0, 1.0);
    vec4 fx45  = clamp((fx + delta - Co)/(2.0*delta), 0.0, 1.0);
    vec4 fx30  = clamp((fx_l + delta_l - Cx)/(2.0*delta_l), 0.0, 1.0);
    vec4 fx60  = clamp((fx_u + delta_u - Cy)/(2.0*delta_u), 0.0, 1.0);

    vec4 wd1 = wd(e, c, g, i, h5, f4, h, f);
    vec4 wd2 = wd(h, d, i5, f, i4, b, e, i);

    vec4 edri = step(wd1, wd2) * irlv0;
    vec4 edr  = step(wd1 + vec4(0.1), wd2) * step(vec4(0.5), irlv1);
    
    float lv2_cf = 2.0;
    vec4 edr_l = step( lv2_cf*df(f,g), df(h,c) ) * irlv2l * edr;
    vec4 edr_u = step( lv2_cf*df(h,c), df(f,g) ) * irlv2u * edr;

    fx45  = edr   * fx45;
    fx30  = edr_l * fx30;
    fx60  = edr_u * fx60;
    fx45i = edri  * fx45i;

    vec4 px = step(df(e,f), df(e,h));

    // SMOOTH_TIPS logic
    vec4 maximos = max(max(fx30, fx60), max(fx45, fx45i));

    vec3 res1 = E;
    res1 = mix(res1, mix(H, F, px.x), maximos.x);
    res1 = mix(res1, mix(B, D, px.z), maximos.z);

    vec3 res2 = E;
    res2 = mix(res2, mix(F, B, px.y), maximos.y);
    res2 = mix(res2, mix(D, H, px.w), maximos.w);

    vec3 res = mix(res1, res2, step(c_df(E, res1), c_df(E, res2)));

    FinalColor = vec4(res, 1.0);
}
