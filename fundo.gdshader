shader_type canvas_item;

// Textura da cena
uniform sampler2D screen_tex : hint_screen_texture;

// Scanlines
uniform float scanlines_count = 300.0;
uniform float scanlines_intensity = 0.03;

// Flicker
uniform float flicker_speed = 20.0;
uniform float flicker_intensity : hint_range(0.0,0.1) = 0.03;

// Cromatic Aberration
uniform float color_offset = 1.5;
uniform float blur = 0.1;

// Curvatura da tela
uniform float curvature = 0.05;
uniform float horizontal_distortion = 0.002;

// Ruído/estática fina
uniform float noise_density : hint_range(50.0,500.0) = 250.0;
uniform float noise_intensity : hint_range(0.0,0.05) = 0.02;

float rand(vec2 co){
    return fract(sin(dot(co.xy ,vec2(12.9898,78.233))) * 43758.5453);
}

void fragment() {
    vec2 uv = SCREEN_UV;

    // Curvatura da tela
    vec2 centered = uv - 0.5;
    centered *= 1.0 + curvature * dot(centered, centered);
    uv = centered + 0.5;
    uv.x += sin(uv.y*50.0 + TIME*5.0) * horizontal_distortion;

    vec2 pixel_size = 1.0 / vec2(textureSize(screen_tex,0));
    float offset = color_offset * pixel_size.x;

    // Fundo preto
    vec4 color = vec4(0.0, 0.0, 0.0, 1.0);

    // Chromatic Aberration
    vec3 tex = vec3(
        textureLod(screen_tex, uv + vec2(offset,0.0), blur).r,
        textureLod(screen_tex, uv, blur).g,
        textureLod(screen_tex, uv - vec2(offset,0.0), blur).b
    );

    color.rgb = tex * 1.0;

    // Flicker irregular
    float f = (sin(TIME*flicker_speed + uv.y*20.0)*0.5+0.5) * flicker_intensity;
    color.rgb += f;

    // Scanlines horizontais
    float scan = sin(FRAGCOORD.y * scanlines_count * pixel_size.y) * scanlines_intensity;
    color.rgb -= scan;

    // Ruído/estática fina (sem círculos)
    float n = rand(uv * noise_density + TIME*5.0);
    color.rgb += (n - 0.5) * noise_intensity;

    COLOR = color;
}
