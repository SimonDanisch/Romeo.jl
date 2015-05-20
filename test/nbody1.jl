using ODE
using GLVisualize, AbstractGPUArray, GLAbstraction, MeshIO, GeometryTypes, Reactive, ColorTypes

function F(t,y)
    
    #Number of Planets (note we're solving the n-body problem, rather than just a 3-body problem)
    n = int(length(y)/6)
    
    #Extract current position and velocity
    r = zeros(n,3)
    v = zeros(n,3)
    for i=1:n
        r[i,:] = y[(i-1)*6+1:(i-1)*6+3]
        v[i,:] = y[(i-1)*6+4:(i-1)*6+6]
    end
        
    #Calculate spatial derivatives
    drdt = v
        
    #Work out velocity derivatives (ie accelerations)
    dvdt = zeros(n,3)
    for i = 1:n
        for j = 1:n
            if i != j
                dvdt[i,:] += -G*m[j]*(r[i,:]-r[j,:])/(norm(r[i,:]-r[j,:])^3)
            end
        end
    end
    
    #Combine back together into dydt vector
    dydt = zeros(6*n)
    for i = 1:n
        dydt[6(i-1)+1] = drdt[i,1]
        dydt[6(i-1)+2] = drdt[i,2]
        dydt[6(i-1)+3] = drdt[i,3]
        dydt[6(i-1)+4] = dvdt[i,1]
        dydt[6(i-1)+5] = dvdt[i,2]
        dydt[6(i-1)+6] = dvdt[i,3]
    end
    return dydt
end  # Function F(t,y)

function worldCreate()

   #Set the masses
   global m 
   m = [5,4,3,5]
   n = length(m)

   #Set the gravitational field strength
   global G
   G = .2

   #Set initial positions and velocities 
   r0 = zeros(n,3)
   r0[1,:] = [1.0,-1.0,1.0]
   r0[2,:] = [1,3,0.0]
   r0[3,:] = [-1,-2,0.0]
   r0[4,:] = [0,0,0.0]

   #Select a reasonable set of speeds (avoid cases where
   #       a singularity happens stopping the ode solver. Arrange for
   #       a null momentum so that the world stays on the screen. )
   v0 = rand(n,3)
   mv = m' * v0 / sum(m)
   v0 = v0 - ones(4,1) * mv
    
   # Aggregate initial data (position, speed)  in a format that
   # the ODE solver and function F handle
   y0 = zeros(6*n)
   for i = 1:n
     y0[6(i-1)+1] = r0[i,1]
     y0[6(i-1)+2] = r0[i,2]
     y0[6(i-1)+3] = r0[i,3]
     y0[6(i-1)+4] = v0[i,1]
     y0[6(i-1)+5] = v0[i,2]
     y0[6(i-1)+6] = v0[i,3]
   end
    return (m,y0,G)
end

function worldOperate(y0)
   #Solve the system
   tf = 10
   stepsPerUnitTime = 200
   tspan = linspace(0,tf,tf*stepsPerUnitTime)
   t,y = ode23s(F, y0, tspan; points=:specified);
   return t,y
end

function send_frame(i, planets)
    p = planets[i, 1:4]
    reshape(p, (2,2))
end

function reformatData(m, t, y)
    #Extract the data into a useful form 
    n = length(m)
    ymat= hcat(y...)

    # gather some results, do we need to construct such an array
    # positions
    rcoords = sort([  [6(i-1)+1 for i = 1:n],
                      [6(i-1)+2 for i = 1:n],
                      [6(i-1)+3 for i = 1:n]])
    rcoords = convert(Array{Int64,1}, rcoords)
    const r = map(Float32, ymat[rcoords,:])
    
    const planets = hcat( [ reinterpret(Point3{Float32},
                                        r[3(i-1)+1:3(i-1)+3,:],
                                        (size(r, 2),)) for i=1:n]...)
    println("size(planets[:, 1]=", size(planets[:, 1]))                                            
    return planets
end



function doPlanets(time_i)                          #  sc::Screen,cam::Camera) # beware 3rd result   
    m,y0,G = worldCreate()
    t,y    = worldOperate(y0)  
    planets = reformatData(m, t, y)
    len= size(planets, 1)

    const positions     = lift(send_frame, time_i, Input(planets))
    const robj          = visualize(positions, model=scalematrix(Vec3(0.1f0)))


    const robjPl  = [ visualize(
    				reshape(planets[:, i], (round(Int,len/20), 20)),
				particle_color=RGBA(rand(Float32,3)..., 0.4f0),
    				model=scalematrix(Vec3(0.01f0)))
                       for i=1:4]

    return (robj, robjPl, len) 
end




const time_i = Input(1)    
robj, planet_lines, lenPlanet =   doPlanets(time_i)    
push!(GLVisualize.ROOT_SCREEN.renderlist, robj)
append!(GLVisualize.ROOT_SCREEN.renderlist, planet_lines)


    
@async renderloop() 
# you can also "manually" push into the signal. For that the renderloop has to be started asynchronous
# while the loop that updates the signal is the blocking one
while GLVisualize.ROOT_SCREEN.inputs[:open].value
    yield()
    push!(time_i, mod1(time_i.value+1, lenPlanet))
end



