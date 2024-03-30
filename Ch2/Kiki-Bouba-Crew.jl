#-----------------------------------#
    # For directed wiring diagrams
#-----------------------------------#
using AlgebraicDynamics.DWDDynam
using LabelledArrays
using Catlab.WiringDiagrams, Catlab.Programs, Catlab.Graphics

using OrdinaryDiffEq, Plots, Plots.PlotMeasures

# Define the composition pattern

mood_pattern = WiringDiagram([], [:Kiki, :Bouba, :"Bouba's Crew"])
Kiki_b = add_box!(mood_pattern, Box(:Kiki, [:Bouba_mood], [:Kiki_mood]))
Bouba_b = add_box!(mood_pattern, Box(:Bouba, [:Kiki_mood], [:Bouba_mood]))
Group_b = add_box!(mood_pattern, Box(:"Bouba's crew", [:Bouba_mood, :Group_mood], [:Staff_mood]))

add_wires!(mood_pattern, Pair[
    (Kiki_b, 1) => (Bouba_b, 1),
    (Bouba_b, 1)    => (Kiki_b, 1),
    (Bouba_b, 1)    => (Group_b, 1),
    (Group_b, 1)    => (Group_b, 2),
    (Kiki_b, 1) => (output_id(mood_pattern), 1),
    (Bouba_b, 1)    => (output_id(mood_pattern), 2),
    (Group_b, 1)    => (output_id(mood_pattern), 3)

])

#Draw the undirected wiring diagram
#to_graphviz(rabbitfox_pattern, labels=true, label_attr=:xlabel)
draw(d::WiringDiagram; labels=true) = to_graphviz(d,
  orientation=LeftToRight,
  labels=labels, label_attr=:xlabel
)

draw(mood_pattern, labels=true)


#------------------------------#
# Define the primitive systems #
# Each person's mood level is a number in the interval [-5, 5] 
# -5 is uber grumpy
# +5 is uber excited 
#  0 is neutral

# Each person has a susceptability_factor [0,1] caputring the susceptibility of other person's mood during an interaction
# Each person has a calmDown_factor [0,1] capturing the rate at which they approach the neutral state if by themselves (no interaction) 
# When each person has reached their maximum grumpiness or maximum excitment, the external connection breaks, Lets call this mood_tolerance 

# change_in_mood = external_mood * susceptability - mood * calmdown_rate (if mood > gumpiness_tolerance and mood < excitement_tolreance)
# This model has a major flaw, suppose the tolerance limit is reached, then the connection is broken only for the person whose tolerance limit 
# has been reached. The other person is still affected by and the connection is not broken at his/her end. This makes no sense. The connection 
# must be treated as a shared resource which is either available to both or unavailable to both simultaneously. 
#------------------------------#

dotmood_Kiki(mood, input, param, t) = # [ - mood[1] * param.calmdown_rate[1] ]
 begin
    if ( mood[1] <= param.grumpiness_tolerance[1] || mood[1] >= param.excitement_tolerance[1] )
     [ - (mood[1] * param.calmdown_rate[1]) ] # pay attention to the negative sign in the front; here, change in mood is the amount by which the mood moves towards zero
    else
     [ input[1] * param.susceptability[1] - mood[1] * param.calmdown_rate[1] ]
    end
end 

# Bouba is a chef at a star restaurant 
dotmood_Bouba(mood, input, param, t) = 
begin
   if ( mood[1] <= param.grumpiness_tolerance[2] || mood[1] >= param.excitement_tolerance[2] )
      [ - mood[1] * param.calmdown_rate[2] ]
    else
      [ input[1] * param.susceptability[2] - mood[1] * param.calmdown_rate[2] ]
    end
end 

# if the staff becomes too grumpy, they take a vacation and go away to calm down :)
dotmood_Staff(mood, input, param, t) = 
begin
   if ( mood[1] <= param.grumpiness_tolerance[3] )
      [ - mood[1] * param.calmdown_rate[3] ]
    else
      [ input[1] * param.susceptability[3] - input[2] * param.calmdown_rate[3] ]
    end
end 

# The group does not show their actual mood to the external world, they show about 75% of how they feel
Readout_Group(state, p, t) = 0.6 * state[1] 

# 1 input, 1 state, 1 output, dynamics, readout
Kiki_m = ContinuousMachine{Float64}(1,1,1, dotmood_Kiki, (mood_level, p, t) -> mood_level)
Bouba_m = ContinuousMachine{Float64}(1,1,1, dotmood_Bouba, (mood_level, p, t) -> mood_level)
Staff_m = ContinuousMachine{Float64}(2,1,1, dotmood_Bouba, Readout_Group)
# Compose
mood_system = oapply(mood_pattern, [Kiki_m, Bouba_m, Staff_m]) # 

initial_moods = [4.5, -2.8, 0.5] # Kiki, Bouba, Group
params = LVector(susceptability=[0.2, 0.1, 0.5], calmdown_rate=[.05, .03, 0.01], grumpiness_tolerance=[-4,-4.8, -3.5], excitement_tolerance=[4.5,4])
tspan = (0.0, 100.0)

prob = ODEProblem(mood_system, initial_moods, tspan, params)
sol = solve(prob, Tsit5())

plot(sol, mood_system, params,
    lw=2, title = "Life of Bouba!",
    xlabel = "Time in Minutes", ylabel = "Mood level"
)