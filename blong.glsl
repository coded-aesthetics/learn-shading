precision mediump float;

float Sphere(vec3 p, vec3 c, float r) {
    return length(p-c)-r;
}

float Plane(vec3 p, vec3 n, float d) {
    return dot(p, n) + d;
}

float Circle(vec2 p, vec2 c, float r) {
    float dist = length(p-c) - r;

    return smoothstep(0.01, 0.0, dist);
}

float map(vec3 p) {
    return min(Sphere(p, vec3(.0), 1.0), Plane(p, vec3(-1.0), 3.0));
}

const float MAX_TRAVEL = 128.0;
const int MAX_ITER = 64;
const float MIN_DIST = 0.01;

float ray_march(vec3 p, vec3 dir) {
    float dist = .0;

    for (int i = 0; i < MAX_ITER; i++) {
        vec3 cur_p = p + dist * dir;
        float cur_dist = map(cur_p);

        if (cur_dist < MIN_DIST) {
            break;
        }

        dist += cur_dist;

        if (dist > MAX_TRAVEL) {
            break;
        }
    }

    return dist;
}

vec3 get_normal(vec3 p) {
    vec2 d = vec2(0.01, 0.0);
    float dx = map(p+d.xyy) - map(p-d.xyy);
    float dy = map(p+d.yxy) - map(p-d.yxy);
    float dz = map(p+d.yyx) - map(p-d.yyx);

    return normalize(vec3(dx, dy, dz));
}

float diffuse(vec3 normal, vec3 rel_light_pos) {
    return max(dot(normalize(rel_light_pos), normal), 0.0);
}

float specular(vec3 view_dir, vec3 rel_light_pos, vec3 normal) {
    vec3 r = reflect(normalize(-rel_light_pos), normal);
    float strength = max(dot(normalize(view_dir), r), 0.0);
    return pow(strength, 32.0);
}

float blinn(vec3 cc, vec3 p_on_obj, vec3 rel_light_pos, vec3 normal) {
    // this is the direction the light hit the currentposition on the object
    // for a parallel light source that is infinitely far away, this is just the relative light position
    // when using a point light source this needs to be calculated as p_on_obj - point_light_source
    vec3 s = normalize(rel_light_pos);
    vec3 v = normalize(cc-p_on_obj);
    vec3 h = normalize(s + v);
    float strength = max(dot(h, normal), 0.0);
    return pow(strength, 32.0);
}

uniform vec2 u_resolution;

uniform float u_time;

void main() {
    vec2 uv = (2.0 * gl_FragCoord.xy - u_resolution) / u_resolution.y;

    vec3 cam = vec3(0.0, 0.0, -3.0);
    vec3 cam_plane = vec3(uv, -2.0);

    vec3 rd = normalize(cam_plane - cam);

    vec3 rel_light_pos = vec3(sin(u_time)*-1.0, .0, cos(u_time)*-1.0);

    float dist = ray_march(cam, rd);

    vec3 point_on_obj = cam + dist * rd;
    vec3 normal = get_normal(point_on_obj);
    float diffuse_strength = diffuse(normal, rel_light_pos);
    float specular_strength = specular(cam, rel_light_pos, normal);
    float blinn_strength = blinn(cam,point_on_obj, rel_light_pos, normal);



    vec3 color = vec3(1.0) * (0.75* diffuse_strength + 0.25*specular_strength);

    if (fract(u_time) > 0.0) {
        color = vec3(1.0) * (0.75* diffuse_strength + 0.25*blinn_strength);
    }

    if (dist > MAX_TRAVEL) {
        color = vec3(0.0);
    }

    gl_FragColor = vec4(color, 1.0);
}