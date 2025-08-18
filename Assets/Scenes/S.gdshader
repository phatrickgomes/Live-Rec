shader_type spatial;
render_mode unshaded, blend_add;

uniform vec4 color : source_color = vec4(0.0, 0.5, 1.0, 1.0);
uniform float pulse_speed = 2.0;

void fragment() {
    float pulse = sin(TIME * pulse_speed) * 0.5 + 0.5;
    vec3 final_color = color.rgb * (pulse + 0.5);
    ALBEDO = vec3(0.0);
    EMISSION = final_color;
    ALPHA = color.a;
}