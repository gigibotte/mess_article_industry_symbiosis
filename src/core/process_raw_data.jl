module ProcessRawData

using DataFrames,CSV
using Main.SystemStructMess
using Main.Dirs: path

export process_raw_results
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
        if occursin("demand",i) || occursin("balance",i) || occursin("import",i) || occursin("soc",i) || occursin("delta_battery",i)
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
        if occursin("demand",i) || occursin("balance",i) || occursin("import",i) || occursin("soc",i) || occursin("delta_battery",i)
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
                    
                    elseif occursin("export",i) || occursin("import",i) || occursin("delta_battery",i)
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
                    
                    elseif occursin("excess",i) || occursin("import",i) || occursin("delta_battery",i)
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
function save_results_to_CSV(solution)

    mkpath((joinpath(path, "..", "results")))

    sol = solution.nodes
    for i in 1:length(sol)
        name = sol[i].name*"_"
        for j in fieldnames(Results_locations)
            res = getfield(sol[i],Symbol(j))
            if String(j) == "name"
            elseif ismissing(res)
            else
                touch(joinpath(path, "..", "results","results_$name$j.csv"))
                CSV.write(joinpath(path, "..", "results","results_$name$j.csv"),res)
            end
        end
    end

    sol_network = solution.network
    for k in fieldnames(Results_networks)
        res_network = getfield(sol_network,Symbol(k))
        if ismissing(res_network)
        else
            touch(joinpath(path,"..","results","results_network_$k.csv"))
            CSV.write(joinpath(path,"..","results","results_network_$k.csv"),res_network)
        end
    end
end

end  # module ProcessRawData
