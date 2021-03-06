#ifdef GL_ES
precision mediump float;
#endif
// #version 430 core
/// PixelSpirit Tarot
/// 01. Justice

// Input Data
uniform vec2 u_resolution;

// Ouput data
// out vec4 gl_FragColor;

void main(void)
{
  vec3 color   = vec3(0.);
  vec2 st      = gl_FragCoord.xy/u_resolution;
  color       += step(.5,st.x);
  gl_FragColor = vec4(color,1.0);
}
