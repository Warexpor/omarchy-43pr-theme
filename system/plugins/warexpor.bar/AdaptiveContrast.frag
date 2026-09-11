#version 440

layout(location = 0) in vec2 qt_TexCoord0;
layout(location = 0) out vec4 fragColor;

layout(std140, binding = 0) uniform buf {
    mat4 qt_Matrix;
    float qt_Opacity;
    float threshold;
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

    vec3 wall = texture(wallpaper, qt_TexCoord0).rgb;
    float lum = dot(wall, vec3(0.2126, 0.7152, 0.0722));
    vec3 unpremul = glyph.rgb / coverage;
    float weight = max(unpremul.r, max(unpremul.g, unpremul.b));
    vec3 ink = lum > threshold ? vec3(0.0) : vec3(1.0);
    float a = coverage * weight;
    fragColor = vec4(ink * a, a) * qt_Opacity;
}
