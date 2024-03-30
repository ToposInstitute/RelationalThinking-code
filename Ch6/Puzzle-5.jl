# Puzzle 5
# --------

using Catlab
using AlgebraicRewriting.CSets

Overlap, Pattern₅, Host₅ = SymmetricGraph.([2, 4, 6])
O_P₅ = ACSetTransformation(Overlap, Pattern₅; V=[1,2])
P_H₅ = ACSetTransformation(Pattern₅, Host₅; V=[1,1,2,2])
O_PC₅, PC_H₅ = pushout_complement(O_P₅, P_H₅)

to_graphviz(dom(PC_H₅))