module LuxorInteractive

using JSServe
using EzXML
using Luxor

export @group
export parsedrawing, opentagluxor, closetagluxor, cleargroups
export applyid!, applygroupclass!
# Write your package code here.

"""
LUXORGROUPS stores the group keys.
"""
LUXORGROUPS = Dict()
LUXORGIDS = Dict()

macro group(groupname, ex)
    groupname = esc(groupname)
    ex = esc(ex)
    return quote
        if haskey(LUXORGROUPS, $groupname)
            gid = LUXORGROUPS[$groupname]
        else
            gid = "0." * String(gensym())[3:end]
        end

        LUXORGROUPS[$groupname] = gid
        LUXORGIDS[gid] = $groupname

        setlinecap(:round)
        setcolor(100, 100, 100, parse(Float64, gid))
        circle(O, 0, :stroke)

        $ex

        setlinecap(:square)
        circle(O, 0, :stroke)
    end
end

function cleargroups()
    empty!(LUXORGROUPS)
    empty!(LUXORGIDS)
end

"""
    opentagluxor(element)
"""
function opentagluxor(element)
    starttag = "fill:none;stroke-width:2;stroke-linecap:round;stroke-linejoin:miter;stroke:rgb(100%,100%,100%);stroke-opacity:"
    endtag = "stroke-miterlimit:10;"
    if !haskey(element, "style")
        return nothing
    end
    if element["style"][1:min(110, end)] == starttag && element["d"] == "M 0 0 L 0 0 "
        pos = findfirst(";", element["style"][110:end])
        if !isnothing(pos)
            if element["style"][110+pos[1]:end] == endtag
                groupid = element["style"][111:108+pos[1]]
                try
                    return LUXORGIDS[groupid]
                catch
                    return nothing
                end
            end
        end
    end
    return nothing
end

"""
    closetagluxor(element)
"""
function closetagluxor(element)
    starttag = "fill:none;stroke-width:2;stroke-linecap:square;stroke-linejoin:miter;stroke:rgb(100%,100%,100%);stroke-opacity:"
    endtag = "stroke-miterlimit:10;"
    if !haskey(element, "style")
        return nothing
    end
    if element["style"][1:min(111, end)] == starttag && element["d"] == "M 0 0 L 0 0 "
        pos = findfirst(";", element["style"][111:end])
        if !isnothing(pos)
            if element["style"][111+pos[1]:end] == endtag
                groupid = element["style"][112:109+pos[1]]
                try
                    return LUXORGIDS[groupid]
                catch
                    return nothing
                end
            end
        end
    end
    return nothing
end

function applyid!(dxml::EzXML.Document)
    root(dxml)["id"] = "luxor" * string(gensym())[3:end]
    id = 1
    idopengroup = 1
    idclosegroup = 1
    for i in eachelement(root(dxml))
        for j in eachelement(i)
            if !isnothing(opentagluxor(j))
                j["id"] = "lxog" * string(idopengroup)
                idopengroup += 1
            elseif !isnothing(closetagluxor(j))
                j["id"] = "lxcg" * string(idclosegroup)
                idclosegroup += 1
            else
                j["id"] = "lx" * string(id)
                id += 1
            end
        end
    end
end

function applygroupclass!(dxml::EzXML.Document)
    gtag = nothing
    for i in eachelement(root(dxml))
        for j in eachelement(i)
            if !isnothing(opentagluxor(j))
                gtag = opentagluxor(j)
            end
            if !isnothing(closetagluxor(j))
                j["class"] = gtag * " " * j["id"]
                gtag = nothing
            end
            if !isnothing(gtag)
                j["class"] = gtag * " " * j["id"]
            end
        end
    end
end

function extratpathsstyles(dxml::EzXML.Document)
    pathstyles = ""
    for i in eachelement(root(dxml))
        for j in eachelement(i)
            pathstyles *= "\n" * root(dxml)["id"] * ">." * j["id"] * "{" * j["style"] * "}"
            delete!(j, "style")
        end
    end
    return pathstyles
end


function parsedrawing(d::Drawing)
    dxml = parsexml(String(copy(d.bufferdata)))
    applyid!(dxml)
    applygroupclass!(dxml)
    return string(root(dxml))
end

end
