module HW4

using CommonRLInterface
using StaticArrays: SA, SVector
using Compose

import ColorSchemes

export gw, render

const RL = CommonRLInterface

mutable struct GridWorldEnv <: AbstractEnv
    size::SVector{2, Int}
    rewards::Dict{SVector{2, Int}, Float64}
    state::SVector{2, Int}
end

function GridWorldEnv()
    rewards = Dict(SA[9,9]=> 10.0,
                   SA[3,1]=> -2.0,
                   SA[4,3]=>-10.0,
                   SA[2,3]=>  1.0,
                   SA[7,6]=> -5.0)
    return GridWorldEnv(SA[10, 10], rewards, SA[1,1])
end

RL.reset!(env::GridWorldEnv) = (env.state = SA[1,1])
RL.actions(env::GridWorldEnv) = (SA[1,0], SA[-1,0], SA[0,1], SA[0,-1])
RL.observe(env::GridWorldEnv) = env.state
RL.terminated(env::GridWorldEnv) = haskey(env.rewards, env.state)

function RL.act!(env::GridWorldEnv, a)
    if rand() < 0.44 # 44% chance of going in a random direction (=33% chance of going in a wrong direction)
        direction = rand(actions(env))
    else
        direction = a
    end

    env.state = clamp.(env.state + direction, SA[1,1], env.size)

    return get(env.rewards, env.state, -0.1) + 0.1*randn()
end

RL.observations(env::GridWorldEnv) = [SA[x, y] for x in 1:env.size[1], y in 1:env.size[2]]
RL.clone(env::GridWorldEnv) = GridWorldEnv(env.size, copy(env.rewards), env.state)
RL.state(env::GridWorldEnv) = env.state
RL.setstate!(env::GridWorldEnv, s) = (env.state = s)

"""
    render(env::GridWorldEnv)
    render(env::GridWorldEnv, color=s->5.0, policy=s->SA[1,0])

Render a GridWorldEnv to a Compose.jl object that can be displayed in a Jupyter notebook or ElectronDisplay window.

# Keyword Arguments
- `color::Function`: A function that determines the color of each cell. Input is a state, output is either a Float64 between -10 and 10 that will produce a color ranging from red to green, or any color from Colors.jl.
- `policy::Function`: A function that allows showing an arrow in each cell to indicate the policy. Input is a state; output is an action.
"""
function render(env::GridWorldEnv; color::Function=s->get(env.rewards, s, -0.1), policy::Union{Function,Nothing}=nothing)
    nx, ny = env.size
    cells = []
    for s in observations(env)
        r = get(env.rewards, s, 0.0)
        clr = get(ColorSchemes.redgreensplit, (r+10.0)/20.0)
        cell = context((s[1]-1)/nx, (ny-s[2])/ny, 1/nx, 1/ny)
        if policy !== nothing
            a = policy(s)
            txt = compose(context(), text(0.5, 0.5, aarrow[a], hcenter, vcenter), stroke("black"))
            compose!(cell, txt)
        end
        clr = tocolor(color(s))
        compose!(cell, rectangle(), fill(clr), stroke("gray"))
        push!(cells, cell)
    end
    grid = compose(context(), linewidth(0.5mm), cells...)
    outline = compose(context(), linewidth(1mm), rectangle(), stroke("gray"))

    s = env.state
    agent_ctx = context((s[1]-1)/nx, (ny-s[2])/ny, 1/nx, 1/ny)
    agent = compose(agent_ctx, circle(0.5, 0.5, 0.4), fill("orange"))

    sz = min(w,h)
    return compose(context((w-sz)/2, (h-sz)/2, sz, sz), agent, grid, outline)
end

RL.render(env::GridWorldEnv) = render(env)

tocolor(x) = x
function tocolor(r::Float64)
    minr = -10.0
    maxr = 10.0
    frac = (r-minr)/(maxr-minr)
    return get(ColorSchemes.redgreensplit, frac)
end

const aarrow = Dict(SA[0,1]=>'↑', SA[-1,0]=>'←', SA[0,-1]=>'↓', SA[1,0]=>'→')

gw = GridWorldEnv()

end
