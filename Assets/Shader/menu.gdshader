shader_type canvas_item;

uniform sampler2D screen_tex : hint_screen_texture;
uniform vec4 scanline_color : source_color = vec4(0.0, 0.0, 0.0, 1.0);
uniform vec4 flicker_color : source_color = vec4(0.0, 0.0, 0.0, 1.0);
uniform float scanlines_count = 400.0;
uniform float scanlines_intensity = 0.07;
uniform float flicker_speed = 30.0;
uniform float flicker_intensity : hint_range(0.0, 1.0, 0.001) = 0.03;
uniform float color_offset = 1.5;
uniform float blur = 0.15;
uniform float curvature = 0.12; // curvatura da tela
uniform float vignette = 0.5; // escurece bordas
uniform float horizontal_distortion = 0.003; // distorção horizontal leve

void fragment() {
    vec2 uv = SCREEN_UV;

    // Barrel distortion (curvatura da tela)
    vec2 centered = uv - 0.5;
    centered *= 1.0 + curvature * dot(centered, centered);
    uv = centered + 0.5;

    // Leve distorção horizontal aleatória
    uv.x += sin(uv.y * 60.0 + TIME * 5.0) * horizontal_distortion;

    // pegar tamanho do pixel
    vec2 pixel_size = 1.0 / vec2(textureSize(screen_tex, 0));
    float offset = color_offset * pixel_size.x;

    // Chromatic Aberration
    float r = textureLod(screen_tex, uv + vec2(offset, 0.0), blur).r;
    float g = textureLod(screen_tex, uv, blur).g;
    float b = textureLod(screen_tex, uv - vec2(offset, 0.0), blur).b;
    vec4 color = vec4(r, g, b, 1.0);

    // Flicker sutil
    float flicker = (sin(TIME * flicker_speed + uv.y * 20.0) * 0.5 + 0.5) * flicker_intensity;
    color = mix(color, flicker_color, flicker);

    // Scanlines
    float scan = sin(FRAGCOORD.y * scanlines_count * pixel_size.y) * scanlines_intensity;
    color = mix(color, scanline_color, scan);

    // Vinheta nas bordas
    float dist = distance(uv, vec2(0.5, 0.5));
    color.rgb *= smoothstep(0.8, 0.4, dist * (1.0 + vignette));

    COLOR = color;
}
