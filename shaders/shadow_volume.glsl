// Shadow volume shader.

[vert]

#version 150 compatibility

uniform float g_fFrameTime;

void main()
{
	vec4 vAnimatedPos = gl_Vertex;
    //vAnimatedPos.x += sin(g_fFrameTime/300.0 + vAnimatedPos.x * 5)*0.02 
					//* (cos(clamp(vAnimatedPos.x*2, -1, 1)*3.1416)*0.5+0.5)
					//+ sin(g_fFrameTime/2000.0)*0.3;

    gl_Position = gl_ModelViewMatrix * vAnimatedPos;
}

[geom]
#version 150 compatibility

// Input data layout: triangle with a adjacency
layout(triangles_adjacency) in;
// Output data layout: triangle strip
// Maximum vertices output per input triangle
// If you emit triangle strips, then the 
// max_vertices is 3 * 4 = 12. Otherwise if
// you emit individual triangles, then the
// max_vertices is 3 * 6 = 18.
layout(triangle_strip, max_vertices = 18) out;

uniform int lightIndex;
//
// Helper function to detect a silhouette edge and extrude a volume from it.
// This function takes an edge of the model (end points v1 and v2), 
// detects if it is a silhouette from the light's point of view,
// and extrudes a quad from it if it is.
void DetectAndProcessSilhouette( vec3 N,          // triangle normal (Un-normalized)
                                 vec3 v1,         // Shared vertex
                                 vec3 v2,         // Shared vertex
                                 vec4 vAdj,       // Adjacent triangle vertex (with "w")
                                 vec3 lightPos    // Light position
                               )
{    
    // TODO: 
    // 1) Compute normal of the adjacent triangle
    // 2) Determine if the current and the adjacent
    //    triangle are facing the light
    // 3) Determine if the processed edge is a silhouette
    //    from the light's point of view (PoV)
    //    If not, simply return
    //    Hint: two cases: either the adjacent triangle is null (w==0)
    //          or the two triangles are facing differently in the light PoV
    // 4) Extrude a quad from the silhouette edge in the 
    //    direction away from the light to infinity.
    //    Hint:
    //    1. the output should be in projection space. 
    //    2. the output is in the format of a triangle strip.
    //    You can either emit two triangles separately or together (i.e. as a strip).  
    //    If the latter, the four vertices of the quad should be in the following order:
    //    0 ---- 2
    //    |     /|
    //    |    / |
    //    |   /  |
    //    |  /   |
    //    | /    |
    //    1 ---- 3

    // 1) Compute normal of the adjacent triangle
    vec3 v3 = vAdj.xyz;
    vec3 sharedEdge = v2-v1;
    vec3 adjEdge = v3-v1;
    // 2) Determine if current and adjacent triangle are facing the lightIndex
    vec3 adjN = cross(adjEdge, sharedEdge);
    vec3 sharedEdgeCenter = (v1+v2)/2;
    vec3 egdeCenter2Light = lightPos-sharedEdgeCenter;
    // 3) Determine if sharedEgde is a sihouette: not a sihouette: w!=0 and (triangle is not facing the light and the adjacent is fa 
    if (vAdj.w != 0 && (dot(N, egdeCenter2Light) <= 0 || dot(adjN, egdeCenter2Light) >= 0)) {return;}

    // 4) Extrude a quad from the silhouette edge in the 
    //    direction away from the light to infinity.
    vec4 q0 = vec4(v1, 1);
	vec4 q1 = vec4(v2, 1);
	vec4 q2 = vec4(v1 + v1 - lightPos, 0);
	vec4 q3 = vec4(v2 + v2 - lightPos, 0);

	gl_Position = gl_ProjectionMatrix*q0; EmitVertex();
	gl_Position = gl_ProjectionMatrix*q1; EmitVertex();
	gl_Position = gl_ProjectionMatrix*q2; EmitVertex();
	gl_Position = gl_ProjectionMatrix*q3; EmitVertex();
	EndPrimitive();
}

void main()
{
    vec3 lightPos = gl_LightSource[lightIndex].position.xyz;

    // Compute the triangle normal (un-normalized)
    // Note: this is different from the interpolated one
    vec3 N = cross( gl_in[2].gl_Position.xyz - gl_in[0].gl_Position.xyz, gl_in[4].gl_Position.xyz - gl_in[0].gl_Position.xyz );
    
    // Compute direction from this triangle to the light
    vec3 lightDir = lightPos - 
                (gl_in[0].gl_Position.xyz + gl_in[2].gl_Position.xyz + gl_in[4].gl_Position.xyz) / 3.0;
    
    //if we're facing the light
    if( dot(N, lightDir) > 0.0f )
    {
        // For each edge of the triangle, determine if it is a silhouette edge
        // If it is, extrude a quad from it in the direction away from the light
        DetectAndProcessSilhouette( N, gl_in[0].gl_Position.xyz, gl_in[2].gl_Position.xyz, gl_in[1].gl_Position, lightPos );
        DetectAndProcessSilhouette( N, gl_in[2].gl_Position.xyz, gl_in[4].gl_Position.xyz, gl_in[3].gl_Position, lightPos );
        DetectAndProcessSilhouette( N, gl_in[4].gl_Position.xyz, gl_in[0].gl_Position.xyz, gl_in[5].gl_Position, lightPos );
    }
}

[frag]

#version 150 compatibility
uniform int lightIndex;
void main()
{
    // Render light color for visualization purpose
    // In a normal shadow volume pass, color buffer will not be modified.
    gl_FragColor = gl_LightSource[lightIndex].diffuse * vec4(0.1, 0.1, 0.1, 0.1);
}

