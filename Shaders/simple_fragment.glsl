#version 330 core
out vec4 final_color;

in vec2 vertex_texture;
in vec3 vertex_color;
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
    vec4 diffuse_color = texture(sampleTexture, vertex_texture);
		
		// setup lights
		vec3 unitVectorToCamera = normalize(toCameraVector);
		vec3 unitNormal = normalize(surfaceNormal);
		
		vec3 diffuse_light = vec3(0);
		vec3 specular_light = vec3(0);
		
		for(int i = 0; i < 4; i++)
		{
			float dist = length(toLightVector[i]);
			float attenFactor = attenuation[i].x + (attenuation[i].y * dist) + (attenuation[i].z * dist * dist);
				
			// diffuse lighting
			vec3 unitLightVector = normalize(toLightVector[i]);
			float nDot1 = dot(unitNormal, unitLightVector);
			float brightness = max(nDot1, 0);
			diffuse_light = diffuse_light + (brightness * lightColor[i]) / attenFactor;

			// specular lignting
			vec3 lightDirection = -unitLightVector;
			vec3 reflectedLightDirection = reflect(lightDirection, unitNormal);
			float specularFactor = dot(reflectedLightDirection, unitVectorToCamera);
			specularFactor = max(specularFactor, 0.0);
			float dampedFactor = pow(specularFactor, shineDamper);
			specular_light = specular_light + (dampedFactor * reflectivity * lightColor[i]) / attenFactor;
		}
		diffuse_light = max(diffuse_light, ambientLight);
		
		// add color/diffuse/specular
		diffuse_color = vec4(diffuse_light, 1.0) * diffuse_color + vec4(specular_light, 1.0);
		//diffuse_color = vec4(diffuse, 1.0) * diffuse_color;
		
		// mix fog
		final_color = mix(vec4(skyColor, 1.0), diffuse_color, visibility);
		//final_color = vec4(tangent_color, 1.0);
		//final_color = diffuse_color;
}
