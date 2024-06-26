precision mediump float;

uniform float u_time;
uniform vec2 u_resolution;

void main() {
  vec3 black = vec3(0.0);
  vec3 white = vec3(1.0);
  vec3 color = black;

  vec2 uv = 2.0 * gl_FragCoord.xy / u_resolution - 1.0;
  uv.x = uv.x * u_resolution.x / u_resolution.y;
  color = vec3(uv, 0.0);

  color = vec3(uv, 0.0);

  vec2 gridUv = fract(uv);
  vec2 gridId = floor(uv);
  color = vec3(smoothstep(.1, -.1, abs(abs(uv.x)-smoothstep(-0.2, -1., uv.y))));

  gl_FragColor = vec4(color, 1.);
}