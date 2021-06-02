// Display shadow map for debugging purposes

[vert]

#version 150 compatibility

void main(void)
{
  gl_Position = gl_Vertex;
  gl_TexCoord[0] = (gl_Vertex + 1.0) * 0.5;
}

[frag]

#version 150 compatibility

uniform sampler2D depthMap;

float LinearizeDepth(vec2 uv)
{
  float n = 0.05; // camera z near
  float f = 25.0; // camera z far
  float z = texture2D(depthMap, uv).x;
  return (2.0 * n) / (f + n - z * (f - n));
}
void main()
{
  vec2 uv = gl_TexCoord[0].xy;
  float d;
  d = LinearizeDepth(uv);
  //d = texture2D(depthMap, uv).x;
  gl_FragColor = vec4(d, d, d, 1.0);
}
