//Per-fragment Blinn-Phong shader (Phong shading) for two single directional light sources.

[vert]

#version 150 compatibility

uniform float g_fFrameTime;

// data to be passed down to a later stage
out vec3 normal;
out vec4 ecPosition;

void main()
{
    // Compute View(eye) space surface normal at the current vertex
    normal = normalize(gl_NormalMatrix * gl_Normal);
	
	// TODO(4): add an non-trivial interesting animation to the model 
	//       by changing "vAnimatedPos" using a function of "g_fFrameTime"
	vec4 vAnimatedPos = gl_Vertex;

    // Eye-coordinate position of vertex, needed in lighting computation
    ecPosition = gl_ModelViewMatrix * vAnimatedPos;

    // Compute the projection space position of the current vertex
    gl_Position = gl_ModelViewProjectionMatrix * vAnimatedPos;
    // Pass on te texture coordinate
    gl_TexCoord[0] = gl_MultiTexCoord0;    
}

[frag]

#version 150 compatibility

uniform sampler2D colorMap;

// data passed down and interpolated from the vertex shader
in vec3 normal;
in vec4 ecPosition;

// global variables used in auxilary functions
vec4 Ambient;
vec4 Diffuse;
vec4 Specular;

void pointLight(in int i, in vec3 normal, in vec3 eye, in vec3 ecPosition3)
{
    // TODO(3): Copy the completed per-vertex point light computation to here
}




void main()
{   
    // Process passed-down interpolated attributes
    vec3 n = normalize(normal);
    vec3 ecPosition3 = (vec3 (ecPosition)) / ecPosition.w;
    
    //TODO(3): Move the Blinn-Phong computation from the vertex shader to the pixel shader.
    //      Important difference: Perform the texture lookup and modulate by the 
    //      lighting result *prior to* adding the specular component.

    gl_FragColor = vec4(0,0,0,0);
}
