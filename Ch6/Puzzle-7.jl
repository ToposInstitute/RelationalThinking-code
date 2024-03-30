# Puzzle 7
#---------

using Catlab
using AlgebraicRewriting

# Monic=true enforces that the two vertices in Overlap are not mapped to a
# single vertex in the single-edge graph.
add = homomorphism(Overlap, path_graph(SymmetricGraph, 2); monic=true)

fromR, fromPC = pushout(O_PC₅, add)
to_graphviz(codom(fromR))