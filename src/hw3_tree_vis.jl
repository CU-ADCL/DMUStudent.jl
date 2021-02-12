"""
    visualize_tree(q, n, t, root_state)


"""
function visualize_tree(q::Dict, n::Dict, t::Dict, root_state; title="MCTS Tree", init_expand=10, init_duration=0, kwargs...)
    S = typeof(root_state)
    total_n = Dict{S, Int}()
    for ((s, a), nn) in n
        total_n[s] = get(total_n, s, 0) + nn
    end

    maxq = maximum(values(q))
    minq = minimum(values(q))-0.00001

    children = [Int[]]
    text = ["$root_state\nN: $(total_n[root_state])"]
    style = [""]
    link_style = [""]
    tooltip = [""]

    # create sa nodes
    state_children = Dict{S, Vector{Int}}()
    sa_nodeindices = Dict{keytype(q), Int}()
    for (s, a) in keys(q)
        txt = "$a\nN: $(n[(s, a)])\nQ: $(@sprintf("%8.4g", q[(s,a)]))"
        push!(children, Int[])
        push!(text, txt)
        rel_q = (q[(s,a)]-minq)/(maxq-minq)
        color = weighted_color_mean(rel_q, colorant"green", colorant"red")
        push!(style, "stroke:#$(hex(color))")
        w = max(20.0*sqrt(n[(s, a)]/total_n[s]), 1)
        push!(link_style, "stroke-width:$(w)px")
        push!(tooltip, txt)
        sa_nodeindices[(s, a)] = length(children)
        if !haskey(state_children, s)
            state_children[s] = Int[]
        end
        push!(state_children[s], length(children))
    end

    children[1] = state_children[root_state]

    # create sasp nodes and push children to sa
    for (s, a, sp) in keys(t)
        txt = "$sp\nN: $(get(total_n, sp, 0))"
        push!(children, get(state_children, sp, Int[]))
        push!(text, txt)
        push!(style, "")
        w = 20.0*sqrt(t[(s,a,sp)]/n[(s, a)])
        push!(link_style, "stroke-width:$(w)px")
        push!(tooltip, txt)
        push!(children[sa_nodeindices[(s, a)]], length(children))
    end

    return D3Tree(children,
                  text=text,
                  style=style,
                  tooltip=tooltip,
                  link_style=link_style,
                  init_expand=init_expand,
                  init_duration=init_duration,
                  kwargs...
                 )
end

