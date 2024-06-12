# Puzzle 6
# --------

using Catlab


Pattern₆ = SymmetricGraph(3)
add_edge!(Pattern₆, 2, 3)

Host₆ = path_graph(SymmetricGraph, 6)

O_P₆ = ACSetTransformation(Overlap, Pattern₆; V=[1,3])
P_H₆ = homomorphism(Pattern₆, Host₆; initial=(V=[5,1,2],))

O_PC₆, PC_H₆ = pushout_complement(O_P₆, P_H₆)

to_graphviz(dom(PC_H₆))