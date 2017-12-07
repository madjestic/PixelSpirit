//#version 430 core
/// PixelSpirit Tarot
/// Meditation
#define PI 3.1415926535897932384626433832795

// Input Data
uniform vec2  u_resolution;
uniform float u_time;

// Ouput data
// out vec4 gl_FragColor;

float stroke(float x, float s, float w)
{
  float d =
    step(s, x + w*.5) -
    step(s, x - w*.5);
  return clamp(d, 0., 1.);
}

void main(void)
{
  vec3 color = vec3(0.);
  vec3 cnv   = vec3(0.);
  vec2 st    = gl_FragCoord.xy/u_resolution;
  cnv       += step(1. + cos((st.y - st.x + u_time) * PI * 5.0)*.075, (st.x + st.y));
  color     += vec3((stroke(st.x, .5, .15)), .5, .0);
  color     += .5*cnv;
  gl_FragColor = vec4(color,1.0);
}
