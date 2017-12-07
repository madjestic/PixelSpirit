//#version 430 core
/// PixelSpirit Tarot
/// 02. Strength
#define PI 3.1415926535897932384626433832795

// Input Data
uniform vec2 u_resolution;

// Ouput data
// out vec4 gl_FragColor;

void main(void)
{
  vec3 color   = vec3(0.);
  vec2 st      = gl_FragCoord.xy/u_resolution;
  color       += step(.5+cos(st.y * PI * 10.)*0.35, st.x);
  gl_FragColor = vec4(color,1.0);
}


