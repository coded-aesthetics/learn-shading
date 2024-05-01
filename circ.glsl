precision mediump float;

float Circle(vec2 p, vec2 center, float radius) {
    float dist = length(p - center);
    return smoothstep(0.005, 0.0, dist-radius);
}

float Line(vec2 p, vec2 a, vec2 b) {
    vec2 ab = b - a;
    vec2 ap = p - a;
    float t = clamp(dot(ab, ap)/dot(ab, ab), 0.0, 1.0);
    vec2 point_projected_on_line = a + t * ab;
    float dist = length(p - point_projected_on_line);
    return smoothstep(0.005, 0.0, dist);
}

uniform vec2 u_resolution;

void main() {
    vec2 uv = (2.0 * gl_FragCoord.xy - u_resolution) / u_resolution.x;

    vec3 foreground_color = vec3(1.0);

    vec3 color = vec3(0.0);
    color += Circle(uv, vec2(0.0), 0.2);
    color += Line(uv, vec2(-0.2), vec2(0.2));

    gl_FragColor = vec4(color, 1.0);
}