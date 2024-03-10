module Solver

export solver, core_MESS

using Main.Parents, Main.ProcessYaml, Main.SystemStructMess, Main.Exceptions

using Main.ModelConfiguration: timestep, timespan

using Main.Economicsv2

using Main.Dirs: path

using YAML,CSV,DataFrames,LinearAlgebra

function core_MESS(sys,name,model_configuration,techs)
    solution = Solver.solver(sys,name,model_configuration)
    
    processed_solution = Solver.process_raw_results(solution)
    economic_solution = Economicsv2.build_economic_solution(processed_solution, sys,techs)

    return processed_solution,economic_solution
end

"""
    solver(system,name)

Given the system in analysis and its name,
It generates the results of the system firslty by solving the location and later by solving the network att each time step t.

It return the struct System_result representing the full results of the system in analysis.
"""
function solver(system,name,modelconfig)


    results_partial     = create_results_struct(system)
    results_partial_net = create_results_struct_net()
    #specific_param      = create_param_struct(system)

    # tech_specific_param = struttura: per ogni location, per le tecnologie per cui serve, ho un dataframe contente il valore per ogni timestep 
    # i valori delle diverse variabili considerate

    for t in 1:timespan
        for loc in 1:length(results_partial)
            if system.nodes[loc].techs == 0 
            elseif occursin("Industry",system.nodes[loc].name)
            else
                solvelocation!(system.nodes[loc],results_partial[loc],loc,timestep,t,modelconfig)
            end
        end

        if modelconfig.network_electricity && modelconfig.network_district_heating
            solvenetwork!(system,results_partial,results_partial_net,t)
        elseif modelconfig.network_electricity
            solvenetwork!(system,results_partial,results_partial_net,t)
        end
        
    end

    result = System_results(name,results_partial_net,results_partial)
    
    return(result)
end # solver


