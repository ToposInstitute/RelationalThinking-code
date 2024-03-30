# Example 2
#-----------

using Catlab
using AlgebraicRewriting.CSets


K = SymmetricGraph(1)
L = path_graph(SymmetricGraph, 2)
G = path_graph(SymmetricGraph, 3)

# There is only one homomorphism (up to symmetry)
# So we can pick an arbitrary one
p = homomorphism(K, L)
m = homomorphism(L, G)

# We can check whether or not the pushout complement exists
can_pushout_complement(p, m)

# We can get a list of the specific violations
gluing_conditions(ComposablePair(p, m))
