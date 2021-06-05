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
    // Parameters: 
    //   i: light index (1/2 in this assignment)
    //   normal: eye(view) space surface normal at the shaded vertex
    //   eye: eye(view) space camera position
    //   ecPosition3: eye(view) space position of the shaded vertex

    /****************************************/
    /*************** MODIFIED ***************/

    // Init
    float nDotVP;       // normal . light direction
    float nDotHV;       // normal . light half vector
    float pf;           // power factor
    float attenuation;  // computed attenuation factor
    float d;            // distance from surface to light source
    vec3  VP;           // direction from surface to light position
    vec3  halfVector;   // direction of maximum highlights (Half vector defined by the *Blinn-Phong model*)

    // Diffuse: Compute the direction from surface to the light source
    // Compute vector from surface to light position
    VP = vec3 (gl_LightSource[i].position) - ecPosition3;
    // Compute distance between surface and light position
    d = length(VP);
    // Normalize the vector from surface to light position
    VP = normalize(VP);

    // Compute attenuation
    attenuation = 1.0;
    // attenuation = 1.0 / (gl_LightSource[i].constantAttenuation +
    //     gl_LightSource[i].linearAttenuation * d +
    //     gl_LightSource[i].quadraticAttenuation * d * d);

    // Specular: Compute the half-vector
    halfVector = normalize(VP + eye);

    nDotVP = max(0.0, dot(normal, VP));
    nDotHV = max(0.0, dot(normal, halfVector));

    // Specular: Computer the specular reflection
    pf = (nDotVP == 0.0) ? 0.0 : pow(nDotHV, gl_FrontMaterial.shininess);

    // Return
    Ambient  += gl_LightSource[i].ambient * attenuation;
    Diffuse  += gl_LightSource[i].diffuse * nDotVP * attenuation;
    Specular += gl_LightSource[i].specular * pf * attenuation;
    /****************************************/
}




void main()
{   
    // Process passed-down interpolated attributes
    vec3 n = normalize(normal);
    vec3 ecPosition3 = (vec3 (ecPosition)) / ecPosition.w;
    
    //TODO(3): Move the Blinn-Phong computation from the vertex shader to the pixel shader.
    //      Important difference: Perform the texture lookup and modulate by the 
    //      lighting result *prior to* adding the specular component.

    /****************************************/
    /*************** MODIFIED ***************/

    // Clear the light intensity accumulators
    Ambient  = vec4 (0.0);
    Diffuse  = vec4 (0.0);
    Specular = vec4 (0.0);
    vec3 eye = vec3 (0.0, 0.0, 1.0);

    // Compute point light contributions
    pointLight(0, n, eye, ecPosition3);
    pointLight(1, n, eye, ecPosition3);

    // Step 1: Add ambient and diffuse contributions
    vec4 color = gl_FrontLightModelProduct.sceneColor +
                 gl_FrontMaterial.ambient * Ambient +
                 gl_FrontMaterial.diffuse * Diffuse;

    // Step 2: Perform the texture lookup
    color = color * texture2D(colorMap, gl_TexCoord[0].st);

    // Step 3: Adding the specular component
    color += gl_FrontMaterial.specular * Specular;

    // Clamp color to [0, 1]
    color = clamp( color, 0.0, 1.0 );
    
    // Output color
    gl_FrontColor = color;
    /****************************************/
}