"""
    solvelocation!(loc, result_loc, loc_num, timestep, t)

Given a location, the empty result dataframe of the location, the number of the location, the timestep and the time in exam,
It generates the results for that location for each carrier at the time t.
At the first time t, it overwrite the results on the first row of the dataframes (that are filled with 0) for each time t after the first,
a row of 0 is generated for each dataframe and then filled.

Each technology is analysed based on its parent and carrier. From these, the respective parent function is called to obtain the results for that technology.
"""
 function solvelocation!(loc, result_loc, loc_num, timestep, t,modelconfig)

     if t == 1
     else
         push!(result_loc.df_el, zeros(Float64,length(names(result_loc.df_el))))
         push!(result_loc.df_th, zeros(Float64,length(names(result_loc.df_th))))
         push!(result_loc.df_gas, zeros(Float64,length(names(result_loc.df_gas))))
         if ismissing(result_loc.additional_carriers)
         else
             push!(result_loc.additional_carriers, zeros(Float64,length(names(result_loc.additional_carriers))))
         end

         #push!(result_loc.el_balance, zeros(Float64,length(names(result_loc.el_balance))))
         #push!(result_loc.th_balance, zeros(Float64,length(names(result_loc.th_balance))))
         #push!(result_loc.gas_balance, zeros(Float64,length(names(result_loc.gas_balance))))
     end

     for tech in loc.techs
         if tech.essentials.parent == "demand"

            if tech.essentials.carrier == "electricity"
                result_demand = Parents.demand(result_loc.df_el[t,"electricity_balance"], tech, t, timestep)
                result_loc.df_el[t,tech.name] = result_demand[2]
                result_loc.df_el[t,"electricity_balance"] = result_demand[1]
            elseif tech.essentials.carrier == "heat"
                result_demand = Parents.demand(result_loc.df_th[t,"heat_balance"], tech, t, timestep)
                result_loc.df_th[t,tech.name] = result_demand[2]
                result_loc.df_th[t,"heat_balance"] = result_demand[1]
            else tech.essentials.carrier == "gas"
                result_demand = Parents.demand(result_loc.df_gas[t,"gas_balance"], tech, t, timestep)
                result_loc.df_gas[t,tech.name] = result_demand[2]
                result_loc.df_gas[t,"gas_balance"] = result_demand[1]
            end

         elseif tech.essentials.parent == "supply"

            if tech.essentials.carrier_out == "electricity"
                result_supply = Parents.supply(result_loc.df_el[t,"electricity_balance"], tech, t, timestep,loc.name)
                result_loc.df_el[t,tech.name] = result_supply[2]
                result_loc.df_el[t,"electricity_balance"] = result_supply[1]
            elseif tech.essentials.carrier_out == "heat"
                result_supply = Parents.supply(result_loc.df_th[t,"heat_balance"], tech, t, timestep,loc.name)
                result_loc.df_th[t,tech.name] = result_supply[2]
                result_loc.df_th[t,"heat_balance"] = result_supply[1]
            else tech.essentials.carrier_out == "gas"
                result_supply = Parents.supply(result_loc.df_gas[t,"gas_balance"], tech, t, timestep,loc.name)
                result_loc.df_gas[t,tech.name] = result_supply[2]
                result_loc.df_gas[t,"gas_balance"] = result_supply[1]
            end

         elseif tech.essentials.parent == "supply_grid"

            if tech.essentials.carrier_out == "electricity"
                if modelconfig.network_electricity
                else
                    result_supply = Parents.supply_grid(result_loc.df_el[t,"electricity_balance"], tech, t, timestep)
                    result_loc.df_el[t,tech.name] = result_supply[2]
                    result_loc.df_el[t,"electricity_balance"] = result_supply[1]
                end
            elseif tech.essentials.carrier_out == "heat"
                result_supply = Parents.supply_grid(result_loc.df_th[t,"heat_balance"], tech, t, timestep)
                result_loc.df_th[t,tech.name] = result_supply[2]
                result_loc.df_th[t,"heat_balance"] = result_supply[1]
            else tech.essentials.carrier_out == "gas"
                result_supply = Parents.supply_grid(result_loc.df_gas[t,"gas_balance"], tech, t, timestep)
                result_loc.df_gas[t,tech.name] = result_supply[2]
                result_loc.df_gas[t,"gas_balance"] = result_supply[1]
            end

         elseif tech.essentials.parent == "conversion"

             result_conversion = Parents.conversion(result_loc.df_el[t,"electricity_balance"],result_loc.df_th[t,"heat_balance"],tech,t,timestep)

             if tech.essentials.carrier_out == "electricity"
                 result_loc.df_el[t,tech.name] = result_conversion[4]
                 result_loc.df_el[t,"electricity_balance"] = result_conversion[1]
             else tech.essentials.carrier_out == "heat"
                 result_loc.df_th[t,tech.name] = result_conversion[4]
                 result_loc.df_th[t,"heat_balance"] = result_conversion[2]
             end
             if tech.essentials.carrier_in == "electricity"
                 result_loc.df_el[t,tech.name] = result_conversion[3]
                 result_loc.df_el[t,"electricity_balance"] = result_conversion[1]
             elseif tech.essentials.carrier_in == "heat"
                 result_loc.df_th[t,tech.name] = result_conversion[3]
                 result_loc.df_th[t,"heat_balance"] = result_conversion[2]
             elseif tech.essentials.carrier_in == "gas"
                 result_loc.df_gas[t,tech.name] = result_conversion[3]
             else
                 result_loc.additional_carriers[t,tech.name] = result_conversion[3]
             end

         elseif tech.essentials.parent == "conversion_plus"

             result_conversion_plus = Parents.conversion_plus(result_loc.df_el[t,"electricity_balance"],result_loc.df_th[t,"heat_balance"],tech,t,timestep)

             if tech.essentials.carrier_out == "electricity"
                 result_loc.df_el[t,tech.name] = result_conversion_plus[4]
                 result_loc.df_el[t,"electricity_balance"] = result_conversion_plus[1]
             else tech.essentials.carrier_out == "heat"
                 result_loc.df_th[t,tech.name] = result_conversion_plus[4]
                 result_loc.df_th[t,"heat_balance"] = result_conversion_plus[2]
             end

             if ismissing(tech.essentials.carrier_out_2)
             elseif tech.essentials.carrier_out_2 == "electricity"
                 result_loc.df_el[t,tech.name] = result_conversion_plus[5]
                 result_loc.df_el[t,"electricity_balance"] = result_conversion_plus[1]
             else tech.essentials.carrier_out_2 == "heat"
                 result_loc.df_th[t,tech.name] = result_conversion_plus[5]
                 result_loc.df_th[t,"heat_balance"] = result_conversion_plus[2]
             end

             # if ismissing(tech.essentials.carrier_out_3)
             # elseif tech.essentials.carrier_out_3 == "electricity"
             #     result_loc.df_el[t,[tech.name,tech.name*"_min", tech.name*"_max"]] = result_conversion_plus[]
             # else tech.essentials.carrier_out_3 == "heat"
             #     result_loc.df_th[t,[tech.name,tech.name*"_min", tech.name*"_max"]] = result_conversion_plus[]
             # end

             if tech.essentials.carrier_in == "electricity"
                 result_loc.df_el[t,tech.name] = result_conversion_plus[3]
                 result_loc.df_el[t,"electricity_balance"] = result_conversion_plus[1] #ADD
             elseif tech.essentials.carrier_in == "heat"
                 result_loc.df_th[t,tech.name] = result_conversion_plus[3]
                 result_loc.df_el[t,"electricity_balance"] = result_conversion_plus[2]#ADD
             elseif tech.essentials.carrier_in == "gas"
                 result_loc.df_gas[t,tech.name] = result_conversion_plus[3]#ADD
             else
                 result_loc.additional_carriers[t,tech.name] = result_conversion_plus[3] #ADD
             end

             # if ismissing(tech.essentials.carrier_in_2)
             # elseif tech.essentials.carrier_in_2 == "electricity"
             #     result_loc.df_el[t,[tech.name*"cons",tech.name*"cons_min", tech.name*"cons_max"]] = result_conversion[] #ADD
             # elseif tech.essentials.carrier_in_2 == "heat"
             #     result_loc.df_th[t,[tech.name*"cons",tech.name*"cons_min", tech.name*"cons_max"]] = result_conversion[]#ADD
             # elseif tech.essentials.carrier_in_2 == "gas"
             #     result_loc.df_gas[t,[tech.name*"cons",tech.name*"cons_min", tech.name*"cons_max"]] = result_conversion[]#ADD
             # else
             #     result_loc.additional_carriers[t,[tech.name*"cons",tech.name*"cons_min", tech.name*"cons_max"]] = result_conversion[] #ADD
             # end
             #
             # if ismissing(tech.essentials.carrier_in_3)
             # elseif tech.essentials.carrier_in_3 == "electricity"
             #     result_loc.df_el[t,[tech.name*"cons",tech.name*"cons_min", tech.name*"cons_max"]] = result_conversion[] #ADD
             # elseif tech.essentials.carrier_in_3 == "heat"
             #     result_loc.df_th[t,[tech.name*"cons",tech.name*"cons_min", tech.name*"cons_max"]] = result_conversion[]#ADD
             # elseif tech.essentials.carrier_in_3 == "gas"
             #     result_loc.df_gas[t,[tech.name*"cons",tech.name*"cons_min", tech.name*"cons_max"]] = result_conversion[]#ADD
             # else
             #     result_loc.additional_carriers[t,[tech.name*"cons",tech.name*"cons_min", tech.name*"cons_max"]] = result_conversion[] #ADD
             # end
         elseif tech.essentials.parent == "storage"

             if tech.essentials.carrier == "electricity"
                soc = 0.
                if t == 1
                    soc = 0.2 # initilize soc at t0 = 0
                else
                    soc = result_loc.df_el[t-1,"soc"]
                end
                result_storage = Parents.storage(result_loc.df_el[t,"electricity_balance"],soc, tech, t, timestep)
                result_loc.df_el[t,"electricity_balance"] = result_storage[1]
                result_loc.df_el[t,"battery"] = result_storage[2]
                result_loc.df_el[t,"soc"] = result_storage[3]
                # what to do with battery?
             else
                # other carriers to be implemented
             end

         end
     end
 end# solvelocations

 """
     solvenetwork!(system,res,res_net,t)

Given the system in analysis, the partial results obtained from the solvelocation! function, 
the structure of the results of the network and the time t in analysis,
it generates the results of the network solver for time t.

A summation of the electrical energy balances of the locations is done.
If > 0 energy sold to the grid, if <0 energy bought from the grid.
Energy exchanged in the local grid is the min between:
- summation of positive location energy imbalances
- summation of negative location energy imbalances

 """
 function solvenetwork!(system,res,res_net,t)

     # res are the partial results of the locations
     # res_net are the results of the network

     push!(res_net.df_el,  zeros(Float64,3))

     el_pos  = 0.
     el_neg  = 0.

     for loc in 1:length(system.nodes)
         if system.nodes[loc].techs == 0 || occursin("Industry",system.nodes[loc].name)
         else

             # electricity
             el_bal = res[loc].df_el.electricity_balance[t]
             res_net.df_el.balance[t]  = res_net.df_el.balance[t]  + el_bal
             if el_bal > 0.
                 el_pos = el_pos + el_bal
             else
                 el_neg = el_neg - el_bal
             end

         end
     end

     res_net.df_el.supply_grid[t] = - res_net.df_el.balance[t]
     res_net.df_el.exchanged[t]  = min(el_pos ,el_neg)

 end # solvenetwork

 """
     create_results_struct(system)

 Given the struct representing the system in analysis, it generates the initial dataframe of results for the following carriers:
     electricity
     heat
     gas
     additional carriers

 by using the column names obtained by the get_array_column_names().
 Each dataframe generated has a single line filled with 0.
 """
 function create_results_struct(system)
     x = length(system.nodes)
     result_df = Array{Results_locations,1}(undef,x)
     loc_num = 1
     for loc in system.nodes
         if system.nodes[loc_num].techs == 0 || occursin("Industry",system.nodes[loc_num].name)
             result_df[loc_num] = Results_locations()
             result_df[loc_num].name = system.nodes[loc_num].name
             loc_num += 1
         else
             col_names_el,col_names_th, col_names_gas, col_names_other = get_array_column_names(system.nodes[loc_num].techs)
             loc_df = Results_locations()
             loc_df.name =  system.nodes[loc_num].name
             df = DataFrame()
             for c in col_names_el
                 df[!, c] .= 0.0
             end
             push!(df,zeros(Float64,length(col_names_el)))
             loc_df.df_el = df
             #loc_df.el_balance = DataFrame(El = 0.0)
             df2 =  DataFrame()
             for c in col_names_th
                 df2[!,c] .= 0.0
             end
             push!(df2,zeros(Float64,length(col_names_th)))
             loc_df.df_th = df2
             #loc_df.th_balance = DataFrame(Th = 0.0)
             df3 =  DataFrame()
             for c in col_names_gas
                 df3[!,c] .= 0.0
             end
             push!(df3,zeros(Float64,length(col_names_gas)))
             loc_df.df_gas = df3
             #loc_df.gas_balance = DataFrame(Gas = 0.0)
             df4 =  DataFrame()
             if length(col_names_other) == 0

             else
                 for c in col_names_other
                     df4[!,c] .= 0.0
                 end
                 loc_df.additional_carriers = df4
             end
            push!(df4,zeros(Float64,length(col_names_other)))

             result_df[loc_num] = loc_df
             loc_num += 1
         end
     end
     return result_df
 end # create_results_struct

 """
     create_results_struct_net()

 It generates the preliminary struct of the network solver results ready to be filled in solvenetwork!

 """
 function create_results_struct_net()

     result_df_network = Results_networks()

     result_df_network.df_el  = DataFrame(balance = Float64[],supply_grid = Float64[],exchanged = Float64[])

     return result_df_network
 end # create_results_struct_network

 """
     get_length_arrays_column_names(techs)

 Given an array representing the technologies belonging to a location,
 and by using the length of the column of each result dataframe,
 it generates the arrays with the column names for each dataframe considered:

 electricity: column_names_el
 thermal: column_names_th
 gas: column_names_gas
 additional_carriers: column_names_other

 For each technology, its name and the min,max column are used.

 """
 function get_array_column_names(techs)
     if (techs == 0)
     else
         length_el, length_th, length_gas, length_other = get_length_arrays_column_names(techs)
         column_names_el = Array{Any,1}(undef,length_el)
         column_names_th = Array{Any,1}(undef,length_th)
         column_names_gas = Array{Any,1}(undef,length_gas)
         column_names_other = Array{Any,1}(undef,length_other)
         x = length(techs)
         y_el = 1
         y_th = 1
         y_gas = 1
         y_other = 1
         for i in 1:x
             if techs[i].essentials.parent == "demand"
                 #this if can be omitted if we consider carrier_out also for the demand
                 if techs[i].essentials.carrier == "electricity"
                     column_names_el[y_el] = techs[i].name
                     y_el += 1
                     column_names_el[y_el] = techs[i].essentials.carrier*"_balance"
                     y_el += 1
                 elseif techs[i].essentials.carrier == "heat"
                     column_names_th[y_th] = techs[i].name
                     y_th += 1
                     column_names_th[y_th] = techs[i].essentials.carrier*"_balance"
                     y_th += 1
                 end
             elseif techs[i].essentials.parent == "storage"
                 #this if can be omitted if we consider carrier_out also for storage
                 if techs[i].essentials.carrier == "electricity"
                    column_names_el[y_el] = "soc"
                    y_el += 1
                    column_names_el[y_el] = "battery"
                    y_el += 1
                 elseif techs[i].essentials.carrier == "heat"
                    column_names_th[y_th] = "soc"
                    y_th += 1
                    column_names_th[y_th] = "battery"
                    y_th += 1
                elseif techs[i].essentials.carrier == "gas"
                    column_names_gas[y_gas] = "soc"
                    y_gas += 1
                    column_names_gas[y_gas] = "battery"
                    y_gas += 1
                 end
             elseif techs[i].essentials.parent == "conversion"
                 if techs[i].essentials.carrier_in == "gas"
                     column_names_gas[y_gas] = techs[i].name
                     y_gas += 1
                 elseif techs[i].essentials.carrier_in == "electricity"
                     column_names_el[y_el] = techs[i].name
                     y_el += 1
                 else
                     column_names_other[y_other] = techs[i].name
                     y_other += 1
                 end
                 if techs[i].essentials.carrier_out == "electricity"
                     column_names_el[y_el] = techs[i].name
                     y_el += 1
                 end
                 if techs[i].essentials.carrier_out == "heat"
                     column_names_th[y_th] = techs[i].name
                     y_th += 1
                 else
                     column_names_other[y_other] = techs[i].name
                     y_other += 1
                 end
             elseif techs[i].essentials.parent == "conversion_plus"
                 if techs[i].essentials.carrier_in == "gas"
                     column_names_gas[y_gas] = techs[i].name
                     y_gas += 1
                 else
                     column_names_other[y_other] = techs[i].name
                     y_other += 1
                 end
                 if techs[i].essentials.carrier_out === "electricity" || techs[i].essentials.carrier_out_2 === "electricity" || techs[i].essentials.carrier_out_3 === "electricity"
                     column_names_el[y_el] = techs[i].name
                     y_el += 1
                 end
                 if techs[i].essentials.carrier_out === "heat" || techs[i].essentials.carrier_out_2 === "heat" || techs[i].essentials.carrier_out_3 === "heat"
                     column_names_th[y_th] = techs[i].name
                     y_th += 1
                 else
                     column_names_other[y_other] = techs[i].name
                     y_other += 1
                 end
             elseif techs[i].essentials.parent == "supply" 
                 if techs[i].essentials.carrier_out == "electricity"
                     column_names_el[y_el] = techs[i].name
                     y_el += 1
                 elseif techs[i].essentials.carrier_out == "heat"
                     column_names_th[y_th] = techs[i].name
                     y_th += 1
                 elseif techs[i].essentials.carrier_out == "gas"
                     column_names_gas[y_gas] = techs[i].name
                     y_gas += 1
                 else
                     column_names_other[y_other] = techs[i].name
                     y_other += 1
                 end
             elseif techs[i].essentials.parent == "supply_grid" 
                 if techs[i].essentials.carrier_out == "electricity"
                     column_names_el[y_el] = techs[i].name
                     y_el += 1
                 elseif techs[i].essentials.carrier_out == "heat"
                     column_names_th[y_th] = techs[i].name
                     y_th += 1
                 elseif techs[i].essentials.carrier_out == "gas"
                     column_names_gas[y_gas] = techs[i].name
                     y_gas += 1
                 else
                     column_names_other[y_other] = techs[i].name
                     y_other += 1
                 end
             else
                 #throw error
             end
         end
         column_names_gas[y_gas] = "gas_balance"
         return column_names_el,column_names_th, column_names_gas, column_names_other
     end
 end # get_array_column_names


 """
     get_length_arrays_column_names(techs)

 Given an array representing the technologies belonging to a location,
 it generates the number of columns of each result dataframe based on the carrier of the technologies
 in the form of array. Respective length for each carriers are used:
 electricity: length_el
 thermal: length_th
 gas: length_gas
 additional_carriers: length_other

 An additional number is added to each carrier to later represent the respective balance.
 The final number is multiplied by 3 to consider value,min,max used in the results dataframes.

 """

 function get_length_arrays_column_names(techs)
     length_el = 0
     length_th = 0
     length_gas = 0
     length_other = 0
     x = length(techs)

     for j in 1:x
         if techs[j].essentials.parent == "conversion"
             if ismissing(techs[j].essentials.carrier_in)
                 throw(NoCarrier("The technology ",techs[j].essentials.name," has no carrier_in defined"))
                 break
             elseif techs[j].essentials.carrier_in == "gas"
                 length_gas += 1
             elseif techs[j].essentials.carrier_in == "electricity"
                 length_el += 1
             else
                 length_other += 1
             end
             if ismissing(techs[j].essentials.carrier_out)
                 throw(NoCarrier("The technology ",techs[j].essentials.name," has no carrier_out defined"))
                 break
             elseif techs[j].essentials.carrier_out == "electricity"
                 length_el += 1
             end
             if techs[j].essentials.carrier_out == "heat"
                 length_th += 1
             else
                 length_other += 1
             end
         elseif techs[j].essentials.parent == "conversion_plus" #In future check for carriers_out
             if ismissing(techs[j].essentials.carrier_in)
                 throw(NoCarrier("The technology ",techs[j].essentials.name," has no carrier_in defined"))
                 break
             elseif techs[j].essentials.carrier_in == "gas"
                 length_gas += 1
             else
                 length_other += 1
             end
             if ismissing(techs[j].essentials.carrier_out)
                 throw(NoCarrier("The technology ",techs[j].essentials.name," has no carrier_out defined"))
                 break
             elseif techs[j].essentials.carrier_out === "electricity" ||  techs[j].essentials.carrier_out_2 === "electricity" || techs[j].essentials.carrier_out_3 === "electricity"
                 length_el += 1
             end
             if techs[j].essentials.carrier_out === "heat" ||  techs[j].essentials.carrier_out_2 === "heat" || techs[j].essentials.carrier_out_3 === "heat"
                 length_th += 1
             else
                 length_other += 1
             end
         elseif techs[j].essentials.parent == "demand"
             if techs[j].essentials.carrier == "electricity"
                 length_el += 1
             elseif techs[j].essentials.carrier == "heat"
                 length_th += 1
             elseif techs[j].essentials.carrier == "gas"
                 length_gas += 1
             else
                 length_other += 1
             end
         elseif techs[j].essentials.parent == "supply"
             if techs[j].essentials.carrier_out == "electricity"
                 length_el += 1
             elseif techs[j].essentials.carrier_out == "heat"
                 length_th += 1
             elseif techs[j].essentials.carrier_out == "gas"
                 length_gas += 1
             else
                 length_other += 1
             end
         elseif techs[j].essentials.parent == "storage"
             if techs[j].essentials.carrier == "electricity"
                 length_el += 2
             elseif techs[j].essentials.carrier == "heat"
                 length_th += 2
             elseif techs[j].essentials.carrier == "gas"
                 length_gas += 2
             else
                 length_other += 2
             end
         elseif techs[j].essentials.parent == "supply_grid"
             if techs[j].essentials.carrier_out == "electricity"
                 length_el += 1
             elseif techs[j].essentials.carrier_out == "heat"
                 length_th += 1
             elseif techs[j].essentials.carrier_out == "gas"
                 length_gas += 1
             else
                 length_other += 1
             end
         else
            # ADD ERROR wrong parent
         end
     end


     if length_el > 1
         length_el += 1
     end
     if length_th > 1
         length_th += 1
     end
     
     length_gas += 1
     
     return length_el, length_th, length_gas, length_other
    
 end # get_length_arrays_column_names

 """
 process_raw_results(sys_solution)
 
     Given a struct System_results representing the results coming from the core, 
     it process the results of each location to add information regarding import and export.
     The resulting struct is ready to be used to plot timeseries results of each location.
 """
 function process_raw_results(sys_solution)
     sol = deepcopy(sys_solution)
     for i in 1:length(sol.nodes)
         process_location_result!(sol.nodes[i])
     end
     return sol
 end
 
 """
 process_location_result!(loc)
 
     Given a struct Result_locations with the results of a specific location,
     it process it to obtain all relevant information needed to plot the results.
 
     Firstly it removes the extra columns not needed, then it add columns for import and export,
     it assign to these columns the correspondent values and remove the columns that have all zeros.
 """
 function process_location_result!(loc)
     for i in fieldnames(typeof(loc))
         if String(i) == "name"
         elseif ismissing(getfield(loc,i))
         elseif String(i) == "df_el"
             df = getfield(loc,i)
             add_import_export_columns!(df)
             reprocess_results_data!(df, String(i))
             remove_zeros_columns!(df)
             setproperty!(loc,i,df)
         else
             df = getfield(loc,i)
             add_excess_columns!(df)
             reprocess_results_data!(df, String(i))
             remove_zeros_columns!(df)
             setproperty!(loc,i,df)           
         end
     end
 end
 
 
 
 """
 add_import_export_columns!(df)
 
     Given a dataframe representing the results of a location with no min/max columns,
     it insert a import column and an "export_techname" column for each technology.
         
     e.g. if columns are ["demand", "pv","boiler"] it returns a dataframe with the following columns:
     ["demand", "pv","boiler","import","pv_export","boiler_export"]
 """
 function add_import_export_columns!(df)
     n_col = ncol(df)
     j = 1
     insertcols!(df, n_col+j, :import => zeros(Float64,nrow(df)))
     j += 1
     for i in names(df)
         if occursin("demand",i) || occursin("balance",i) || occursin("import",i) || occursin("soc",i) || occursin("battery",i)
         else
 
             name = "export_"*i
             insertcols!(df, n_col+2, Symbol(name) => zeros(Float64,nrow(df)))
             j += 1
         end
     end
     return df
 end
 
 """
 add_excess_columns!(df)
 
     Given a dataframe representing the results of a location with no min/max columns,
     it insert a import column and an "export_techname" column for each technology.
         
     e.g. if columns are ["demand","chp"] it returns a dataframe with the following columns:
     ["demand", "pv","chp_excess"]
 """
 function add_excess_columns!(df)
     n_col = ncol(df)
     j = 1
     insertcols!(df, n_col+j, :import => zeros(Float64,nrow(df)))
     j += 1
     for i in names(df)
         if occursin("demand",i) || occursin("balance",i) || occursin("import",i) || occursin("soc",i) || occursin("battery",i)
         else
 
             name = "excess_"*i
             insertcols!(df, n_col+2, Symbol(name) => zeros(Float64,nrow(df)))
             j += 1
         end
     end
     return df
 end
 """
 reprocess_results_data!(df)
 
     Given a dataframe with the results of a location that has already passed through
     remove_extra_columns() and add_import_export_columns() functions and the df bane ,
     it processes the results to assign to the newly created columns (import/export) the respective
     values if it is a df for electricity otherwise it assigne results to the excess columns.
 
     The post process is made by cheching the balance, the demand and the produced energy of each technology.
 """
 function reprocess_results_data!(df, df_name)
     demand = zeros(Float64,nrow(df))
     balance = zeros(Float64,nrow(df))
     for i in names(df)
         if occursin("balance",i)
             balance = df[!,i]
             select!(df, Not(i))
         elseif occursin("soc",i)
             select!(df, Not(i))
         end
     end
     if df_name == "df_el"
         for t in 1:nrow(df)
             dem = 0
             if balance[t] > 0.
                 for i in names(df)
                     if occursin("demand",i)
                         dem = df[t,i]
                     
                     elseif occursin("export",i) || occursin("import",i) || occursin("battery",i)
                     else
                         if df[t,i] > -dem
                             exp = "export_"*i
                             df[t,exp] = df[t,i]+dem
                             df[t,i] = -dem
                             dem = 0
                         end
                     end
                 end
             elseif balance[t] ≤ 0.
                 df[t,"import"] = -balance[t]
             end
         end
     else
         for t in 1:nrow(df)
             dem = 0
             if balance[t] > 0.
                 for i in names(df)
                     if occursin("demand",i)
                         dem = df[t,i]
                     
                     elseif occursin("excess",i) || occursin("import",i) || occursin("battery",i)
                     else
                         if df[t,i] > -dem
                             exp = "excess_"*i
                             df[t,exp] = df[t,i]+dem
                             df[t,i] = -dem
                             dem = 0
                         end
                     end
                 end
             elseif balance[t] ≤ 0.
                 df[t,"import"] = -balance[t]
             end
         end  
     end     
     return df
 end
 
 """
 remove_zeros_columns!(df)
 
     Given a post_processed dataframe that already passed through reprocess_results_data(),
     it remove all columns with all zeros.
 """
 function remove_zeros_columns!(df)
     for i in names(df)
         if count(x->x==0., df[!,i]) == nrow(df)
             select!(df, Not(Symbol(i)))
         end
     end
     return df
 end
 
 """
 save_results_to_CSV(solution)
 
     Save results to CSV (old)
 """
 function save_results_to_CSV(solution,type_sol,scenario)
 
     mkpath((joinpath(path, "..", "results")))
 
     sol = solution.nodes
     for i in 1:length(sol)
         name = sol[i].name*"_"
         for j in fieldnames(Results_locations)
             res = getfield(sol[i],Symbol(j))
             if String(j) == "name"
             elseif ismissing(res)
             else
                 filename = string(type_sol, "_results_", name, j,"_",scenario, ".csv")
                 touch(joinpath(path, "..", "results",filename))
                 CSV.write(joinpath(path, "..", "results",filename),res)
             end
         end
     end
 
     sol_network = solution.network
     for k in fieldnames(Results_networks)
         res_network = getfield(sol_network,Symbol(k))
         if ismissing(res_network)
         else
             filename = string(type_sol, "_net_results_", k,"_",scenario, ".csv")
             touch(joinpath(path,"..","results",filename))
             CSV.write(joinpath(path,"..","results",filename),res_network)
         end
     end
 end


end