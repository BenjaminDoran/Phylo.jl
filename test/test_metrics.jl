module TestMetrics

using Phylo
using Test

@testset "Metrics" begin
    species = getleaves(tree)[[2, 5, 8, 12, 22]];
    mrca = common_ancestor(tree, species)
    @test getnodename(tree, mrca) == "Node 65"
end