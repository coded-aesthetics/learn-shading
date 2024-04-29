precision mediump float;

uniform vec2 u_resolution;
uniform float u_time;

float sdSphere(vec3 p, vec3 center, float radius) {
    return length(p - center) - radius;
}

const float MAX_TRAVEL_DIST = 128.0;
const float MAX_ITERATIONS = 64.0;
const float MIN_DIST_TO_OBJ = 0.01;

float sdBoxFrame( vec3 p, vec3 b, float e )
{
       p = abs(p  )-b;
  vec3 q = abs(p+e)-e;
  return min(min(
      length(max(vec3(p.x,q.y,q.z),0.0))+min(max(p.x,max(q.y,q.z)),0.0),
      length(max(vec3(q.x,p.y,q.z),0.0))+min(max(q.x,max(p.y,q.z)),0.0)),
      length(max(vec3(q.x,q.y,p.z),0.0))+min(max(q.x,max(q.y,p.z)),0.0));
}
float sdPlane(vec3 p, vec3 n, float dist) {
    return dot(p, n) + dist;
}
float disturb(vec3 p) {
    return sin(50.*p.x*p.y)*sin(50.2*p.y*p.z)*sin(25.0*p.z*p.x)*.05*sin(u_time*2.0);
}
float map(vec3 p) {
    float plane = sdPlane(p, vec3(sin(u_time)*1.0, 1.0, sin(u_time)*.4), 7.0);
    float sphere = sdSphere(p, vec3(0.0), 0.5);

  float frame = sdBoxFrame(p, vec3(1.0, 1.0, 0.0), 0.2);
//return frame;

    return min(sphere+disturb(p), plane);
}


float ray_march(vec3 ro, vec3 rd) {
    float travel_dist = 0.0;
    for (float i = 0.0; i < MAX_ITERATIONS; i += 1.0) {
        vec3 cur_pos = ro + travel_dist * rd;
        float dist_to_scene = map(cur_pos);

        if (dist_to_scene < MIN_DIST_TO_OBJ) {
            break;
        }

        travel_dist += dist_to_scene;

        if(travel_dist > MAX_TRAVEL_DIST) {
            break;
        }
    }
    return travel_dist;
}

bool is_in_shadow(vec3 point_slightly_above_surface, vec3 rel_light_pos) {
    vec3 rd = normalize(rel_light_pos - point_slightly_above_surface);
    return ray_march(point_slightly_above_surface, rd) < MAX_TRAVEL_DIST;
}
vec3 get_normal(vec3 p) {
    vec2 d = vec2(0.01, 0.0);
    float dx = map(p + d.xyy) - map(p - d.xyy);
    float dy = map(p + d.yxy) - map(p - d.yxy);
    float dz = map(p + d.yyx) - map(p - d.yyx);

    return normalize(vec3(dx, dy, dz));
}

float diffuse(vec3 rel_light_source_pos, vec3 normal) {
    float diffuse_strength = max(dot(normalize(rel_light_source_pos), normal), 0.0);
    return diffuse_strength;
}

float specular(vec3 rel_light_source_pos, vec3 rel_camera_pos, vec3 normal) {
    vec3 r = reflect(-normalize(rel_light_source_pos), normal);
    float spec_stren = max(dot(r, normalize(rel_camera_pos)), 0.0);
    return pow(spec_stren, 32.0);
}

void main() {
    vec2 uv = (2.0 * gl_FragCoord.xy - u_resolution) / u_resolution.x;
    vec3 camera_center = vec3(0.0, 0.0, -2.0);
    vec3 cur_point_on_cam_plane = vec3(uv, -1.0);
    vec3 rd = normalize(cur_point_on_cam_plane - camera_center);

    float dist_to_scene = ray_march(camera_center, rd);

    vec3 rel_light_source_pos = vec3(+100000.0,+100000.0, -100000.0);


    vec3 obj_col = vec3(1.0);
    vec3 background_col = vec3(0.0);

    if (dist_to_scene > MAX_TRAVEL_DIST) {
        gl_FragColor = vec4(background_col, 1.0);
    } else {
        vec3 point_on_surface = camera_center + dist_to_scene * rd;
        vec3 normal = get_normal(point_on_surface);

        bool shad = is_in_shadow(point_on_surface + 0.1 * normal, rel_light_source_pos);

        if (shad) {
            obj_col *= 0.2;
        }

        float specular_strength = specular(rel_light_source_pos, camera_center, normal);

        float diffuse_strength = diffuse(rel_light_source_pos, normal);
        gl_FragColor = vec4(obj_col * (0.75*diffuse_strength+0.25*specular_strength), 1.0);
    }

}