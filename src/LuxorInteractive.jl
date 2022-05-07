module LuxorInteractive

using JSServe
using EzXML
using Luxor

export @group
# Write your package code here.
LUXORGROUPS = Dict()

macro group(groupname, ex)
    return quote
        gid = "0.1" * String(gensym())[3:end]
        LUXORGROUPS[$groupname] = gid

        setlinecap(:round)
        setcolor(100, 100, 100, parse(Float64, gid))
        circle(O, 0.0001, :stroke)

        $ex

        setlinecap(:square)
        circle(O, 0.0001, :stroke)
    end
end

end
