using GLAbstraction, Reactive, Compat, ImmutableArrays
import GLFW.Window
immutable Screen
    id::Symbol
    area
    parent::Screen
    children::Vector{Screen}
    inputs::Dict{Symbol, Any}
    renderlist::Vector{RenderObject}

    hidden::Signal{Bool}
    hasfocus::Signal{Bool}

    perspectivecam::PerspectiveCamera
    orthographiccam::OrthographicCamera
    nativewindow::Window
    counter = 1

    function Screen(
        area,
        children::Vector{Screen},
        inputs::Dict{Symbol, Any},
        renderlist::Vector{RenderObject},

        hidden::Signal{Bool},
        hasfocus::Signal{Bool},

        perspectivecam::PerspectiveCamera,
        orthographiccam::OrthographicCamera,
        nativewindow::Window)
        parent = new()
        new(symbol("display"*string(counter+=1)), area, parent, children, inputs, renderlist, hidden, hasfocus, perspectivecam, orthographiccam, nativewindow)
    end
end

inputs = @compat Dict(
        :insidewindow                   => Input(false),
        :open                           => Input(true),
        :hasfocus                       => Input(false),

        :window_size                    => Input(Vector4(0,0,20,20)),
        :windowposition                 => Input(Vector2(0)),

        :unicodeinput                   => Input(Char[]),

        :buttonspressed                 => Input(IntSet()),
        :buttondown                     => Input(0),
        :buttonreleased                 => Input(0),

        :mousebuttonspressed            => Input(IntSet()),
        :mousedown                      => Input(0),
        :mousereleased                  => Input(0),

        :mouseposition                  => Input(Vector2(0.0)),

        :scroll_x                       => Input(0),
        :scroll_y                       => Input(0)
    )
    children = Screen[]
    mouse    = filter(Vector2(0.0), inputs[:mouseposition]) do mpos
        !any(children) do screen 
            isinside(screen.area.value, mpos)
        end
    end
    camera_input = merge(inputs, Dict(:mouseposition=>mouse))
    pcamera      = PerspectiveCamera(camera_input, Vec3(2), Vec3(0))
    pocamera     = OrthographicPixelCamera(camera_input)

    screen = Screen(lift(x->Rectangle(x...), inputs[:window_size]), children, inputs, RenderObject[], Input(false), inputs[:hasfocus], pcamera, pocamera, Window(C_NULL))