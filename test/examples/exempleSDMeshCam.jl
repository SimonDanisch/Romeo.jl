#Incomplete example sniplets taken from GLPlot branch meshes:
vert = "
{{GLSL_VERSION}}

{{in}} vec3 vertex;
{{in}} vec3 normal;
{{in}} vec2 uv;

// data for fragment shader
{{out}} vec3 o_normal;
{{out}} vec3 o_lightdir;
{{out}} vec3 o_vertex;
{{out}} vec2 o_uv;

uniform mat4 projection, view, model;
uniform vec3 light[4];
uniform vec3 eyeposition;


const int position = 3;


void render(vec3 vertex, vec3 normal, vec2 uv,  mat4 model)
{
    mat3 normalmatrix           = mat3(transpose(inverse(view*model)));
    vec4 position_camspace      = view * model * vec4(vertex, 1);
    vec4 lightposition_camspace = view * vec4(light[position],1);
    // normal in world space
    o_normal            = normalize(normalmatrix * normal);
    // direction to light
    o_lightdir          = normalize(lightposition_camspace.xyz - position_camspace.xyz);
    // direction to camera
    o_vertex            = -position_camspace.xyz;
    // texture coordinates to fragment shader
    o_uv                = uv;
    // screen space coordinates of the vertex
    gl_Position         = projection * position_camspace; 
}

void main(){
    render(vertex, normal, uv, model);
}
"

frag = "
{{GLSL_VERSION}}

{{in}} vec3 o_normal;
{{in}} vec3 o_lightdir;
{{in}} vec3 o_vertex;
{{in}} vec2 o_uv;


const int diffuse = 0;
const int ambient = 1;
const int specular = 2;

const int bump = 3;
const int specular_exponent = 3;
const int position = 3;

uniform vec3 material[4];
uniform vec3 light[4];
uniform float textures_used[4];



uniform sampler2DArray texture_maps;



vec4[4] set_textures(float texused[4], vec3 mat[4], vec2 uv)
{
    vec4 merged_material[4] = vec4[4]( 
        vec4(mat[0],1),
        vec4(mat[1],1),
        vec4(mat[2],1),
        vec4(mat[3],1));

    if(texused[diffuse]  >= 0)
        merged_material[diffuse] = texture(texture_maps, vec3(vec2(uv.x, 1-uv.y), texused[diffuse]));
    if(texused[ambient]  >= 0)
        merged_material[ambient] = texture(texture_maps, vec3(vec2(uv.x, 1-uv.y), texused[ambient]));
    if(texused[specular]  >= 0)
        merged_material[specular] = texture(texture_maps, vec3(vec2(uv.x, 1-uv.y), texused[specular]));
    //merged_material[bump]       = texused[bump] >= 0 ? texture(texture_maps, vec3(uv, texused[bump])) : vec4(mat[bump], 1);
    return merged_material;
}


{{out}} vec4 fragment_color;

vec4 blinn_phong(vec3 N, vec3 V, vec3 L, vec3 light[4], vec4 mat[4])
{

    float diff_coeff = max(dot(L,N), 0.0);

    // specular coefficient
    vec3 H = normalize(L+V);
    
    float spec_coeff = pow(max(dot(H,N), 0.0), mat[specular_exponent].x);
    if (diff_coeff <= 0.0)
        spec_coeff = 0.0;

    // final lighting model
    return  vec4(
            light[ambient]  * mat[ambient].rgb  +
            light[diffuse]  * mat[diffuse].rgb  * diff_coeff +
            light[specular] * mat[specular].rgb * spec_coeff, 
            1);
}


void main(){

    vec3 spec = vec3(0.0);
    vec3 L = normalize(o_lightdir);
    vec3 V = normalize(o_vertex);
    vec3 N = normalize(o_normal);

    vec4 mat[4] = set_textures(textures_used, material, o_uv);

    fragment_color = blinn_phong(N, V, L, light, mat);
}
"

using ImmutableArrays
using Compat
Vec3= Vector3
const light       = Vec3[Vec3(1.0,0.9,0.8), Vec3(0.01,0.01,0.1), Vec3(1.0,0.9,0.9),
                    Vec3(10.0, 10.0,10.0)]

function toopengl(mesh::GLMesh{(Face{GLuint}, Normal{Float32}, Vertex{Float32})};
                  camera=pcamera)
    if isempty(MESH_SHADER)
        push!(MESH_SHADER, TemplateProgram(Pkg.dir("GLPlot", "src", "shader", "standard.vert"),
                                           Pkg.dir("GLPlot", "src", "shader", "phongblinn.frag")))
    end
    
    shader = first(MESH_SHADER)
    #cam     = customizations[:camera]
    #light   = customizations[:light]
    #mesh[:vertex] = unitGeometry(mesh[:vertex])

    data = merge(collect_for_gl(mesh), @compat(Dict(
        :view            => camera.view,
        :projection      => camera.projection,
        :model           => eye(Mat4),
        :eyeposition     => camera.eyeposition,
        :light           => light,
        :uv              => Vec2(-1),
    )))
    ro = RenderObject(data, shader)
    prerender!(ro, glEnable, GL_DEPTH_TEST, glDepthFunc, GL_LEQUAL, glDisable, GL_CULL_FACE,
               enabletransparency)
    postrender!(ro, render, ro.vertexarray)
    ro
end
