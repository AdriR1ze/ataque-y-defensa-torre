shader_type canvas_item;

uniform vec4 mist_color : source_color = vec4(0.88, 0.89, 0.92, 0.6);
uniform float inner_radius : hint_range(0.1, 1.2) = 0.55;
uniform float outer_radius : hint_range(0.3, 1.8) = 1.1;
uniform float pulse_speed : hint_range(0.0, 5.0) = 1.0;
uniform float pulse_intensity : hint_range(0.0, 0.1) = 0.01;

void fragment() {
    // Coordenadas centradas corregidas por relación de aspecto
    vec2 uv = UV - vec2(0.5);
    uv.x *= SCREEN_PIXEL_SIZE.y / SCREEN_PIXEL_SIZE.x;

    float dist = length(uv);

    // Sutil pulso de respiración de combate
    float pulse = sin(TIME * pulse_speed) * pulse_intensity;
    float current_inner = inner_radius + pulse;
    float current_outer = outer_radius + pulse;

    // Transición ultra suave de transparencia en el centro hacia bruma en las esquinas
    float factor = smoothstep(current_inner, current_outer, dist);

    COLOR = vec4(mist_color.rgb, factor * mist_color.a);
}

