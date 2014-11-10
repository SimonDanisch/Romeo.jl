{{GLSL_VERSION}}

in vec3  vertex;
out vec4 V;
void main(){

    V           = vec4(vertex,0);
    gl_Position = vec4(0,0,0,1);
}
