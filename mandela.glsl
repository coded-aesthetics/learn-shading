precision mediump float;

uniform vec2 u_resolution;
uniform vec2 u_mouse;
uniform float u_time;
const int MAX_ITER = 500;

void main() {

    float zoom = 10.0;
    
    vec2 mouse = (2.0 * u_mouse.xy - u_resolution) / u_resolution.y * zoom;

    vec2 uv = (2.0 * gl_FragCoord.xy - u_resolution) / u_resolution.y + mouse;
    uv /= zoom;
    int iterations = 0;

    vec2 z = vec2(.0);

    for (int i = 0; i < MAX_ITER; i++) {
        float zx = z.x * z.x - z.y * z.y + uv.x;
        z.y = 2.0 * z.x * z.y + uv.y;
        z.x = zx;

        if (length(z) > 2.0) {
            break;
        }

        ++iterations;
    }
    vec3 c1 = vec3(1.0);
    vec3 c2 = vec3(0.0, 0.9725, 0.7961);

    if (iterations >= MAX_ITER) {
        gl_FragColor=vec4(1.0);
    } else {
        gl_FragColor = vec4(mix(c2, c1, float(iterations) / float(MAX_ITER)), 1.0);
    }
}