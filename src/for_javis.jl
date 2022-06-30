"""
    apply_transform(transform::Vector{Float64} , poly::Vector{Point})

applies the transform , got by getmatrix() on every point in the poly
and returns a new poly.

move this to luxor_overrides_util.jl later.
"""
function apply_transform(transform::Vector{Float64}, poly::Vector{Point})
    retpoly = Point[]
    for pt in poly
        res = cairotojuliamatrix(transform) * [pt[1], pt[2], 1]
        push!(retpoly, Point(res[1], res[2]))
    end
    retpoly
end

"""
    update_currentjpath(action::Symbol)

Updates the CURRENT_JPATHS
This function is used  inside the strokepath/strokepreserve/fillpath/fillpreserve.
Converts the current Path and other drawing states into a JPath and appends to the CURRENT_JPATHS global.

the argument is a symbol either `:stroke` or `:fill` , to change behaviour
for stroke vs fill.
"""
function update_currentjpath(action::Symbol)
    #println("test strokepaths")
    cur_polys, cur_costates = pathtopoly(Val(:costate))#this pathtopoly is defined in javis
    @assert length(cur_polys) == length(cur_costates)
    transform = getmatrix()
    cur_polys = [apply_transform(transform, poly) for poly in cur_polys]
    #cur_polys is of 2 element Tuple 
    #containg 2 arrays 1 with Polygons and one with the bools
    r, g, b, a = map(
        sym -> getfield(CURRENTDRAWING[1], sym),
        [:redvalue, :greenvalue, :bluevalue, :alpha],
    )
    #by default they are black transparent 
    fillstroke = Dict(:fill => [0.0, 0, 0, 0], :stroke => [0.0, 0, 0, 0])
    fillstroke[action] .= [r, g, b, a]
    #if polys didnt change we just modify the last JPath in the CURRENT_JPATHS
    if length(Main.Javis.CURRENT_JPATHS) > 0 && cur_polys == Main.Javis.CURRENT_JPATHS[end].polys
        #print("found similar path\n")
        setproperty!(Main.Javis.CURRENT_JPATHS[end], action, fillstroke[action])
        #if action was :stroke above line would be the same as doing...
        #CURRENT_JPATHS[end].stroke = fillstroke[:stroke] 
        setproperty!(Main.Javis.CURRENT_JPATHS[end], :lastaction, action)
        #if action was :stroke above line would be the same as doing...
        #CURRENT_JPATHS[end].lastaction = :stroke
    else
        #println("adding to CURRENT_JPATH")
        currpath = Main.Javis.JPath(
            cur_polys,
            cur_costates,
            fillstroke[:fill],
            fillstroke[:stroke],
            action,
            2,
        )
        push!(Main.Javis.CURRENT_JPATHS, currpath)
    end
end
