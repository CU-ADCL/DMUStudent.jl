arrowlength = maxd/30
arrowheight = (hlim[2]-hlim[1])/20

struct ACASRender
    m::UnresponsiveACASMDP
    s::ACASState
end

POMDPModelTools.render(m::UnresponsiveACASMDP, step::NamedTuple) = render(m, step.s)
POMDPModelTools.render(m::UnresponsiveACASMDP, s::ACASState) = ACASRender(m, s)
POMDPModelTools.render(m::UnresponsiveACASMDP, s::AbstractVector) = render(m, convert(ACASState, s))
POMDPModelTools.render(m::UnresponsiveACASMDP) = ACASRender(m, rand(initialstate(m)))

ownarrow(s::ACASState) = [-arrowlength/2, arrowlength/2, -arrowlength/2], [s.h_o+arrowheight/2, s.h_o, s.h_o-arrowheight/2]
intarrow(s::ACASState) = [s.d+arrowlength/2, s.d-arrowlength/2, s.d+arrowlength/2], [s.h_i+arrowheight/2, s.h_i, s.h_i-arrowheight/2]
title(s::ACASState) = "[hₒ=$(s.h_o) ft, ḣₒ=$(s.hdot_o) ft/min, hᵢ=$(s.h_i) ft, d=$(s.d) ft]"

function Base.show(io::IO, m::MIME"text/plain", r::ACASRender)
    s = r.s
    ox, oy = ownarrow(s)
    plt = UnicodePlots.lineplot(ox, oy,
                                name="Ownship >",
                                title=title(s),
                                width=70,
                                grid=false,
                                xlabel="d (ft)",
                                ylabel="h (ft)",
                                ylim=hlim,
                                xlim=(-0.1*maxd,1.1*maxd))
    ix, iy = intarrow(s)
    UnicodePlots.lineplot!(plt, ix, iy, name="Intruder <")
    show(io, m, plt)
end

function transform(xy)
    x, y = xy
    r = x/maxd
    d = (maximum(hlim) - y)/(hlim[2]-hlim[1])
    return (r, d)
end


function Base.show(io::IO, m::MIME"text/html", r::ACASRender)
    s = r.s
    g = compose(context(),
            text(0.5, 0.05, title(s), hcenter, vtop),
            (context(), polygon(transform.(collect(zip(ownarrow(s)...)))),
                        text(transform((0, s.h_o - arrowheight))..., "Ownship", hleft, vtop), 
                        fill("blue")),
            (context(), polygon(transform.(collect(zip(intarrow(s)...)))),
                        text(transform((s.d, s.h_i - arrowheight))..., "Intruder", hright, vtop), 
                        fill("green")),
           )
    show(io, m, g)
end
