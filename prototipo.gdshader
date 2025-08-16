shader_type canvas_item;

// Declaração correta da textura da tela
uniform sampler2D screen_texture : hint_screen_texture, filter_linear_mipmap;

uniform float darkness_amount : hint_range(0, 1) = 0.0;
uniform vec4 dark_color : source_color = vec4(0.0, 0.0, 0.0, 0.7);
uniform float vignette_strength : hint_range(0, 1) = 0.5;

void fragment() {
    // Acessa a textura da tela corretamente
    vec4 original_color = texture(screen_texture, SCREEN_UV);

    // Efeito vignette
    vec2 uv = SCREEN_UV - 0.5;
    float vignette = 1.0 - dot(uv, uv) * vignette_strength;

    // Mistura de cores com efeito de escurecimento
    vec4 final_dark_color = dark_color * vignette;
    final_dark_color.a = dark_color.a;

    COLOR = mix(original_color, final_dark_color, darkness_amount);
}