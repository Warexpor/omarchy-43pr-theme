#version 440

// Isolate a glyph by expanding along the bar until a coverage gap, then one
// coverage-weighted midline wallpaper sample for that run. Trailing clock
// digits no longer inherit votes from the previous digit.

layout(location = 0) in vec2 qt_TexCoord0;
layout(location = 0) out vec4 fragColor;

layout(std140, binding = 0) uniform buf {
    mat4 qt_Matrix;
    float qt_Opacity;
    float threshold;
    float vertical;
    float pixelWidth;
    float pixelHeight;
};

layout(binding = 1) uniform sampler2D source;
layout(binding = 2) uniform sampler2D wallpaper;

void main() {
    vec4 glyph = texture(source, qt_TexCoord0);
    float coverage = glyph.a;
    if (coverage < 0.001) {
        fragColor = vec4(0.0);
        return;
    }

    const int RA = 22; // along-bar radius (glyph isolation)
    const int RC = 10; // cross-bar radius (glyph height/width)
    const float COL_EPS = 0.18;

    // Unit steps: along the bar (primary) and across it (secondary).
    vec2 along = mix(vec2(pixelWidth, 0.0), vec2(0.0, pixelHeight), vertical);
    vec2 across = mix(vec2(0.0, pixelHeight), vec2(pixelWidth, 0.0), vertical);

    float cols[45]; // da -22..+22
    for (int da = -RA; da <= RA; ++da) {
        float w = 0.0;
        for (int dc = -RC; dc <= RC; dc += 2) {
            vec2 uv = qt_TexCoord0 + along * float(da) + across * float(dc);
            if (uv.x < 0.0 || uv.x > 1.0 || uv.y < 0.0 || uv.y > 1.0)
                continue;
            w += texture(source, uv).a;
        }
        cols[da + RA] = w;
    }

    int lo = 0;
    for (int da = -1; da >= -RA; --da) {
        if (cols[da + RA] < COL_EPS)
            break;
        lo = da;
    }
    int hi = 0;
    for (int da = 1; da <= RA; ++da) {
        if (cols[da + RA] < COL_EPS)
            break;
        hi = da;
    }

    float lumAcc = 0.0;
    float wAcc = 0.0;
    for (int da = lo; da <= hi; ++da) {
        float cw = cols[da + RA];
        if (cw < COL_EPS)
            continue;
        vec2 mid = qt_TexCoord0 + along * float(da);
        vec2 wallUv = mix(vec2(mid.x, 0.5), vec2(0.5, mid.y), vertical);
        wallUv = clamp(wallUv, vec2(0.0), vec2(1.0));
        float lum = dot(texture(wallpaper, wallUv).rgb, vec3(0.2126, 0.7152, 0.0722));
        lumAcc += lum * cw;
        wAcc += cw;
    }

    float lum = wAcc > 0.0
        ? (lumAcc / wAcc)
        : dot(texture(wallpaper, mix(vec2(qt_TexCoord0.x, 0.5), vec2(0.5, qt_TexCoord0.y), vertical)).rgb,
              vec3(0.2126, 0.7152, 0.0722));
    bool lightBg = lum > threshold;

    vec3 unpremul = glyph.rgb / max(coverage, 0.001);
    float weight = max(unpremul.r, max(unpremul.g, unpremul.b));
    vec3 ink = lightBg ? vec3(0.0) : vec3(1.0);
    float a = coverage * weight;
    fragColor = vec4(ink * a, a) * qt_Opacity;
}
