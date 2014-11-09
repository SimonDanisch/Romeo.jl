{{GLSL_VERSION}}

{{in}} vec3 V;

{{out}} vec4 minbuffer;
{{out}} vec4 maxbuffer;

void main()
{
	minbuffer = vec4(V,0);
	maxbuffer = vec4(-V,0);
}