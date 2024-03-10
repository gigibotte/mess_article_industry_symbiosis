module Core

export core

using Main.Parents, Main.ProcessYaml, Main.SystemStructMess, Main.Exceptions, Main.ModelConfiguration

using Main.ModelConfiguration: timestep, timespan

using Main.Solver, Main.ProcessRawData

using YAML,CSV,DataFrames,LinearAlgebra

function core(sys,name,model_configuration)
    solution = Solver.solver(sys,name,model_configuration)
    
   # economic_solution = Economics.economicanalysis(model_configuration, solution, sys,timespan)

    processed_solution = Solver.process_raw_results(solution)

    return processed_solution
end

end