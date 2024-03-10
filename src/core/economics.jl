module Economics

export economicanalysis

using Main.SystemStructMess

using Main.ModelConfiguration: timestep, timespan

using Main.Dirs: path

using DataFrames, CSV



function economicanalysis(model_config, sys_solution, sys,timespan)

    results_economics_sol = create_econ_sol_location(model_config,sys)
    srgcpertech!(results_economics_sol,timespan,sys,sys_solution)

    network_costs = costs_network(sys_solution.network)

    results_economics = Results_economics(results_economics_sol,network_costs)
    
    return results_economics
end

"""
    create_econ_sol_location(modelconfig,sys)
Creates the structure of the SRGC per tech solution based on model configuration
parameters and on system description
"""
function create_econ_sol_location(modelconfig,sys)
    x = length(sys.nodes)
    z = modelconfig.timespan
    locations = Array{Location_srgc,1}(undef,x)
    for i in 1:x
        if sys.nodes[i].techs == 0
            locations[i] = Location_srgc(sys.nodes[i].name,0)
        else
            y = length(sys.nodes[i].techs)
            df_srgc     = DataFrame()
            for j in 1:y
                insertcols!(df_srgc,j,string(sys.nodes[i].techs[j].name) => zeros(z))
            end
            locations[i] = Location_srgc(sys.nodes[i].name,df_srgc)
        end
    end
    return locations
end


"""
    srgcpertech!(econ_sol,steps,system,solution)
Takes in the structure of the SRGC per tech solution and updates it computing
SRGCs according to system and system solution
"""
function srgcpertech!(econ_sol,steps,system,solution)

    for i in 1:length(econ_sol)

        if econ_sol[i].srgc == 0
        else

            techlist = names(econ_sol[i].srgc)

            for j in 1:length(techlist)

                srgc_oandm = zeros(steps)
                srgc_cons  = zeros(steps)
                srgc_emiss = zeros(steps)

                parent,carrier_in,carrier_out,monetary,emissions = techinfo(techlist[j],system.nodes[i].techs)

                if parent == "demand"

                elseif parent == "supply"
                    srgc_oandm = srgc_oandm!(srgc_oandm,carrier_in,carrier_out,solution.nodes[i],techlist[j],monetary)
                    srgc_cons  = srgc_consumption!(srgc_cons,carrier_in,carrier_out,solution.nodes[i],techlist[j],monetary)
                    srgc_emiss = srgc_emissions!(srgc_emiss,carrier_in,carrier_out,solution.nodes[i],techlist[j],monetary)
                elseif parent == "supply_grid"

                elseif parent == "conversion"
                    srgc_oandm = srgc_oandm!(srgc_oandm,carrier_in,carrier_out,solution.nodes[i],techlist[j],monetary)
                    srgc_cons  = srgc_consumption!(srgc_cons,carrier_in,carrier_out,solution.nodes[i],techlist[j],monetary)
                    srgc_emiss = srgc_emissions!(srgc_emiss,carrier_in,carrier_out,solution.nodes[i],techlist[j],monetary)
                elseif parent == "conversion_plus"
                    srgc_oandm = srgc_oandm!(srgc_oandm,carrier_in,carrier_out,solution.nodes[i],techlist[j],monetary)
                    srgc_cons  = srgc_consumption!(srgc_cons,carrier_in,carrier_out,solution.nodes[i],techlist[j],monetary)
                    srgc_emiss = srgc_emissions!(srgc_emiss,carrier_in,carrier_out,solution.nodes[i],techlist[j],monetary)
                elseif parent == "transmission"

                else
                end

                srgc = srgc_oandm + srgc_cons + srgc_emiss
                econ_sol[i].srgc[!,Symbol(techlist[j])] .= srgc

            end
        end
    end

end


