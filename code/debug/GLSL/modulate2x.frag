uniform sampler2D texture;
uniform vec3 viewPos;
uniform vec3 viewNormal;

varying vec2 texture_coordinate;
varying vec3 Position;
varying vec4 vertColor;

void main()
{
	vec4 texcolor = texture2D(texture, texture_coordinate);
	vec4 color = texcolor;
	
	vec4 mid = vec4(0.5,0.5,0.5,0.0);
	vec4 cdelta = (mid - color);
	
	color = mid - (cdelta * vertColor.a);
	
	vec4 vd = vec4(1.0,1.0,1.0,1.0) - vertColor;
	
	color = color - (cdelta * vd)*2.0*vertColor.a;
	
	gl_FragColor = color;
}