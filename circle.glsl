precision mediump float;

uniform vec2 u_resolution;
uniform float u_time;
uniform vec2 u_mouse;

float Circle(vec2 p, vec2 center, float radius) {
    float dist = length(center - p);
    return smoothstep(0.005, 0.0, dist - radius);
}

float Line(vec2 p, vec2 a, vec2 b) {
    vec2 ab = b - a;
    vec2 ap = p - a;
    float t = clamp((dot(ab, ap)/dot(ab, ab)), 0.0, 1.0);
    vec2 p_projected_onto_line = a + t*ab;
    float dist_of_p_to_line = length(p - p_projected_onto_line);
    float width = 0.001;
    return smoothstep(0.005, 0.0, dist_of_p_to_line - width);
}

vec2 Bezier(vec2 posA, vec2 posB, vec2 mouse, float t) {
    vec2 posD = posA + t* (mouse - posA);
    vec2 posE = mouse + t* (posB - mouse);
    return posD + t * (posE-posD);
}

void main() {
    vec2 uv = (2.0 * gl_FragCoord.xy - u_resolution) / u_resolution.x;

    vec2 mouse = (2.0 * u_mouse.xy - u_resolution)/u_resolution.x;

    vec2 posA = vec2(-.5);
    vec2 posB = vec2(.5);

    float C = Circle(uv, mouse, 0.04);
    float A = Circle(uv, posA, 0.04);
    float B = Circle(uv, posB, 0.04);

    float AB = Line(uv, posA, posB);
    float AC = Line(uv, posA, mouse);
    float CB = Line(uv, mouse, posB);

    float t = sin(u_time) * .5 + .5;

    vec2 posD = posA + t* (mouse - posA);
    float D = Circle(uv, posD, 0.04);

    vec2 posE = mouse + t* (posB - mouse);
    float E = Circle(uv, posE, 0.04);

    float DE = Line(uv, posD, posE);

    vec2 posF = posD + t * (posE-posD);
    float F = Circle(uv, posF, 0.04);

    vec3 col = vec3(0.0);
    // col += AC * vec3(1);
    // col += CB * vec3(1);
    // col += AB * vec3(1);
    //col += DE * vec3(1);
    col += C * vec3(1,0,0);
    col += A * vec3(0,1,0);
    col += B * vec3(0,0,1);
    // col += D * vec3(1,1,0);
    // col += E * vec3(0,1,1);
    //col += F * vec3(1);

    const int LINE_SEGMENTS = 15;

    for (int i = 1; i <= LINE_SEGMENTS; i++) {
        vec2 p1 = Bezier(posA, posB, mouse, float(i-1)/float(LINE_SEGMENTS));
        vec2 p2 = Bezier(posA, posB, mouse, float(i)/float(LINE_SEGMENTS));
        col += Line(uv, p1, p2);
    }

    gl_FragColor = vec4(col, 1.0);
}