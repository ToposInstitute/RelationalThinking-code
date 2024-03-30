# Exercise 3
#-----------

using Catlab

# The graphs here are all discrete (no edges)
Overlap3, G2, G3 = SymmetricGraph(0), SymmetricGraph(3), SymmetricGraph(2)

# morphisms out of an empty graph are themselves 'empty'
# (they require no data other than the domain and codomain)
G2_map = ACSetTransformation(Overlap3, G2)
G3_map = ACSetTransformation(Overlap3, G3)
# We glue together the discrete graphs along the empty overlap
colim = colimit(Span(G2_map, G3_map));

to_graphviz(apex(colim))