precision mediump float;

uniform float u_time;
uniform vec2 u_resolution;

float sdfSphere(vec3 c, float r, vec3 p) {
    return length(p - c) - r;
}

float sdfPlane(vec3 normal, float dist_from_origin, vec3 p) {
    return dot(normal, p) + dist_from_origin;
}

float opSmoothUnion(float d1, float d2, float k) {
    float h = clamp(0.5 + 0.5 * (d2 - d1) / k, 0.0, 1.0);
    return mix(d2, d1, h) - k * h * (1.0 - h);
}

float map(vec3 p) {
    float ds = sdfSphere(vec3(0.0), 0.7, p);
    float dp = sdfPlane(vec3(cos(u_time)*-3.0, sin(u_time)*-20.0-20.0, 4.0), 1.0, p);
    return opSmoothUnion(ds, dp, 2.0);
}

const int MAX_ITERATIONS = 64;
const float MIN_DISTANCE_TO_OBJ = 0.01;
const float MAX_TRAVEL_DIST = 128.0;

float ray_march(vec3 p, vec3 ray_direction) {
    float travelledDist = 0.0;
    for (int i = 0; i < MAX_ITERATIONS; i++) {
        float distToNearest = map(p);
        travelledDist += distToNearest;
        if (travelledDist > MAX_TRAVEL_DIST) {
            break;
        }

        if (distToNearest < MIN_DISTANCE_TO_OBJ) {
            break;
        }
        p += ray_direction * distToNearest;
    }
    return travelledDist;
}

vec3 getNormal(vec3 p) {
    float delta = 0.01;
    float x = map(p + vec3(delta, 0., 0.)) - map(p - vec3(delta, 0., 0.));
    float y = map(p + vec3(0., delta, 0.)) - map(p - vec3(0., delta, 0.));
    float z = map(p + vec3(0., 0., delta)) - map(p - vec3(0., 0., delta));

    return normalize(vec3(x, y, z));
}

float diffuseLighting(vec3 relativeLightSourcePos, vec3 normal) {
    float diffuseStrength = max(dot(normalize(relativeLightSourcePos), normal), 0.0);
    return diffuseStrength;
}

float specularLighting(vec3 lightDir, vec3 normal, vec3 viewDir) {
    vec3 reflection = reflect(normalize(lightDir), normal);
    float specStrength = max(dot(normalize(viewDir), reflection), 0.0);
    return pow(specStrength, 32.0);
}

vec3 render(vec2 uv) {
    vec3 ambientColor = vec3(1.0);

    vec3 relativeLightSourcePos = vec3(sin(u_time)*-4.0, -2.0, sin(u_time/4.0)*4.0);

    vec3 cameraCenter = vec3(0.0, -2.0, 0.0);
    vec3 current_point_on_camera_plane = vec3(uv.x, -1.0, uv.y);

    vec3 ray_dir = normalize(current_point_on_camera_plane - cameraCenter);

    float dist = ray_march(cameraCenter, ray_dir);

    vec3 normal = getNormal(cameraCenter + ray_dir * dist);

    float diffuseStrength = diffuseLighting(relativeLightSourcePos, normal);

    float specStrength = specularLighting(-relativeLightSourcePos, normal, cameraCenter);

    if (dist > MAX_TRAVEL_DIST) {
      return vec3(1.0);
    } else {
      return ambientColor * (1.0 - (0.75 * diffuseStrength + 0.25 * specStrength));
    }
}

void main() {
  vec2 uv = 2.0 * gl_FragCoord.xy / u_resolution - 1.0;
  vec3 color = render(uv);
  gl_FragColor = vec4(color, 1.);
}