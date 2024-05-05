precision mediump float;

uniform vec2 u_resolution;
uniform float u_time;

float sdSphere(vec3 p, vec3 center, float radius) {
    return length(p - center) - radius;
}

const float MAX_TRAVEL_DIST = 24.0;
const float MAX_ITERATIONS = 48.0;
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


vec4 quaternion_from_axis_angle(vec3 axis, float angle) {
  vec4 qr;
  float sin_of_half_angle = sin(angle / 2.0);
  qr.x = axis.x * sin_of_half_angle;
  qr.y = axis.y * sin_of_half_angle;
  qr.z = axis.z * sin_of_half_angle;
  qr.w = cos(angle / 2.);
  return qr;
}

vec4 mult_quaternions(vec4 q1, vec4 q2) {
  vec4 q;
  vec3 v1 = q1.xyz;
  vec3 v2 = q2.xyz;
  return vec4(
    cross(v1, v2) + v1 * q2.w + v2 * q1.w,
    q1.w * q2.w - dot(v1, v2)
  );
  q.x = (q1.w * q2.x) + (q1.x * q2.w) + (q1.y * q2.z) - (q1.z * q2.y);
  q.y = (q1.w * q2.y) + (q1.y * q2.w) + (q1.z * q2.x) - (q1.x * q2.z);
  q.z = (q1.w * q2.z) + (q1.z * q2.w) + (q1.x * q2.y) - (q1.y * q2.x);
  q.w = (q1.w * q2.w) - (q1.x * q2.x) - (q1.y * q2.y) - (q1.z * q2.z);
  return q;
}

vec4 quat_conj(vec4 q)
{
  return vec4(-q.x, -q.y, -q.z, q.w);
}

vec3 rotate_vertex_position(vec3 position, vec3 axis, float angle)
{
  vec4 qr = quaternion_from_axis_angle(axis, angle);
  vec4 qr_conj = quat_conj(qr);
  vec4 q_pos = vec4(position.x, position.y, position.z, 0);

  vec4 q_tmp = mult_quaternions(qr, q_pos);
  qr = mult_quaternions(q_tmp, qr_conj);

  return vec3(qr.x, qr.y, qr.z);
}

float sdfPlane(vec3 p, vec3 n, float h) {
    return dot(p, n) + h;
}

float opSmoothUnion(float d1, float d2, float k) {
    float h = clamp(0.5+0.5*(d2-d1)/k, 0.0, 1.0);
    return mix(d2, d1, h) - h*k*(1.0-h);
}
/*
float map(vec3 p) {
  float radius = 0.75;
  vec3 center = vec3(0.0);

  // part 4 - change height of the sphere based on time
  center = vec3(0.0, -0.25 + sin(u_time) * 0.5, 0.0);

  float sphere = sdSphere(p, center, radius);
  float m = sphere;

  // part 1.2 - display plane
  float h = 1.0;
  vec3 normal = vec3(0.0, 1.0, 0.0);
  float plane = sdfPlane(p, normal, h);
  m = opSmoothUnion(sphere, plane, 0.5);

  // part 4 - add smooth blending
  //m = opSmoothUnion(sphere, plane, 0.5);

  return m;
}
*/

float displacement(vec3 p) {
  return sin(50.*p.x*p.y)*sin(50.2*p.y*p.z)*sin(25.0*p.z*p.x)*.05*sin(u_time);
}

float sdBox( vec3 p, vec3 b )
{
  vec3 q = abs(p) - b;
  return length(max(q,0.0)) + min(max(q.x,max(q.y,q.z)),0.0);
}

const float PI = 2.0 * acos(0.0);

