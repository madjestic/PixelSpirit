/// PixelSpirit Tarot
/// 01. Justice
#version 430 core

// Input Data
uniform vec2 u_resolution;

// Ouput data
out vec4 fColor;

void main()
{
  vec3 color = vec3(0.);
  vec2 st    = gl_FragCoord.xy/u_resolution;
  color     += step(.5,st.x);
  fColor = vec4(color,1.0);
}
