# Puzzle 3
#-----------

using Catlab

pattern = path_graph(SymmetricGraph, 3)
host = cycle_graph(SymmetricGraph, 3)

# There are 12 matches because the path can start 
# at any of the three vertices of the cycle. 
# There are two directions each can go. And for each we decide
# for both edges whether they go clockwise or not, 
# so that is 3 x 2 x 2 independent choices.

matches = homomorphisms(pattern, host)