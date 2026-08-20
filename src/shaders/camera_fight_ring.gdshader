shader_type canvas_item;

// Color exterior (Blanco sólido por defecto)
uniform vec4 outer_color : source_color = vec4(1.0, 1.0, 1.0, 1.0);

// Radio base del círculo (0.65 es un círculo grande)
uniform float base_radius : hint_range(0.2, 1.5) = 0.65;

// Intensidad del ruido en el borde (reducido a 0.035 para un toque más sutil y limpio)
uniform float noise_intensity : hint_range(0.0, 0.2) = 0.035;

// Escala/frecuencia del ruido alrededor del borde
uniform float noise_scale : hint_range(1.0, 40.0) = 16.0;

// Velocidad del ruido animado
uniform float noise_speed : hint_range(0.0, 20.0) = 4.0;

// Nitidez del borde
uniform float edge_sharpness : hint_range(0.0, 0.05) = 0.005;


// Función de ruido ultra ligera optimizada para GPU
float hash(vec2 p) {
    p = fract(p * vec2(123.34, 456.21));
    p += dot(p, p + 45.32);
    return fract(p.x * p.y);
}

float fast_noise(vec2 p) {
    vec2 i = floor(p);
    vec2 f = fract(p);
    f = f * f * (3.0 - 2.0 * f);

    float a = hash(i);
    float b = hash(i + vec2(1.0, 0.0));
    float c = hash(i + vec2(0.0, 1.0));
    float d = hash(i + vec2(1.0, 1.0));

    return mix(mix(a, b, f.x), mix(c, d, f.x), f.y);
}

void fragment() {
    // Coordenadas centradas en la pantalla (-0.5 a 0.5) corregidas por aspecto
    vec2 uv = UV - vec2(0.5);
    uv.x *= SCREEN_PIXEL_SIZE.y / SCREEN_PIXEL_SIZE.x;

    float dist = length(uv);
    float angle = atan(uv.y, uv.x);

    // Variación de ruido ligera (2 capas rápidas)
    vec2 noise_uv = vec2(angle * noise_scale, TIME * noise_speed);
    float n = fast_noise(noise_uv) * 0.7 + fast_noise(noise_uv * 2.0) * 0.3;

    // Radio con ligera deformación de ruido
    float noisy_radius = base_radius + (n - 0.5) * noise_intensity;

    // Transición filosa: dist < noisy_radius => Transparente, dist >= noisy_radius => Blanco
    float mask = smoothstep(noisy_radius - edge_sharpness, noisy_radius + edge_sharpness, dist);

    COLOR = vec4(outer_color.rgb, mask * outer_color.a);
}
