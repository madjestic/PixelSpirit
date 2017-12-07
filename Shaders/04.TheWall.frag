//#version 430 core
/// PixelSpirit Tarot
/// 04. The Wall
#define PI 3.1415926535897932384626433832795

// Input Data
uniform vec2 u_resolution;

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
  vec3 color   = vec3(0.);
  vec2 st      = gl_FragCoord.xy/u_resolution;
  color       += step(.5 + cos((st.y + st.y) * PI * 5.0)*.25, (st.x + st.y) * 0.5);
  color       += stroke(st.x, .5, .15);
  gl_FragColor = vec4(color,1.0);
}
