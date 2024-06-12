using Catlab

# Graph with a single isolated vertex
Overlap1 = SymmetricGraph(1)
# Create a triangle
G2 = cycle_graph(SymmetricGraph, 3)
# Initialize this graph as an isolated edge
G3 = path_graph(SymmetricGraph, 2)
# Then modify it to add a loop to vertex #2
add_edge!(G3, 2, 2)

# There are three possible morphisms from the isolated vertex into a graph
# with three vertices. Because these three vertices are equivalent due to
# the symmetry of the triangle, it doesn't matter which one we pick. So,
# rather than manually specifying how Overlap1 matches to parts of G2, we
# use the automatic homomorphism search which will pick an arbitrary one.
G2_map = homomorphism(Overlap1, G2)

# Because the two vertices of G3 are *not* equivalent (one has a loop,
# the other doesn't) we have to be more precise in our construction of
# the map from Overlap1 into G3. The only data required is saying where
# the vertex of Overlap1 is mapped to. We send it to vertex#1, which is
# the one which does *not* have a loop.
G3_map = ACSetTransformation(Overlap1, G3; V=[1])

# Glue together G2 and G3 along their common overlap, Overlap1
colim = colimit(Span(G2_map, G3_map));

# Visualize the result
to_graphviz(apex(colim))