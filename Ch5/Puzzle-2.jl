# Exercise 2
#-----------

using Catlab

# Graph with a single isolated vertex
Overlap1 = SymmetricGraph(1)
# Create a triangle
G2 = cycle_graph(SymmetricGraph, 3)
# Initialize this graph as an isolated edge
G3 = path_graph(SymmetricGraph, 2)
# Then modify it to add a loop to vertex #2
add_edge!(G3, 2, 2)

# Our overlap is an isolated edge
Overlap2 = path_graph(SymmetricGraph, 2)

# Again, the three possible morphisms out of Overlap2 (each of
# which picks an edge of the triangle, G2) are equivalent, so
# we don't need to pick a specific one: we let the automatic
# search algorithm find it for us.
G2_map = homomorphism(Overlap2, G2)

# Again, we need to be more precise in how we map into G3
# because it matters whether or not the overlapping edge is
# the loop or the other edge. Here, we specify the loop by
# initializing the homomorphism search (via the `initial`
# keyword). In this case, the morphism is fully determined
# once we declare that both vertices of Overlap2 are sent
# to vertex#2 in G3.
G3_map = homomorphism(Overlap2, G3; initial=(V=[2, 2],))

# Once again we glue together G2 and G3 along Overlap2
colim = colimit(Span(G2_map, G3_map));

to_graphviz(apex(colim))