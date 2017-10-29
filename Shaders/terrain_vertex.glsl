#version 330 core

// attributes
layout (location=0) in vec3 position;
layout (location=1) in vec3 in_color;
layout (location=2) in vec2 in_texture;
layout (location=3) in vec3 in_normal;

// output
out vec2 vertex_texture;
out float visibility;
out vec3 surfaceNormal;
out vec3 toLightVector[4];
out vec3 toCameraVector;

// constants
const float density = 0.02;
const float gradient = 1.5;

// uniforms
uniform mat4 projTransform;
uniform mat4 modelTransform;
uniform mat4 viewTransform;
uniform vec3 lightPosition[4];

void main()
{
	vec4 worldPosition = modelTransform * vec4(position, 1.0);
	vec4 positionRelativeToCamera = viewTransform * worldPosition;
	vec4 finalTransform = projTransform * positionRelativeToCamera;
	
	gl_Position = finalTransform;
	
	// lignting
	vertex_texture = in_texture * 20.0;
	
	surfaceNormal = (modelTransform * vec4(in_normal, 0.0)).xyz;
	for(int i = 0; i < 4; i++)
	{
		toLightVector[i] = lightPosition[i] - worldPosition.xyz;
	}
	toCameraVector = (inverse(viewTransform) * vec4(0, 0, 0, 1)).xyz - worldPosition.xyz;
	
	// fog visibility
	float dist = length(positionRelativeToCamera.xyz);
	visibility = exp(-pow((dist * density), gradient));
	visibility = clamp(visibility, 0.0, 1.0);
}
