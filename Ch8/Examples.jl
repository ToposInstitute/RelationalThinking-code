using Catlab
using DataMigrations
using AlgebraicRewriting

function make_cache(type::Type, schema::Presentation, subdir::Union{String,Nothing}=nothing)
  if subdir !== nothing
    cache_dir = mkpath(joinpath(@__DIR__, "cache", subdir))
  else
    cache_dir = mkpath(joinpath(@__DIR__, "cache"))
  end
  cache = Dict(Iterators.map(ob -> begin
      name = nameof(ob)
      path = joinpath(cache_dir, "$name.json")
      if isfile(path)
        @info "Reading representables from $path"
        try
          rep = read_json_acset(type, path)
        catch ArgumentError  # if schema changed, delete and start over
          rm(cache_dir, recursive=true)
          make_cache(type, schema, subdir)
        end
      else
        @info "Computing representable $name"
        rep = representable(type, schema, name)
        write_json_acset(rep, path)
      end
      name => (rep, 1)
    end, generators(schema, :Ob)))
end

struct DRule
  diag
  sem::Symbol
  expr::NamedTuple
  DRule(d, s=:DPO; expr=(;)) = new(d, s, expr)
end

function rule_ob_map(rule, name::Symbol)
  try
    ob_map(rule, name)
  catch
    constructor(first(collect_ob(rule)))() # Default to empty database.
  end
end

function rule_hom_map(rule, name::Symbol, dom, codom)
  try
    hom_map(rule, name)
  catch
    only(homomorphisms(dom, codom))
  end
end

struct RuleWithSchema
  rule::Rule
  schema::DataMigration
  pac::Vector{ACSetTransformation}
  nac::Vector{ACSetTransformation}
end

function make_rule(rule_schema::DRule, y)
  rule = colimit_representables(rule_schema.diag, y)
  L, R, K = [rule_ob_map(rule, Symbol(x)) for x in "LRK"]
  i = rule_hom_map(rule, :l, K, L)
  o = rule_hom_map(rule, :r, K, R)
  Rule(i, o)
end
make_rule(rule_schema::DataMigration, y) = make_rule(DRule(rule_schema), y)


#========================================================
EXAMPLE 1: CUBE WORLD (<:FREE)
Interpretations--
- Box assembly instructions. When they go wrong.
- Computerized origami. Natural language instruction vs precise ones
- All possible ways of opening the cube. most general rules.
========================================================#
@present Sch3DShape(FreeSchema) begin
  Face::Ob
  Edge::Ob
  Vertex::Ob

  top::Hom(Face, Edge)
  right::Hom(Face, Edge)
  bottom::Hom(Face, Edge)
  left::Hom(Face, Edge)

  src::Hom(Edge, Vertex)
  tgt::Hom(Edge, Vertex)
end
to_graphviz(Sch3DShape)
@acset_type Typ3DShape(Sch3DShape)

ySch3DShape = yoneda(Typ3DShape)

#===
As we saw previously, pushouts can add connections in our data. 

===#
closedCube = @acset_colim ySch3DShape begin
  (f1, f2, f3, f4, f5, f6)::Face

  # top face (clockwise)
  top(f1) == top(f5)        # e1
  right(f1) == top(f2)      # e2
  bottom(f1) == top(f3)     # e3
  left(f1) == top(f4)       # e4

  # wall faces (clockwise)
  left(f2) == right(f3)     # e5
  left(f3) == right(f4)     # e6
  left(f4) == right(f5)     # e7
  left(f5) == right(f2)     # e8

  # bottom face (clockwise)
  top(f6) == bottom(f5)     # e9
  right(f6) == bottom(f2)   # e10
  bottom(f6) == bottom(f3)  # e11
  left(f6) == bottom(f4)    # e12

  # top vertices
  tgt(top(f1)) == src(right(f1))     # v1
  tgt(top(f1)) == src(right(f2))
  tgt(right(f1)) == src(bottom(f1))  # v2 
  tgt(right(f1)) == src(right(f3))
  tgt(bottom(f1)) == src(left(f1))   # v3 
  tgt(bottom(f1)) == src(right(f4))
  tgt(left(f1)) == src(top(f1))      # v4
  tgt(left(f1)) == src(right(f5))

  # bottom vertices
  tgt(top(f6)) == src(right(f6))     # v5
  tgt(top(f6)) == tgt(right(f2))
  tgt(right(f6)) == src(bottom(f6))  # v6
  tgt(right(f6)) == tgt(right(f3))
  tgt(bottom(f6)) == src(left(f6))   # v7 
  tgt(bottom(f6)) == tgt(right(f4))
  tgt(left(f6)) == src(top(f6))      # v8
  tgt(left(f6)) == tgt(right(f5))
