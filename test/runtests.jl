using Test, Main.Example


# tests from Example.jl
@test hello("Julia") == "Hello, Julia"

@test hello2("Julia") == "Hello, Julia"
# @test domath(2.0) ≈ 7.0
# @test isempty(lintpkg("Simulator"))
