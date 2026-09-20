#version 440

// Force monochrome bar coverage to white. Crisp black outline is drawn in QML
// as four 1px colorized offsets under this pass. Colored tray pixels keep RGB.

layout(location = 0) in vec2 qt_TexCoord0;
layout(location = 0) out vec4 fragColor;

layout(std140, binding = 0) uniform buf {
    mat4 qt_Matrix;
    float qt_Opacity;
};

layout(binding = 1) uniform sampler2D source;

void main() {
    vec4 glyph = texture(source, qt_TexCoord0);
    float coverage = glyph.a;
    if (coverage < 0.001) {
        fragColor = vec4(0.0);
        return;
    }

    const float CHROMA_EPS = 0.06;
    vec3 unpremul = glyph.rgb / max(coverage, 0.001);
    float mx = max(unpremul.r, max(unpremul.g, unpremul.b));
    float mn = min(unpremul.r, min(unpremul.g, unpremul.b));

    if ((mx - mn) > CHROMA_EPS) {
        fragColor = glyph * qt_Opacity;
    } else {
        fragColor = vec4(vec3(1.0) * coverage, coverage) * qt_Opacity;
    }
}
