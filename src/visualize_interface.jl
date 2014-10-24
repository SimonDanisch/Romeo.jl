#################################################################################################################################
#Text Rendering:
TEXT_DEFAULTS = @compat Dict(
:Default => @compat Dict(
  :start            => Vec3(0.0),
  :offset           => Vec2(1.0, 1.5), #Multiplicator for advance, newline
  :color            => rgba(248.0/255.0, 248.0/255.0,242.0/255.0, 1.0),
  :backgroundcolor  => rgba(0,0,0,0),
  :model            => eye(Mat4),
  :newline          => -Vec3(0, getfont().props[1][2], 0),
  :advance          => Vec3(getfont().props[1][1], 0, 0),
  :screen           => first(SCREEN_STACK),
  :font             => getfont()
))

# High Level text rendering for one line or multi line text, which is decided by searching for the occurence of '\n' in text
visualize(text::String,                           style=Style(:Default); customization...) = visualize(style, text, mergedefault!(style, TEXT_DEFAULTS, customization))
# Low level text rendering for multiple line text
visualize(text::Texture{GLGlyph{Uint16}, 4, 2},   style=Style(:Default); customization...) = visualize(style, text, mergedefault!(style, TEXT_DEFAULTS, customization))

# END Text Rendering
#################################################################################################################################

#################################################################################################################################
#Surface Rendering:

SURFACE_DEFAULTS = @compat Dict(
:Default => @compat Dict(
    :primitive      => SURFACE(),     #can also be CUBES(), CIRCLES(), POINT()
    :xrange         => (-1,1),        # can also be a matrix
    :yrange         => (-1,1),        # can also be a matrix
    :color          => rgba(0,0,0,1), # can also be Array/Texture{RGB/RGBA, 1/2}, with "/" meaning OR. 
                                      # A 1D Array of color values is assumed to be a colormap.
                                      # A 2D Array can have higher or lower resolution, and will be automatically mapped on the data points.
    :lightposition  => Vec3(20, 20, -20), 
    :screen         => first(SCREEN_STACK),
    :modelmatrix    => eye(Mat4),
    :interpolate    => false,
    :normal_vector  => 0f0 # meaning, that normal vector needs to be calculated on the gpu
))

begin 
local PointType = Union(AbstractFixedVector, Real)
# Visualizes a matrix of 1D Values as a surface, whereas the values get interpreted as z-values
visualize{T <: PointType}(zpoints::Matrix{T},        attribute = :z,  style=Style(:Default); customization...) = visualize(style, zpoints, attribute, mergedefault!(style, SURFACE_DEFAULTS, customization))
visualize{T <: PointType}(zpoints::Texture{T, 1, 2}, attribute = :z,  style=Style(:Default); customization...) = visualize(style, zpoints, attribute, mergedefault!(style, SURFACE_DEFAULTS, customization))
visualize{T <: PointType}(x::Matrix{T}, y::Matrix{T}, z::Matrix{T},   style=Style(:Default); customization...) = visualize(style, zpoints, attribute, mergedefault!(style, SURFACE_DEFAULTS, customization))
end