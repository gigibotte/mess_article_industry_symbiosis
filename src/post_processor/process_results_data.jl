module ProcessResultsData

using Main.SystemStructMess
using DataFrames

export generate_overall_data_results

"""
generate_overall_data_results(system_solution)

    Given a struct System_results representing post_processed results,
    it returns an array with the aggregated results of the system for electricity and heat.
"""
function generate_overall_data_results(system_solution)
    nodes = system_solution.nodes
    tot_el, tot_th = gather_overall_results(nodes)
    col_el = gather_overall_columns(tot_el)
    col_th = gather_overall_columns(tot_th)
    overall_el = generate_overall_df(tot_el,col_el)
    overall_th = generate_overall_df(tot_th,col_th)
    array_results = [overall_el,overall_th]
    return array_results
end

"""
gather_overall_results(nodes)

    Given a Results_locations struct representing the post process solution,
    it calls the get_total_results() function to generate two arrays - one for electricity 
    and one for heat - representing the aggregated results for each location as a dataframe.
    
"""
function gather_overall_results(nodes)
    array_df_el = Array{DataFrame,1}(undef,0)
    array_df_th = Array{DataFrame,1}(undef,0)
    for i in 1:length(nodes)
        loc_res = nodes[i]
        for k in fieldnames(typeof(loc_res))
            if k == Symbol("name")
            elseif ismissing(getfield(loc_res,k))
            elseif k == Symbol("df_el")
                df = get_total_results(getfield(loc_res,k))
                push!(array_df_el,df)
            elseif k == Symbol("df_th")
                df = get_total_results(getfield(loc_res,k))
                push!(array_df_th,df)
            else
            end
        end
    end
    return array_df_el, array_df_th
end

"""
get_total_results(df)

    Given a dataframe of results it generates a dataframe with the aggregated results.
    Meaning that the sum over all the timestep is calculated and then it's divided by the 
    demand to obtain the percentage of the demand that is covered by each technology.

    The resulting dataframe has not the demand column.
"""
function get_total_results(df)
    sum_total = [round(sum(df[!,i]),digits = 2) for i in names(df)]

    res =  DataFrame()
    for i in names(df)
        res[!,i] .= 0.
    end
    push!(res,sum_total)
    dem = 0
    dem_name = ""
    for i in names(res)
        if occursin("demand",i)
            dem = -res[1,i]
            dem_name = i
        elseif occursin("export",i)
            res[1,i] = round((-res[1,i]/dem)*100,digits =2)
        else
            res[1,i] = round((res[1,i]/dem)*100,digits =2)
        end
    end
    select!(res, Not(dem_name))
    return res
end

"""
gather_overall_columns(array_df)

    Given an array of dataframes representing the aggregated results of each location,
    it gets the overall column names across all the dataframes and return an array
    with all these column names.
"""
function gather_overall_columns(array_df)
    col_names = Array{String,1}(undef,0)
    for i in 1:length(array_df)
        cols_df = names(array_df[i])
        for j in cols_df
            if j in col_names
            else
                push!(col_names,j)
            end
        end
    end
    return col_names
end

"""
generate_overall_df(array_df,col_names)

    Given an array of dataframes representing the aggregated results of each location
    and an array of with all the column names across the dataframes it generates a single
    dataframe with all the results of the locations.
"""
function generate_overall_df(array_df, col_name)
    df = DataFrame()
    for i in col_name
        df[!,i] .= 0.
    end
    for i in 1:length(array_df)
         push!(df,zeros(Float64,length(col_name)))
         tmp_df = array_df[i]
         for j in names(tmp_df)
             df[i,j] = tmp_df[1,j]
         end
    end
    return df
end


end  # module ProcessResultsData
