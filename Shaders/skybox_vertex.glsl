#version 330 core

// attributes
layout (location=0) in vec3 position;

out vec3 textureCoords;

uniform mat4 projTransform;
uniform mat4 viewTransform;

void main(void){
	
	gl_Position = projTransform * viewTransform * vec4(position, 1.0); 
	textureCoords = position;
	
}