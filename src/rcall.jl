using Phylo
using RCall
using RCall: protect, unprotect

import Base.convert

function convert{T <: AbstractTree}(::Type{T}, rt::RObject{VecSxp})
    if !RCall.isObject(rt) || RCall.isS4(rt) ||
        rcopy(rcall(:class, rt)) != "phylo"
        error("Object is not of S3 phylo class, aborting")
    end

    if !rcopy(rcall(Symbol("is.rooted"), rt))
        error("Cannot currently translate unrooted trees")
    end

    dict = convert(Dict{Symbol, Any}, rt)
    nodes = dict[Symbol("tip.label")]
    tree = NamedTree(nodes)
    edges = dict[:edge]
    nnode = dict[:Nnode]
    lengths = dict[Symbol("edge.length")]
    nontips = nnode
    append!(nodes, addnodes!(tree, nontips))
    
    for edge in 1:size(edges, 1)
        addbranch!(tree,
                   nodes[edges[edge, 1]], nodes[edges[edge, 2]],
                   lengths[edge])
    end

    validate(tree) || warn("Tree does not internally validate")
    return tree
end

import RCall.sexp

function sexp(tree::NamedTree)
    validate(tree) || warn("Tree does not internally validate")

    tipnames = collect(NodeNameIterator(tree, isleaf))
    root = collect(NodeNameIterator(tree, isroot))
    if (length(root) != 1)
        error("Can't currently translate tree with > 1 roots")
    end
    nontips = collect(NodeNameIterator(tree, isinternal))
    tor = Dict{Symbol, Any}()
    tor[:Nnode] = length(nontips) + length(root)
    tor[Symbol("tip.label")] = tipnames
    nodes = copy(tipnames)
    push!(nodes, root[1])
    append!(nodes, nontips)
    bi = BranchIterator(tree)
    lengths = Vector{Float64}(length(bi))
    edges = Matrix{Int32}(length(lengths), 2)
    index = 1
    for branch in bi
        lengths[index] = getlength(branch)
        edges[index, :] = indexin([getsource(branch), gettarget(branch)], nodes)
        index += 1
    end
    tor[:edge] = edges
    tor[Symbol("edge.length")] = lengths
    sobj = protect(sexp(tor))
    #setattrib!(sobj, :order, sexp("cladewise"))
    setclass!(sobj, sexp("phylo"))
    unprotect(1)
    return sobj
end

eltype(::Type{RClass{:phylo}}, s::Ptr{VecSxp}) = Phylo
function rcopy(::Type{RClass{:phylo}}, s::Ptr{VecSxp})
    if !rcopy(rcall_p(Symbol("is.rooted"), s))
        error("Cannot currently translate unrooted trees")
    end

    dict = convert(Dict{Symbol, Any}, rt)
    nodes = dict[Symbol("tip.label")]
    tree = NamedTree(nodes)
    edges = dict[:edge]
    nnode = dict[:Nnode]
    lengths = dict[Symbol("edge.length")]
    nontips = nnode
    append!(nodes, addnodes!(tree, nontips))
    
    for edge in 1:size(edges, 1)
        addbranch!(tree,
                   nodes[edges[edge, 1]], nodes[edges[edge, 2]],
                   lengths[edge])
    end

    validate(tree) || warn("Tree does not internally validate")
    return tree
end
