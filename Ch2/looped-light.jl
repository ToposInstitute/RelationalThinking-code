#-----------------------------------#
    # For directed wiring diagrams
#-----------------------------------#
using AlgebraicDynamics.DWDDynam
using LabelledArrays
using Catlab.WiringDiagrams, Catlab.Programs, Catlab.Graphics
using OrdinaryDiffEq
using PrettyTables

# Define the composition pattern
loopedBulb_blueprint = WiringDiagram([], [:Bulb1_state, :Bulb2_state, :Bulb3_state])

BulbBox = Box(:Bulb, [:Neighbor_state], [:My_state])

# add three boxes
Box1 = add_box!( loopedBulb_blueprint, BulbBox)
Box2 = add_box!( loopedBulb_blueprint, BulbBox)
Box3 = add_box!( loopedBulb_blueprint, BulbBox)


add_wires!(loopedBulb_blueprint, Pair[
    (Box1, 1)    => (output_id(loopedBulb_blueprint), 1), # output of Box1 connected to 1st output of larger box
    (Box2, 1)    => (output_id(loopedBulb_blueprint), 2), # output of Box2 connected to 2nd output of larger box
    (Box3, 1)    => (output_id(loopedBulb_blueprint), 3), # output of Box3 connected to 3rd output of larger box
    (Box1, 1)    => (Box2, 1), # output of Box1 connected to 1st input Box 2
    (Box2, 1)    => (Box3, 1), # output of Box2 connected to 1st input Box 3
    (Box3, 1)    => (Box1, 1), # output of Box3 connected to 1st input Box 1
])

#Draw the undirected wiring diagram
#to_graphviz(rabbitfox_pattern, labels=true, label_attr=:xlabel)
draw(d::WiringDiagram; labels=true) = to_graphviz(d,
  orientation=LeftToRight,
  labels=labels, label_attr=:xlabel
)

draw(loopedBulb_blueprint, labels=true)

@enum BulbState begin
    BULB_ON = true
    BULB_OFF = false
end

Transition(state, input, param, t) = [input[1]] 

Readout(state, p, t) = state

# 1 input, 1 state, 1 output, dynamics, time
Bulb1 = Bulb2 = Bulb3 = DiscreteMachine{Bool}(1,1,1, Transition, Readout)

# Compose
Looped_bulbs = oapply(loopedBulb_blueprint, [Bulb1, Bulb2, Bulb3]) 

initial_state = [Bool(BULB_ON), Bool(BULB_OFF), Bool(BULB_OFF)] # needs to be an array

total_span=10
tspan = (1, total_span)


prob = DiscreteProblem(Looped_bulbs, initial_state, tspan, nothing) #p=nothing (no parameters)
sol = solve(prob, FunctionMap();)

getState(state) = if(state) "ON" else "--" end

map(sol) do u
    return (Bulb_1= getState(u[1]), Bulb_2=getState(u[2]), Bulb_3=getState(u[3]))
end |> pretty_table


#------ Javis code ----------#

# preparing color sequence to print
getStateColor(state) = if(state) "gold" else "white" end
result =  map(sol) do u
    return (getStateColor(u[1]), getStateColor(u[2]), getStateColor(u[3]))
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

radius = 15

state_seq = map(sol) do u
    return if(u[1]) "gold" else "white" end
end

for num in 1:total_span
Object( num:num,
        (args...) ->
            electrode(
                Point(-50,50),
                result[num][1],
                "black",
                :fill,
                radius,
            ),
    )
Object( 
        (args...) ->
            electrode(
                Point(0,50),
                result[num][2],
                "black",
                :fill,
                radius,
            ),
    )
Object( 
        (args...) ->
            electrode(
                Point(50,50),
                result[num][3],
                "black",
                :fill,
                radius,
            ),
    )
end
    
render(video, pathname = "Javis-gifs/looped-light.gif", framerate = 1)