"""
    techinfo(name,techs)
Takes in technology name and techs vector of a given location from the
structure describing the system and returns technology infos
"""
function techinfo(name,techs)

    parent = 0.
    carrier_in = 0.
    carrier_out = 0.
    monetary = 0.
    emissions = 0.

    for i in 1:length(techs)
        if techs[i].name == name
            parent      = techs[i].essentials.parent
            carrier_in  = techs[i].essentials.carrier_in
            carrier_out = techs[i].essentials.carrier_out
            monetary    = techs[i].costs.monetary
            emissions   = techs[i].costs.monetary
        else
        end
    end
    return parent,carrier_in,carrier_out,monetary,emissions
end


"""
    nameconversion(carrier)
Associates the carrier to the corresponding dataframe symbol
"""
function nameconversion(carrier)
    if carrier == "electricity"
        df = :df_el
    elseif carrier == "heat"
        df = :df_th
    elseif carrier == "gas"
        df = :df_gas
    else

    end
    return df
end


"""
    steps(model_configuration)
Takes in the model_configuration structure and returns the number of
steps of the simulation, considering timespan and timestep
"""
function steps(model_configuration)
    steps = model_configuration.timespan/model_configuration.timestep
    return steps
end


"""
    srgc_oandm!(srgc_oandm,carrier_in,carrier_out,node,technology,monetary)
O&M term of SRGC, accounts for om_annual and om_prod
srgc_oandm is a steps long array that gets updated by the function
"""
function srgc_oandm!(srgc_oandm,carrier_in,carrier_out,node,technology,monetary)

    if ismissing(monetary.om_annual)
    else
        srgc_oandm = srgc_oandm .+ monetary.om_annual/8760.
    end

    if ismissing(monetary.om_prod)
    else
        df = nameconversion(carrier_out)
        show(node)
        srgc_oandm = srgc_oandm + monetary.om_prod * getproperty(node,df)[technology]
    end
    return srgc_oandm

end


"""
    srgc_consumption!(srgc_cons,carrier_in,carrier_out,node,technology,monetary)
Consumption term of SRGC, fuel costs are taken from om_con for each tech
srgc_cons is a steps long array that gets updated by the function
"""
function srgc_consumption!(srgc_cons,carrier_in,carrier_out,node,technology,monetary)

    if ismissing(monetary.om_con)
    else
        df = nameconversion(carrier_in)
        srgc_cons = monetary.om_con * getproperty(node,df)[technology]
    end
    return srgc_cons
end


"""
    srgc_emissions!(srgc_emiss,carrier_in,carrier_out,node,technology,monetary)
Emission term of SRGC, accounts for emission costs
srgc_emiss is a steps long array that gets updated by the function
"""
function srgc_emissions!(srgc_emiss,carrier_in,carrier_out,node,technology,emissions)

    if ismissing(emissions)
    else
        # error: emissions not yet implemented
    end
    return srgc_emiss
end


function costs_network(network_sol)
    costs = DataFrame()
    prices = CSV.read(joinpath(path, "..", "data","timeseries_data","power_prices.csv"),DataFrame)

    for i in fieldnames(typeof(network_sol))
        if String(i) == "df_el"
            df_el = getfield(network_sol,i)
            col_names = names(df_el)
            for c in col_names
                if c == "balance"
                else
                    costs[!,Symbol(c)] = df_el[!,Symbol(c)] .* prices[!,"Prices"]
                end
            end
        end
    end

    return costs

end

"""
Missing:
- SRGC emissions
- energy bought from the grid
- export costs
- functions updating input variables
  https://stackoverflow.com/questions/62534592/julia-scoping-why-does-this-function-modify-a-global-variable
- specify types of inputs?
"""

# function econanalysis_srgc(model_solution,model_configuration,my_system)
#     steps = steps(model_configuration)
#     rearr_solution = process_raw_results_economics(model_solution)
#     econ_solution  = get_techs_per_location(model_configuration,my_system)
#     econ_solution  = srgc!(econ_solution,steps,my_system,rearr_solution)
#     return econ_solution

# end
#temp1 = process_raw_results_economics(solution)
#temp2 = create_econ_sol_location(model_configuration,my_system)
#srgcpertech!(temp2,168,my_system,temp1)


end



