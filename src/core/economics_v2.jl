module Economicsv2

export build_economic_solution

using Main.SystemStructMess

using Main.ModelConfiguration: timestep, timespan

using Main.Dirs: path

using DataFrames, CSV



function build_economic_solution(sys_results::System_results,sys::System,techs)
    # create a copy of the original System_results object
    economic_solution = deepcopy(sys_results)
    # loop through each Results_locations object and add the economic solution to it
    i=1
    for node in economic_solution.nodes
        # add economic solution for electricity
        if !ismissing(node.df_el)
            node.df_el = get_economic_solution(node.df_el,sys.nodes[i],techs,"electricity")
        end
        
        # add economic solution for thermal energy
        if !ismissing(node.df_th)
            node.df_th = get_economic_solution(node.df_th,sys.nodes[i],techs,"heat")
        end
        
        # add economic solution for gas
        if !ismissing(node.df_gas)
            node.df_gas = get_economic_solution(node.df_gas,sys.nodes[i],techs,"gas")
        end
        
        # add additional carriers economic solutions
        if !ismissing(node.additional_carriers)
            for carrier in node.additional_carriers
                carrier = get_economic_solution(carrier,sys.nodes[i],techs)
            end
        end
        i+=1
    end

    #add economic solution for the network
    economic_solution.network = get_economic_solution_network(economic_solution.network,techs)

    return economic_solution
end


function get_economic_solution(df,sys_node,techs,carrier)
    for col in names(df)
        j=0
        for tech in sys_node.techs
            if col == tech.name
                if tech.essentials.parent == "conversion" 
                    print(tech.essentials.name,"   -   ",carrier,"\n")
                    if tech.essentials.carrier_in == carrier
                        df_price = 0.
                        df[!,col] = df[!,col] .* 0.
                    elseif tech.essentials.carrier_out == carrier
                        df_price = 0.
                        df[!,col] = df[!,col] .* 0.
                    else
                        if isa(tech.costs.monetary.om_prod,DataFrame)
                            df_price = tech.costs.monetary.om_prod
                            df[!,col] = df[!,col] .* convert.(eltype(df[!,col]), df_price[!,"Prices"])
                        else
                            om_cost = tech.costs.monetary.om_prod
                            df[!,col] = df[!,col] * om_cost 
                        end
                    end 
                elseif tech.essentials.parent == "supply" 
                    if isa(tech.costs.monetary.om_con,DataFrame)
                        df_price = tech.costs.monetary.om_con
                        df[!,col] = df[!,col] .* convert.(eltype(df[!,col]), df_price[!,"Prices"])
                    else
                        om_cost = tech.costs.monetary.om_con
                        df[!,col] = df[!,col] * om_cost 
                    end
                elseif tech.essentials.parent == "conversion_plus"      
                    if isa(tech.costs.monetary.om_prod,DataFrame)
                        df_price = tech.costs.monetary.om_con
                        df[!,col] = df[!,col] .* convert.(eltype(df[!,col]), df_price[!,"Prices"])
                    else
                        om_cost = tech.costs.monetary.om_prod
                        df[!,col] = df[!,col] * om_cost 
                    end
                elseif tech.essentials.parent == "storage" 
                    if isa(tech.costs.monetary.om_prod,DataFrame)
                        df_price = tech.costs.monetary.om_prod
                        df[!,col] = df[!,col] .* convert.(eltype(df[!,col]), df_price[!,"Prices"])
                    else
                        om_cost = tech.costs.monetary.om_prod
                        df[!,col] = df[!,col] * om_cost 
                    end
                elseif tech.essentials.parent == "demand"
                    om_cost = 0  
                    df[!,col] = df[!,col] * om_cost 
                end  
            
            elseif occursin("import",col)
                if j==0
                    if typeof(techs["supply_grid_power"]["costs"]["monetary"]["om_con"]) == Int64
                        df[!,col] = df[!,col] .* techs["supply_grid_power"]["costs"]["monetary"]["om_con"]
                        j=1
                        break
                    elseif occursin("file=",techs["supply_grid_power"]["costs"]["monetary"]["om_con"])
                        filename = split(techs["supply_grid_power"]["costs"]["monetary"]["om_con"],"=")[2]
                        df_price = CSV.read(joinpath(path, "..", "data","timeseries_data",filename),DataFrame)
                        df[!,col] = df[!,col] .* convert.(eltype(df[!,col]), df_price[!,"Prices"])
                        j=1
                        break
                    else
                        df[!,col] = df[!,col] .* techs["supply_grid_power"]["costs"]["monetary"]["om_con"]
                        j=1
                        break
                    end  
                end
            elseif occursin("export",col)
                om_cost = 0  
                df[!,col] = df[!,col] * om_cost 
            end
        end
    end
    
    return df

end

function get_economic_solution_network(net::Results_networks, techs::Dict{Any, Any})
  
    for col in names(net.df_el)
        if col == "supply_grid"
            if typeof(techs["supply_grid_power"]["costs"]["monetary"]["om_con"]) == Int64
                net.df_el[!,col] = net.df_el[!,col] * techs["supply_grid_power"]["costs"]["monetary"]["om_con"]
            elseif occursin("file=",techs["supply_grid_power"]["costs"]["monetary"]["om_con"])
                filename = split(techs["supply_grid_power"]["costs"]["monetary"]["om_con"],"=")[2]
                timeseries_df = CSV.read(joinpath(path, "..", "data","timeseries_data",filename),DataFrame)
                net.df_el[!,col] = net.df_el[!,col] .* convert.(eltype(net.df_el[!,col]), timeseries_df[!,"Prices"])
            else
                net.df_el[!,col] = net.df_el[!,col] * techs["supply_grid_power"]["costs"]["monetary"]["om_con"]
            end
        else
        end
    end
    
   
    return net
end





end