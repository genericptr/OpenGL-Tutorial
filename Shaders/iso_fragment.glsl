#version 330 core
out vec4 final_color;

in vec2 vertex_texture;
in float visibility;
in vec3 surfaceNormal;
in vec3 toLightVector[4];
in vec3 toCameraVector;

uniform sampler2D sampleTexture;
uniform float shineDamper;
uniform float reflectivity;
uniform float ambientLight;
uniform vec3 skyColor;
uniform vec3 lightColor[4];
uniform vec3 attenuation[4];

//const	float ambientLight = 0.3;

void main()
{
    //vec4 diffuse_color = texture(sampleTexture, vertex_texture);
		vec4 diffuse_color = vec4(1, 0, 0, 1);

		// diffuse lighting
		vec3 diffuse_light = vec3(0);
		for(int i = 0; i < 1; i++)
		{
			float dist = length(toLightVector[i]);
			float attenFactor = attenuation[i].x + (attenuation[i].y * dist) + (attenuation[i].z * dist * dist);
			vec3 unitNormal = normalize(surfaceNormal);
			vec3 unitLightVector = normalize(toLightVector[i]);
			float nDot1 = dot(unitNormal, unitLightVector);
			float brightness = max(nDot1, 0);
			diffuse_light = diffuse_light + (brightness * lightColor[i]) / attenFactor;
		}
		diffuse_light = max(diffuse_light, ambientLight);
		
		// add color/light
		diffuse_color = vec4(diffuse_light, 1.0) * diffuse_color;
		
		// mix fog
		final_color = mix(vec4(skyColor, 1.0), diffuse_color, 1);
		//final_color = diffuse_color;
}
