precision mediump float;

uniform float u_time;
uniform vec2 u_resolution;

float sdfSphere(vec3 c, float r, vec3 p) {
    return length(p - c) - r;
}

float sdfPlane(vec3 normal, float dist_from_origin, vec3 p) {
    float n = (dist_from_origin) * length(p) / dot(normal, p);
    vec3 point_on_plane = normalize(p) * n;
    vec3 perp1 = normalize(vec3(normal.y, -normal.x, 0.0));
    vec3 perp2 = normalize(perp1 * normal);
    vec3 origin = normal * (dist_from_origin);
    float x = dot(point_on_plane - origin, perp1);
    float y = dot(point_on_plane - origin, perp2);
    return dot(normal, p + normal*sin(x)/2.0) + dist_from_origin;
}

float opSmoothUnion(float d1, float d2, float k) {
    float h = clamp(0.5 + 0.5 * (d2 - d1) / k, 0.0, 1.0);
    return mix(d2, d1, h) - k * h * (1.0 - h);
}

float map(vec3 p) {
  float radius = 0.75;
  vec3 center = vec3(0.0);

  // part 4 - change height of the sphere based on time
  center = vec3(0.0, -0.25 + sin(u_time) * 0.5, .0);

  float sphere = sdfSphere(center, radius, p);
  float m = sphere;

  // part 1.2 - display plane
  float h = 1.0;
  vec3 normal = vec3(.0, 1.0, .0);
  float plane = sdfPlane(normal, h, p);
  m = min(plane, plane);

  // part 4 - add smooth blending
  //m = opSmoothUnion(sphere, plane, 0.5);

  return m;
}
const int MAX_ITERATIONS = 64;
const float MIN_DISTANCE_TO_OBJ = 0.01;
const float MAX_TRAVEL_DIST = 228.0;

float ray_march(vec3 p, vec3 ray_direction, float maxTravelDist) {
    float travelledDist = 0.0;
    for (int i = 0; i < MAX_ITERATIONS; i++) {
        float distToNearest = map(p);
        travelledDist += distToNearest;
        if (travelledDist > maxTravelDist) {
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

float specularLighting(vec3 lightDir, vec3 normal, vec3 viewPos) {
    vec3 reflection = reflect(normalize(lightDir), normal);
    float specStrength = max(dot(normalize(viewPos), reflection), 0.0);
    return pow(specStrength, 32.0);
}

bool shadow(vec3 relativeLightSourcePos, vec3 pointOnObj) {
    relativeLightSourcePos = normalize(relativeLightSourcePos);
    float dist = ray_march(pointOnObj, relativeLightSourcePos, 128.0);
    return dist < MAX_TRAVEL_DIST;
}

vec3 render(vec2 uv) {
    vec3 ambientColor = vec3(1.0);

    vec3 relativeLightSourcePos = vec3(4.0, 60.0, 3.0);

    vec3 cameraCenter = vec3(.0, 30.0, -3.0);
    vec3 current_point_on_camera_plane = cameraCenter + vec3(uv, 2.0);

    // vec3 cameraCenter = vec3(-0.0, -6.0, 0.0);
    // vec3 current_point_on_camera_plane = vec3(uv.x, -5.0, uv.y);

    vec3 ray_dir = normalize(current_point_on_camera_plane - cameraCenter);

    float dist = ray_march(cameraCenter, ray_dir, MAX_TRAVEL_DIST);

    vec3 normal = getNormal(cameraCenter + ray_dir * dist);

    float diffuseStrength = diffuseLighting(relativeLightSourcePos, normal);

    float specStrength = specularLighting(-relativeLightSourcePos, normal, cameraCenter);

    vec3 color = ambientColor * (0.75 * diffuseStrength + 0.25 * specStrength);

    vec3 shadowColor = vec3(0.08, 0.21, 0.81);
    bool shad = shadow(relativeLightSourcePos, cameraCenter + ray_dir * dist + normal * 0.1);
    if (shad) {
        //color = color * shadowColor;
    }

    if (dist > MAX_TRAVEL_DIST) {
      return vec3(1.0);
    } else {
      return color;
    }
}

void main() {
  vec2 uv = 2.0 * gl_FragCoord.xy / u_resolution - 1.0;
  uv = (2.0 * gl_FragCoord.xy - u_resolution) / u_resolution.y;
  vec3 color = render(uv);
  gl_FragColor = vec4(color, 1.);
}