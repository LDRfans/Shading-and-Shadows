//Per-fragment diffuse/specular lighting shader (Phong shading) for a particular single directional light source.

[vert]

#version 150 compatibility

uniform float g_fFrameTime;

// data to be passed down to a later stage
out vec3 normal;
out vec4 ecPosition;
out vec4 shadowCoord;

void main()
{
    normal = normalize(gl_NormalMatrix * gl_Normal);
	vec4 vAnimatedPos = gl_Vertex;
	//vAnimatedPos.x += sin(g_fFrameTime/300.0 + vAnimatedPos.x * 5)*0.02 
					//* (cos(clamp(vAnimatedPos.x*2, -1, 1)*3.1416)*0.5+0.5)
					//+ sin(g_fFrameTime/2000.0)*0.3;
					
    // Eye-coordinate position of vertex, needed in various calculations
    ecPosition = gl_ModelViewMatrix * vAnimatedPos;

    gl_Position = gl_ModelViewProjectionMatrix * vAnimatedPos;
    
    // Compute shadow map coordinate (including depth)
    shadowCoord= gl_TextureMatrix[1] * vAnimatedPos; 
    
    gl_TexCoord[0] = gl_MultiTexCoord0;
}

[frag]

#version 150 compatibility

uniform sampler2D colorMap;
uniform sampler2D shadowMap;
uniform int lightIndex;
uniform float shadowZOffset = 1e-5;

// data passed down and interpolated from the vertex shader
in vec3 normal;
in vec4 ecPosition;
in vec4 shadowCoord;

// global variables used in auxilary functions
vec4 Ambient;
vec4 Diffuse;
vec4 Specular;

void pointLight(in int i, in vec3 normal, in vec3 eye, in vec3 ecPosition3)
{
   float nDotVP;       // normal . light direction
   float nDotHV;       // normal . light half vector
   float pf;           // power factor
   float attenuation;  // computed attenuation factor
   float d;            // distance from surface to light source
   vec3  VP;           // direction from surface to light position
   vec3  halfVector;   // direction of maximum highlights

   // Compute vector from surface to light position
   VP = vec3 (gl_LightSource[i].position) - ecPosition3;

   // Compute distance between surface and light position
   d = length(VP);

   // Normalize the vector from surface to light position
   VP = normalize(VP);

   // Compute attenuation
   attenuation = 1.0 / (gl_LightSource[i].constantAttenuation +
       gl_LightSource[i].linearAttenuation * d +
       gl_LightSource[i].quadraticAttenuation * d * d);

   halfVector = normalize(VP + eye);

   nDotVP = max(0.0, dot(normal, VP));
   nDotHV = max(0.0, dot(normal, halfVector));

   pf = (nDotVP == 0.0) ? 0.0 : pow(nDotHV, gl_FrontMaterial.shininess);

   Ambient  += gl_LightSource[i].ambient * attenuation;
   Diffuse  += gl_LightSource[i].diffuse * nDotVP * attenuation;
   Specular += gl_LightSource[i].specular * pf * attenuation;
}

void main()
{   
    vec3 n = normalize(normal);

    vec3 ecPosition3 = (vec3 (ecPosition)) / ecPosition.w;

	// Clear the light intensity accumulators
    Ambient  = vec4 (0.0);
    Diffuse  = vec4 (0.0);
    Specular = vec4 (0.0);
    vec3 eye = vec3 (0.0, 0.0, 1.0);
    
    // Compute point light contributions
    pointLight(lightIndex, n, eye, ecPosition3);
    
    
 	float shadow = 1.0;
 	
    // TODO:
    // 1) Compute shadow map coordinate (including depth)
    //    in texture space (Hint: use perspective division)
    // 2) Fetch depth from the shadow map
    // 3) Compute "shadow" value based on the comparison of 
    //    fetched depth and the computed depth
    //    Hint: Compare with the tolerance "shadowZOffset"
    //          to avoid shadow acnes in self shadowing

    // 1) homogeneity
    vec4 shadowMapCoord = shadowCoord / shadowCoord.w;
    // 2) fetch depth
	float depth = texture2D(shadowMap, shadowMapCoord.xy).z;
    // 3) shadow map logic
	if(shadowMapCoord.z - depth > shadowZOffset) {
		shadow = 0.0;
	}


    vec4 color = Diffuse * gl_FrontMaterial.diffuse;

    color *= texture2D(colorMap, gl_TexCoord[0].st);
    color += Specular * gl_FrontMaterial.specular;
    color = clamp( color, 0.0, 1.0 );
    gl_FragColor = color * shadow;
}
