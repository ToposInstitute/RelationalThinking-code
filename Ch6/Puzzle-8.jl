# Puzzle 8
#---------

using Catlab

fromR, fromPC = pushout(O_PC₆, add)
to_graphviz(codom(fromR))