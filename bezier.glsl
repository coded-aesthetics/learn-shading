precision mediump float;

float Circle(vec2 p, vec2 c, float r) {
    float dist = length(p-c) - r;
    return smoothstep(0.005, 0.0, dist);
}

float Line(vec2 p, vec2 a, vec2 b, float r) {
    vec2 ab = b - a;
    vec2 ap = p - a;
    float t = clamp(dot(ab, ap)/dot(ab, ab),0., 1.);
    return length(ap - ab*t) - r;
}

const int SIZE = 6;

vec2 BezierPointN(vec2[SIZE] ps, float h) {
    int level = SIZE;
    for (int i = 0; i < SIZE; i++) {
        for (int j = 0; j < SIZE; j++) {
            ps[j] = mix(ps[j], ps[j+1], h);
            if (j == SIZE-i-1) break;
        }
    }
    return ps[0];
}

float BezierN(vec2 p, vec2[SIZE] ps, float r) {
    const float NUM_SEGMENTS = 24.;

    float dist = 10000.;
    for (float i = .0; i < NUM_SEGMENTS - 1.; i += 1.) {
        float h1 = i / NUM_SEGMENTS;
        float h2 = (i + 1.) / NUM_SEGMENTS;

        vec2 p1 = BezierPointN(ps, h1);
        vec2 p2 = BezierPointN(ps, h2);

        dist = min(Line(p, p1, p2, r), dist);
    }

    return smoothstep(0.005, 0.0, dist);
}

uniform vec2 u_resolution;
uniform float u_time;

void main() {
    vec2 uv = (2. * gl_FragCoord.xy - u_resolution) / u_resolution.x;

    vec2 a = vec2(-.5);
    vec2 b = vec2(.5);
    vec2 cp1 = vec2(sin(u_time)*1., cos(u_time));
    vec2 cp2 = vec2(cos(u_time*3.0)*.6, sin(u_time*2.)*.7);
    vec2 cp3 = vec2(sin(u_time/7.0)*.8, sin(u_time*4.7)*.9);
    vec2 cp4 = vec2(cos(u_time/7.0)*1.4, sin(u_time/6.7)*1.4);

    vec2 points[SIZE];

    points[0] = a;
    points[1] = cp1;
    points[2] = cp2;
    points[3] = cp3;
    points[4] = cp4;
    points[5] = b;

    float dist = BezierN(uv, points, 0.01);

    vec3 bg = vec3(0.0);
    vec3 fg = vec3(1.0);

    vec3 c1 = vec3(1.0, 0., 0.) * Circle(uv, cp1, 0.04);
    vec3 c2 = vec3(0.0, 0., 1.) * Circle(uv, cp2, 0.04);
    vec3 c3 = vec3(0.0, 1., 0.) * Circle(uv, cp3, 0.04);
    vec3 c4 = vec3(0.0, 1., 1.) * Circle(uv, cp4, 0.04);

    vec3 color = mix(bg, fg, dist) + c1 + c2 + c3 + c4;

    gl_FragColor = vec4(color, 1.0);
}