end

openBox = @migration(SchRule, Sch3DShape, begin
  L => @join begin
    (face, face1, face2, face3, face4)::Face

    # top edges
    top(face) == top(face1)
    right(face) == top(face2)
    bottom(face) == top(face3)
    left(face) == top(face4)

    # wall faces (clockwise)
    left(face1) == right(face2)
    left(face2) == right(face3)
    left(face3) == right(face4)
    left(face4) == right(face1)

    # top vertices
    src(right(face1)) == src(top(face1))
    src(right(face1)) == tgt(top(face4))
    src(right(face2)) == src(top(face2))
    src(right(face2)) == tgt(top(face1))
    src(right(face3)) == src(top(face3))
    src(right(face3)) == tgt(top(face2))
    src(right(face4)) == src(top(face4))
    src(right(face4)) == tgt(top(face3))

    # bottom vertices
    tgt(right(face1)) == src(bottom(face1))
    tgt(right(face1)) == tgt(bottom(face4))
    tgt(right(face2)) == src(bottom(face2))
    tgt(right(face2)) == tgt(bottom(face1))
    tgt(right(face3)) == src(bottom(face3))
    tgt(right(face3)) == tgt(bottom(face2))
    tgt(right(face4)) == src(bottom(face4))
    tgt(right(face4)) == tgt(bottom(face3))
  end
  K => @join begin
    (face1, face2, face3, face4)::Face
  end
  R => @join begin
    (face1, face2, face3, face4, faceNew)::Face
    (edge1, edge2, edge3)::Edge

    # top edges
    top(faceNew) == top(face4)
    right(faceNew) == edge1
    bottom(faceNew) == edge2
    left(faceNew) == edge3

    # connect vertices of new edges
    src(edge1) == tgt(top(face4))
    tgt(edge1) == src(edge2)
    tgt(edge2) == src(edge3)
    tgt(edge3) == src(top(face4))

    # wall faces (clockwise
    left(face1) == right(face2)     # e5
    left(face2) == right(face3)     # e6
    left(face3) == right(face4)     # e7
    left(face4) == right(face1)     # e8

    # top vertices
    src(right(face1)) == src(top(face1))
    src(right(face1)) == tgt(top(face4))
    src(right(face2)) == src(top(face2))
    src(right(face2)) == tgt(top(face1))
    src(right(face3)) == src(top(face3))
    src(right(face3)) == tgt(top(face2))
    src(right(face4)) == src(top(face4))
    src(right(face4)) == tgt(top(face3))

    # bottom vertices
    tgt(right(face1)) == src(bottom(face1))
    tgt(right(face1)) == tgt(bottom(face4))
    tgt(right(face2)) == src(bottom(face2))
    tgt(right(face2)) == tgt(bottom(face1))
    tgt(right(face3)) == src(bottom(face3))
    tgt(right(face3)) == tgt(bottom(face2))
    tgt(right(face4)) == src(bottom(face4))
    tgt(right(face4)) == tgt(bottom(face3))
  end
  l => begin
    face1 => face1
    face2 => face2
    face3 => face3
    face4 => face4
  end
  r => begin
    face1 => face1
    face2 => face2
    face3 => face3
    face4 => face4
  end
end)

rule = make_rule(openBox, ySch3DShape)

#========================================================
EXAMPLE 2: KITCHENWORLD (<:FREE)
Actions:
  1. Slice bread
  2. Plate slice
  3. Put cheese on bread
