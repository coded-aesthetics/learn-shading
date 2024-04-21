precision mediump float;

uniform vec2 u_resolution;
uniform float u_time;

float sdfSphere(vec3 center, float radius, vec3 p) {
    return length(p - center) +-radius;
}



float map(vec3 p) {
    float sphere1 = sdfSphere(vec3(0.0), 1.0, p);
    float sphere2 = sdfSphere(vec3(1.0), 1.0, p);

    return min(sphere1, sphere2);
}

vec3 getNormal(vec3 point_on_surface) {
    vec2 d = vec2(0.01, 0.0);
    float x = map(point_on_surface + d.xyy) - map(point_on_surface - d.xyy);
    float y = map(point_on_surface + d.yxy) - map(point_on_surface - d.yxy);
    float z = map(point_on_surface + d.yyx) - map(point_on_surface - d.yyx);
    return normalize(vec3(x,y,z));
}

float diffuse(vec3 relLightPos, vec3 normal) {
    float diffuseStrength = max(0.0, dot(normalize(relLightPos), normal));
    return diffuseStrength;
}

float specular(vec3 relLightPos, vec3 viewDir, vec3 normal) {
    vec3 ref = reflect(-normalize(relLightPos), normal);
    float stren = max(dot(ref, normalize(viewDir)), 0.0);
    return pow(stren, 32.0);
}


const float MAX_ITERATIONS = 64.0;
const float MAX_TRAVEL_DIST = 128.0;
const float MIN_DIST_TO_OBJ = 0.01;

float ray_march(vec3 ro, vec3 rd) {
    float dist = 0.0;
    for (float i = 0.0; i < MAX_ITERATIONS; i++) {
        vec3 current_pos = ro + dist * rd;
        float min_dist_to_scene = map(current_pos);

        if (min_dist_to_scene < MIN_DIST_TO_OBJ) {
            break;
        }

        dist += min_dist_to_scene;

        if (dist > MAX_TRAVEL_DIST) {
            break;
        }
    }

    return dist;
}

bool shadow(vec3 relLightPos, vec3 point_slightly_above_surface) {
    float dist_to_object = ray_march(point_slightly_above_surface, normalize(relLightPos));
    return dist_to_object <= MAX_TRAVEL_DIST;
}

vec3 render(vec2 uv) {
    vec3 cameraCenter = vec3(0.0, 0.0, -3.0);
    vec3 current_pos_on_camera_plane = vec3(uv, -2.0);

    vec3 ambientColor = vec3(0.13, 0.07, 0.93);
    vec3 diffuseColor = vec3(0.94, 0.97, 0.03);
    vec3 backgroundColor = vec3(0.0);

    vec3 rd = normalize(current_pos_on_camera_plane - cameraCenter);

    float dist_to_scene = ray_march(cameraCenter, rd);

    vec3 point_on_surface = cameraCenter + (dist_to_scene) * (rd);

    vec3 normal = getNormal(point_on_surface);

    vec3 lightSource = vec3(sin(u_time)*1.0, cos(u_time)*2.0, sin(u_time)*1.5-0.5);

    float diffuseStrength = diffuse(lightSource, normal);

    float specularStrength = specular(lightSource, cameraCenter, normal);

    vec3 point_slightly_above_surface = point_on_surface + 0.1 * normal;
    vec3 shadowColor = vec3(0.6);

    if (dist_to_scene > MAX_TRAVEL_DIST) {
        return backgroundColor;
    } else {
        vec3 color = 0.5 * specularStrength + 0.5 * diffuseColor * diffuseStrength;
        bool is_in_shadow = shadow(lightSource, point_slightly_above_surface);
        if (is_in_shadow) {
            color *= shadowColor;
        }
        return color;
    }
}

void main() {
    vec2 uv = (2.0 * gl_FragCoord.xy - u_resolution) / u_resolution.y;
    vec3 color = render(uv);
    gl_FragColor = vec4(color, 1.0);
}