float map(vec3 p) {
  vec3 center = vec3(0.0);



  // part 4 - change height of the sphere based on time
  center = vec3(0.25 + sin(u_time/7.0) * 0.5, 0.25 + sin(u_time) * 0.5, -4.0);

  vec3 twistedP = p; //opTwist(p);

  float sphere = sdBox(rotate_vertex_position(twistedP, vec3(1.0, 1.0, 0.0), u_time)-vec3(1.0), vec3(1.2, 1.7, 1.3));
  float m = sphere;
  float box = sdBox(rotate_vertex_position(twistedP, vec3(0.0, 1.0, 1.0), u_time/1.5)-vec3(1.0), vec3(1.2, 1.7, 1.3));
  float box2 = sdBox(rotate_vertex_position(twistedP, vec3(1.0, 1.0, 1.0), u_time/1.7)-vec3(1.0), vec3(.7, 1.1, 0.8));
  float box3 = sdBox(rotate_vertex_position(twistedP, vec3(0.7, -1.2, .2), u_time/1.3)-vec3(1.0), vec3(0.5, 1.2, 0.9));


  float h = 1.0;
  vec3 normal = vec3(0.0, 1.0, 0.1);
  float plane = sdfPlane(p, normal, h);


  // part 4 - add smooth blending
  m = opSmoothUnion(m, box, 1.5);
  m = opSmoothUnion(m, box2, 1.5);
  m = m + displacement(p);
  m = opSmoothUnion(m, box3, 1.5);
  m = opSmoothUnion(m, plane, 1.5);

  vec3 rot_axis = vec3(0., 1., 0.);
  // BEGIN STONEHENGE
  const int num_henges = 7;

  // first henge position
  vec3 initial_pos = vec3(6., 1., 6.);

  for (int i = 0; i < num_henges; i++) {
    float cur_angle = 2.0 * PI * float(i) / float(num_henges);
    vec3 cur_pos = rotate_vertex_position(initial_pos,rot_axis, cur_angle) + sin(u_time +  cur_angle) * vec3(0.0, 4.0, 0.0);
    //m = min(m, sdBox(p-cur_pos, vec3(1.5, 1.9, 1.15)));
    vec3 hum = vec3(1.0, 0.0, 1.0);
    hum = rotate_vertex_position(hum, rot_axis, cur_angle);
    m = opSmoothUnion(m, sdSphere(p - cos(u_time-cur_angle)*hum*6.0, cur_pos, 2.), 2.5);
  }
  // END STONEHENGE

  // BEGIN STONEHENGE
  const int num_walls = 9;

  // first henge position
  vec3 initial_pos_2 = vec3(6., 1., 6.);
/*
  for (int i = 0; i < num_walls; i++) {
    float cur_angle = 2.0 * PI * float(i) / float(num_walls);
    vec3 cur_pos = rotate_vertex_position(initial_pos_2,rot_axis, cur_angle) + sin(u_time +  cur_angle) * vec3(0.0, 1.0, 0.0);
    //m = min(m, sdBox(p-cur_pos, vec3(1.5, 1.9, 1.15)));

    vec3 axis_x = vec3(0.0, 0.0, 1.0);
    axis_x = rotate_vertex_position(axis_x, rot_axis, -cur_angle+PI/4.0);
    vec3 rotatedP = rotate_vertex_position(p - cur_pos, rot_axis, -cur_angle+PI/4.0);
    rotatedP = rotate_vertex_position(rotatedP, axis_x,  .0);
    m = min(m, sdBox(rotatedP, vec3(.1, 19., 3.)));
  }*/
  // END STONEHENGE

  return m;
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
vec3 rot_axis = vec3(0., 1., 0.);
    vec3 camera_center = vec3(0.0,0.0, 9.0);
    camera_center = rotate_vertex_position(camera_center, rot_axis, u_time/2.0);
    vec3 cur_point_on_cam_plane = vec3(uv, 8.0);
    cur_point_on_cam_plane = rotate_vertex_position(cur_point_on_cam_plane, rot_axis, u_time/2.0);
    vec3 rd = normalize(cur_point_on_cam_plane - camera_center);


    float dist_to_scene = ray_march(camera_center, rd);

    vec3 rel_light_source_pos = vec3(+1.0,1., -1.0);
    rel_light_source_pos = rotate_vertex_position(rel_light_source_pos, rot_axis, u_time/2.0);


    vec3 obj_col = vec3(1.0, 1.0, 1.0);
    vec3 background_col_2 = vec3(1.0, 0.949, 0.0);
    vec3 background_col_3 = vec3(0.0, 0.0314, 1.0);

    vec3 background_col = mix(background_col_2, background_col_3, .5+cos(u_time/2.0)*.5);

    vec3 color = vec3(0);

    if (dist_to_scene > MAX_TRAVEL_DIST) {
        gl_FragColor = vec4(background_col, 1.0);
    } else {
        vec3 point_on_surface = camera_center + dist_to_scene * rd;
        vec3 normal = get_normal(point_on_surface);
        obj_col = normal;

        vec3 refl = normalize(reflect(rd, normal));
        float d = ray_march(point_on_surface + 0.2*refl, refl);
        float specular_strength = specular(rel_light_source_pos, camera_center, normal);

        float diffuse_strength = diffuse(rel_light_source_pos, normal);
        bool shad = is_in_shadow(point_on_surface + 0.1 * normal, rel_light_source_pos);

        if (shad) {
            vec3 shadow_color = vec3(0.0);
            obj_col = mix(shadow_color, obj_col, 0.8);
        }
        color = obj_col * (0.75*diffuse_strength+0.25*specular_strength);
        color = pow(color, vec3(1.0 / 2.2));

         if (d > MAX_TRAVEL_DIST) {
        gl_FragColor = vec4(mix(color, background_col, 0.3), 1.0);
    } else {
        vec3 ref_on_surf = point_on_surface + d * refl;
        vec3 ref_norm = get_normal(ref_on_surf);
        obj_col = ref_norm;

        vec3 refl_light = reflect(rel_light_source_pos, normal);




        float specular_strength_refl = specular(refl_light, refl, ref_norm);

        float diffuse_strength_refl = diffuse(refl_light, ref_norm);
        vec3 refl_color = obj_col * (0.75*diffuse_strength_refl+0.25*specular_strength_refl);
        gl_FragColor = vec4(mix(color, refl_color, 0.3), 1.0);
    }
    }

}