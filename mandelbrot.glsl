precision mediump float;

uniform vec2 u_resolution;

uniform float u_time;

const int MAX_ITER = 20;


void main() {
    float zoom = 4.0 + sin(u_time/2.0) * 3.0;
    vec2 uv = (2.0*gl_FragCoord.xy-u_resolution) / u_resolution.y;

    int iterations = 0;
    vec2 z = vec2(sin(u_time/7.0), cos(u_time/3.0));

    for (int i = 0; i < MAX_ITER; i++) {
        float zx = z.x * z.x - z.y *z.y + uv.x;
        z.y = 2.0 * z.x * z.y + uv.y;
        z.x = zx;
        iterations++;

        if (length(z) >= 2.0) break;
    }

      // Colorize based on iteration count
  if (iterations >= MAX_ITER) {
    gl_FragColor = vec4(1.0); // White for infinite points
  } else {
    vec3 color = mix(vec3(sin(u_time/1.7), sin(u_time/1.9), cos(u_time/1.3)), vec3(sin(u_time/1.6), cos(u_time/1.12), 0.0), float(iterations) / float(MAX_ITER));
    gl_FragColor = vec4(color, 1.0); // Color gradient from blue to white
  }
}