========================================================#
@present SchKitchen(FreeSchema) begin
  Entity::Ob

  Food::Ob
  food_in_on::Hom(Food, Entity)
  food_is_entity::Hom(Food, Entity)

  Kitchenware::Ob
  ware_in_on::Hom(Kitchenware, Entity)
  ware_is_entity::Hom(Kitchenware, Entity)

  Counter::Ob
  counter_is_entity::Hom(Counter, Entity)

  BreadLoaf::Ob
  bread_loaf_is_food::Hom(BreadLoaf, Food)
  BreadSlice::Ob
  bread_slice_is_food::Hom(BreadSlice, Food)
  Egg::Ob
  egg_is_food::Hom(Egg, Food)
  Cheese::Ob
  cheese_is_food::Hom(Cheese, Food)

  Knife::Ob
  knife_is_ware::Hom(Knife, Kitchenware)
  Plate::Ob
  plate_is_ware::Hom(Plate, Kitchenware)
end
to_graphviz(SchKitchen)

@acset_type Kitchen(SchKitchen)

yKitchen = yoneda(Kitchen, SchKitchen; cache=make_cache(Kitchen, SchKitchen, "Kitchen"))

slice_bread = @migration(SchKitchen, begin
  L => @join begin
    loaf::BreadLoaf
    knife::Knife
  end
  R => @join begin
    loaf::BreadLoaf
    slice::BreadSlice
    food_in_on(bread_slice_is_food(slice)) == food_in_on(bread_loaf_is_food(loaf))
    knife::Knife
  end
  K => @join begin
    loaf::BreadLoaf
    knife::Knife
  end
end)
slice_bread_rule = make_rule(slice_bread, yKitchen)

plate_slice = @migration(SchRule, SchKitchen, begin
  L => @join begin
    slice::BreadSlice
    plate::Plate
  end
  R => @join begin
    slice::BreadSlice
    plate::Plate
    orig_container::Entity
    food_in_on(bread_slice_is_food(slice)) == ware_is_entity(plate_is_ware(plate))
  end
  K => @join begin
    plate::Plate
    orig_container::Entity
  end
  l => begin
    plate => plate
    orig_container => food_in_on(bread_slice_is_food(slice))
  end
  r => begin
    plate => plate
    orig_container => orig_container
  end
end)
plate_slice_rule = make_rule(plate_slice, yKitchen)

put_cheese_on_bread = @migration(SchKitchen, begin
  L => @join begin
    cheese::Cheese
    slice::BreadSlice
  end
  R => @join begin
    cheese::Cheese
    slice::BreadSlice
    cheese_is_food(cheese) == bread_slice_is_food(slice)
  end
  K => @join begin
    cheese::Cheese
    slice::BreadSlice
  end
end)
put_cheese_on_bread_rule = make_rule(put_cheese_on_bread, yKitchen)


state = @acset Kitchen begin
  Entity = 9

  Food = 5
  food_is_entity = [1, 2, 3, 4, 5]
  food_in_on = [9, 9, 9, 9, 9]
  Egg = 3
  egg_is_food = [1, 2, 3]
  BreadLoaf = 1
  bread_loaf_is_food = [4]
  Cheese = 1
  cheese_is_food = [5]

  Kitchenware = 3
  ware_is_entity = [6, 7, 8]
  ware_in_on = [9, 9, 9]
  Knife = 1
  knife_is_ware = [1]
  Plate = 2
  plate_is_ware = [2, 3]

  Counter = 1
  counter_is_entity = [9]
end
to_graphviz(elements(state))

matches = get_matches(slice_bread_rule, state)
match = matches[1]
state1 = rewrite_match(slice_bread_rule, match)
to_graphviz(elements(state1))

matches = get_matches(plate_slice_rule, state1)
match = matches[1]
state2 = rewrite_match(plate_slice_rule, match)
to_graphviz(elements(state2))

matches = get_matches(put_cheese_on_bread_rule, state2)
match = matches[1]
state3 = rewrite_match(put_cheese_on_bread_rule, match)
to_graphviz(elements(state3))

