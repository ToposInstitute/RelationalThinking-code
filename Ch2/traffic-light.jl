#-----------------------------------#
    # For directed wiring diagrams
#-----------------------------------#
using AlgebraicDynamics.DWDDynam
using LabelledArrays
using Catlab.WiringDiagrams, Catlab.Programs, Catlab.Graphics
using OrdinaryDiffEq
using PrettyTables

# Define the composition pattern
trafficlight_blueprint = WiringDiagram([], 
    [:Red, :Green, :Yellow])

controllerBox = Box(:Controller, [], [:Red, :Green, :Yellow])
RedBulb = Box(:Red, [:State], [:State])
GreenBulb = Box(:Green, [:State], [:State])
YellowBulb = Box(:Yellow, [:State], [:State])



#add four boxes
# add three boxes
Red_b = add_box!( trafficlight_blueprint, RedBulb)
Green_b = add_box!( trafficlight_blueprint, GreenBulb)
Yellow_b = add_box!( trafficlight_blueprint, YellowBulb)
Controller_b = add_box!( trafficlight_blueprint, controllerBox)

add_wires!(trafficlight_blueprint, Pair[
    (Red_b, 1)    => (output_id(trafficlight_blueprint), 1), # output of Box1 connected to 1st output of larger box
    (Green_b, 1)    => (output_id(trafficlight_blueprint), 2), # output of Box3 connected to 3rd output of larger box
    (Yellow_b, 1)    => (output_id(trafficlight_blueprint), 3), # output of Box2 connected to 2nd output of larger box
    (Controller_b, 1)    => (Red_b, 1), # output of Box1 connected to 1st input Box 2
    (Controller_b, 2)    => (Green_b, 1), # output of Box2 connected to 1st input Box 3
    (Controller_b, 3)    => (Yellow_b, 1), # output of Box3 connected to 1st input Box 1
])

draw(d::WiringDiagram; labels=true) = to_graphviz(d,
  orientation=LeftToRight,
  labels=labels, label_attr=:xlabel
)

draw(trafficlight_blueprint, labels=true)

BulbTransition(state, input, param, t) = [input[1]] 

ControllerTransition(state, input, param, t) = begin
    if(state[1] == true && state[2] == false && state[3] == false)  #Red is ON, the rest of OFF
        [false, true, false] 
    elseif(state[1] == false && state[2] == true && state[3] == false)  # Green is ON
        [false, false, true]
    elseif(state[1] == false && state[2] == false && state[3] == true)  # Yellow is ON, the rest is OFF
        [true, false, false]
    else #non-sense 
        [true, false, false]
    end
end

Readout(state, p, t) = state

# input, state, output, dynamics, time
Red_m = Green_m = Yellow_m = DiscreteMachine{Bool}(1,1,1, BulbTransition, Readout)
Controller_m = DiscreteMachine{Bool}(0,3,3, ControllerTransition, Readout)

# Compose
TrafficLight_m = oapply(trafficlight_blueprint, [Red_m, Green_m, Yellow_m, Controller_m]) 

#running the code
#first three states represent controller, last three states represent initial states of the light
initial_states = [true, false, false, false, true, false] 
inputs = []

total_span=10
tspan = (1, total_span)

prob = DiscreteProblem(TrafficLight_m, initial_states, inputs, tspan, nothing) #p=nothing (no parameters)
sol = solve(prob, FunctionMap();) 

#= map(sol) do u
    return (Red=u[4], Green=u[5], Yellow=u[6])
end |> pretty_table =#

map(sol) do u
    return  (Red=if(u[4]) "ON" else "--" end, Green=if(u[5]) "ON" else "--" end, Yellow=if(u[6]) "ON" else "--" end )
end |> pretty_table

#------ Javis code ----------#

# preparing color sequences to print
getStateColor1(state) = if(state) "red" else "white" end
red_seq =  map(sol) do u
    return (getStateColor1(u[1]))
end

getStateColor2(state) = if(state) "green" else "white" end
green_seq =  map(sol) do u
    return (getStateColor2(u[2]))
end

getStateColor3(state) = if(state) "gold" else "white" end
yellow_seq =  map(sol) do u
    return (getStateColor3(u[3]))
end

using Javis

video = Video(500, 500)

function ground(args...)
    background("white")
    sethue("black")
end

anim_background = Background(1:10, ground) # same as tspan

function electrode(
    p = O,
    fill_color = "white",
    outline_color = "black",
    action = :fill,
    radius = 25,
)
    sethue(fill_color)
    circle(p, radius, :fill)
    sethue(outline_color)
    circle(p, radius, :stroke)
end

function info_box(video, object, frame)
    fill_color = "black"
    sethue(fill_color)
    setopacity(0.8)
    Javis.box(0, 0, 100, 220, :fillpreserve)
end

radius = 25

Object(info_box)

for num in 1:total_span
Object( num:num,
        (args...) ->
            electrode(
                Point(0,-65),
                red_seq[num],
                "black",
                :fill,
                radius,
            ),
    )
Object( 
        (args...) ->
            electrode(
                Point(0,0),
                yellow_seq[num],
                "black",
                :fill,
                radius,
            ),
    )
Object( 
        (args...) ->
            electrode(
                Point(0,65),
                green_seq[num],
                "black",
                :fill,
                radius,
            ),
    )

end
    
render(video, pathname = "Javis-gifs/traffic-light.gif", framerate = 1)