

# Loading Dirs Module
println("Loading Dirs Module")
include("./dirs.jl")
using .Dirs

# Loading Pre Processor modules
println("Loading Pre Processor modules")
include("./pre_processor/exceptions.jl")
using .Exceptions
include("./pre_processor/systems_struct_mess.jl")
using .SystemStructMess
include("./pre_processor/configuration.jl")
using .ModelConfiguration
include("./pre_processor/process_yaml.jl")
using .ProcessYaml

# Loading Core modules
println("Loading Core modules")
include("./core/technologies.jl")
using .Technologies
include("./core/parents.jl")
using .Parents
include("./core/economics_v2.jl")
using .Economicsv2
include("./core/solver.jl")
using .Solver


# Loading Post Processor modules
println("Loading Post Processor modules")

include("./post_processor/process_results_data.jl")
using .ProcessResultsData

# Loading Plotting modules
println("Loading Plotting modules")
include("./plotting/plotting_hourly_results.jl")
using .PlottingHourlyResults
include("./plotting/plotting_overall_results.jl")
using .PlottingOverallResults

# Loading various packages
println("Loading external packages")
using YAML,CSV,DataFrames,LinearAlgebra

# Running the model to obtain system solution
println("Running the model")

model_configuration = ModelConfiguration.create_model_configuration()
techs_scenarios = ["HP","DH"]
for scenario in techs_scenarios
    println("Running the $scenario scenario:")
    my_system,techs = ProcessYaml.create_system(name,scenario)
    solution,economic_sol = Solver.core_MESS(my_system,name,model_configuration,techs)


    # Post processing
    println("Post processing")
    aggregated_data = ProcessResultsData.generate_overall_data_results(solution)

    # Plotting
    println("Plotting")
    PlottingHourlyResults.plot_hourly_results(my_system,solution,scenario)
    PlottingOverallResults.plot_overall_results(my_system,aggregated_data,scenario)

    # Exporting results to CSV
    println("Saving results to CSV")
    Solver.save_results_to_CSV(solution,"sys",scenario)
    Solver.save_results_to_CSV(economic_sol,"eco",scenario)
end

