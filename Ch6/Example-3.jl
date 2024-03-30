# Example 3
#----------------------------------------
# (K, L, p: K->L are all the same)
#----------------------------------------

using Catlab
using AlgebraicRewriting.CSets

G = @acset SymmetricGraph begin V=1; E=2; src=[1,1]; tgt=[1,1]; inv=[2,1] end
m = homomorphism(L, G)

# We can check whether or not the pushout complement exists
can_pushout_complement(p, m)

# We can get a list of the specific violations
gluing_conditions(ComposablePair(p, m))