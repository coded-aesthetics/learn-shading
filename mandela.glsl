precision mediump float;

uniform vec2 u_resolution;
const float DEPTH = 100.0;

void main() {
    vec2 uv = (2.*gl_FragCoord.xy-u_resolution)/u_resolution.y;

    vec2 z = vec2(0.0);
    float iterations = .0;

    for (float i = .0; i < DEPTH;i++) {
        float zx = z.x*z.x - z.y*z.y + uv.x;
        z.y = 2.0*z.x*z.y + uv.y;

        z.x = zx;

        ++iterations;
        if (length(z) > 2.) {
            break;
        }
    }

    vec3 bg_color = vec3(1.0);
    vec3 fg_color = vec3(0.0);

    vec3 color = mix(bg_color, fg_color, iterations/DEPTH);

    gl_FragColor = vec4(color, 1.0);
}