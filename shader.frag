// Helful Resources
// ----------------
// Ray Marching Blog Post by Michael Walczyk
// https://michaelwalczyk.com/blog-ray-marching.html
// Inigo Quilez SDF Functions
// https://iquilezles.org/articles/distfunctions/

precision mediump float;

uniform float u_time;
uniform vec2 u_resolution;

const float NUM_OF_STEPS = 128.0;
const float MIN_DIST_TO_SDF = 0.001;
const float MAX_DIST_TO_TRAVEL = 64.0;

float opSmoothUnion(float d1, float d2, float k) {
  // this next term will be between 0.0 and 1.0
  // if the distance between d1 and d2 is less than k
  // so increasing k will blend the shapes together earlier
  float h = clamp(0.5 + 0.5 * (d2 - d1) / k, 0.0, 1.0);
  // h is a value between 0.0 and 1.0
  // if h is 1.0 nothing is subtracted from the term below
  // if h is 0.0 nothing is subtracted as well
  // if h is between 0.0 and 1.0 we get the linear interpolation between d2 and d1
  return mix(d2, d1, h) - k * h * (1.0 - h);
}

float displace(vec3 p, float fac) {
   return sin(fac*p.x)*sin(fac*p.y)*sin(fac*p.z);
}


float opDisplace( in float p, in float q )
{
    return p+q;
}

float sdfBox(vec3 p, vec3 b) {
  vec3 q = abs(p) - b;
  return length(max(q, 0.0)) + min(max(q.x, max(q.y, q.z)), 0.0);
}
float sdBox( vec3 p, vec3 b )
{
  vec3 q = abs(p) - b;
  return length(max(q,0.0)) + min(max(q.x,max(q.y,q.z)),0.0);
}
float sdfPlane(vec3 p, vec3 n, float h) {
  // n must be normalized
  return dot(p, n) + h;
}

float sdfSphere(vec3 p, vec3 c, float r) {
  return length(p - c) - r;
}

vec3 opTwist( in vec3 p , float k) {
    float c = cos(k*p.y);
    float s = sin(k*p.y);
    mat2  m = mat2(c,-s,s,c);
    vec3  q = vec3(m*p.xz,p.y);
    return q;
}

float map(vec3 p) {
  float radius = 0.75;
  vec3 center = vec3(0.0);

  // part 4 - change height of the sphere based on time
  center = vec3(0.0, -0.25 + sin(u_time) * .3 + .2, 0.0);

  float dis = displace(p, sin(u_time/2.0) * 10.0);

  vec3 normal = vec3(0.5333, 0.1137, 0.1137);
  float sphere = sdfSphere(opTwist(opTwist(p, cos(u_time/24.0) * 300.0).yxz, sin(u_time/120.0) * 2300.0), center, radius);
  float m = sphere + dis;


  // part 1.2 - display plane
  float h = 1.0;
  float plane = sdfPlane(p + center * 2.0, normal, h);

  // part 4 - add smooth blending
  m = opSmoothUnion(m, plane, 0.4);

  return m;
}



float rayMarch(vec3 ro, vec3 rd, float maxDistToTravel) {
  float dist = 0.0;

  for (float i = 0.0; i < NUM_OF_STEPS; i++) {
    vec3 currentPos = ro + rd * dist;
    float distToSdf = map(currentPos);

    if (distToSdf < MIN_DIST_TO_SDF) {
      break;
    }

    dist = dist + distToSdf;

    if (dist > maxDistToTravel) {
      break;
    }
  }

  return dist;
}

vec3 getNormal(vec3 p) {
  vec2 d = vec2(0.01, 0.0);
  float gx = map(p + d.xyy) - map(p - d.xyy);
  float gy = map(p + d.yxy) - map(p - d.yxy);
  float gz = map(p + d.yyx) - map(p - d.yyx);
  vec3 normal = vec3(gx, gy, gz);
  return normalize(normal);
}

vec3 render(vec2 uv) {
  vec3 color = vec3(0.0);

  // note: ro -> ray origin, rd -> ray direction
  vec3 ro = vec3(0.0, 0., -2.0);
  vec3 rd = vec3(uv * sin(u_time)*3.0, 1.0);

  float dist = rayMarch(ro, rd, MAX_DIST_TO_TRAVEL);

  if (dist < MAX_DIST_TO_TRAVEL) {
    // part 1 - display ray marching result
    color = vec3(1.0);

    // part 2.1 - calculate normals
    // calculate normals at the exact point where we hit SDF
    vec3 p = ro + rd * dist;
    vec3 normal = getNormal(p);
    color = normal;

    // part 2.2 - add lighting

    // part 2.2.1 - calculate diffuse lighting
    vec3 lightColor = vec3(0.85, 0.0, 1.0);
    vec3 lightSource = vec3(sin(u_time / 10.0) * 2.5 + 2.5, sin(u_time / 7.0) * 2.5,-1.0 + sin(u_time) * -1.0);
    //lightSource = vec3(2.5, 2.5,-1.0);
    float diffuseStrength = max(0.0, dot(normalize(lightSource), normal));
    vec3 diffuse = lightColor * diffuseStrength;

    // part 2.2.2 - calculate specular lighting
    vec3 viewSource = normalize(ro);
    vec3 reflectSource = normalize(reflect(-lightSource, normal));
    float specularStrength = max(0.0, dot(viewSource, reflectSource));
    specularStrength = pow(specularStrength, 64.0);
    vec3 specular = specularStrength * lightColor;

    // part 2.2.3 - calculate lighting
    vec3 lighting = diffuse * 0.75 + specular * 0.25;
    color = lighting;

    // part 3 - add shadows

    // part 3.1 - update the ray origin and ray direction
    vec3 lightDirection = normalize(lightSource);
    float distToLightSource = length(lightSource - p);
    ro = p + normal * 0.1;
    rd = lightDirection;

    // part 3.2 - ray march based on new ro + rd
    float dist = rayMarch(ro, rd, distToLightSource);
    if (dist < distToLightSource) {
      color = color * vec3(0.0431, 0.7804, 0.498);
    }

    // note: add gamma correction
    color = pow(color, vec3(1.0 / 2.2));
  }

  return color;
}

void main() {
  vec2 uv = 2.0 * gl_FragCoord.xy / u_resolution - 1.0;
  // note: properly center the shader in full screen mode
  uv = (2.0 * gl_FragCoord.xy - u_resolution) / u_resolution.y;
  vec3 color = vec3(0.0);
  color = render(uv);
  // color = vec3(uv, 0.0);
  gl_FragColor = vec4(color, 1.0);
}