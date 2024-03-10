module PlottingHourlyResults

using PlotlyJS, DataFrames
using Main.SystemStructMess
using Main.Dirs: path

export plot_hourly_results

function plot_hourly_results(system,system_solution,scenario)
    locations_techs = get_techs_color_priority_per_location(system)
    nodes = system_solution.nodes
    for i in 1:length(nodes)
        for j in 1:length(locations_techs)
             if nodes[i].name == locations_techs[j].name
                  plot_hourly_bar_charts(nodes[i],locations_techs[j],scenario)
             end
        end
    end
end

function get_techs_color_priority_per_location(sys)
    x = length(sys.nodes)
    locations = Array{Location_post,1}(undef,x)
    for i in 1:x
        if sys.nodes[i].techs == 0
            locations[i] = Location_post(sys.nodes[i].name,0)
        else
            y = length(sys.nodes[i].techs)
            loc_techs = Array{Tech_post,1}(undef,y)
            for j in 1:y
                loc_techs[j] = Tech_post(sys.nodes[i].techs[j].name,sys.nodes[i].techs[j].essentials.color,sys.nodes[i].techs[j].priority)
            end
            locations[i] = Location_post(sys.nodes[i].name, loc_techs)
        end
    end
    return locations
end

function plot_hourly_bar_charts(result_loc, loc_post,scenario)
    name = loc_post.name*"_"
    k = 1
    for i in fieldnames(typeof(result_loc))
        if typeof(getfield(result_loc,i)) == String ||  ismissing(getfield(result_loc,i))
        else
            # Generate Data for plotting
            data_test = generate_data_bar_charts(getfield(result_loc,i),loc_post)
            layout = Layout(;xaxis_title="hours",yaxis_title="energy [kWh]",
                             barmode="relative")
            # Generate Plot
            p =  plot(data_test,layout)
            if isnothing(p)
            else
                df_name = ""
                if k == 1
                    df_name = "el"
                elseif k == 2
                    df_name = "th"
                elseif k == 3
                    df_name = "gas"
                end
                savefig(p, joinpath(path, "..", "plots","results_$name$df_name$scenario.html"))
                k += 1
            end


        end
    end
end


function generate_data_bar_charts(df,location)
    data = Array{GenericTrace,1}(undef,0)
    for i in names(df)
        color_attr =  get_color_attr(df,i,location)
        if occursin("demand",i)
            trace = scatter(;x = range(1,nrow(df), step = 1),
                             y = -df[!,Symbol(i)],
                             mode = "lines",
                             name = i,
                             marker=attr(color=color_attr))
        elseif occursin("export",i)
            trace = bar(;x = range(1,nrow(df), step = 1),
                         y = -df[!,Symbol(i)],
                         name = i,
                         marker=attr(color=color_attr))
        else
            trace = bar(;x = range(1,nrow(df), step = 1),
                         y = df[!,Symbol(i)],
                         name = i,
                         marker=attr(color=color_attr))
        end
        push!(data, trace)
    end
    return data
end


function get_color_attr(df,col_name,location)
    color_attr = ""
    for i in 1:length(location.techs)
        if col_name == location.techs[i].name
            color_attr = location.techs[i].color
        elseif occursin("import",col_name)
            color_attr = "#B0B0B0"
        elseif occursin("export",col_name)
            tech = split(col_name,"_")[2]
            if tech == location.techs[i].name
                color_attr = location.techs[i].color*"80"
            end
        end
    end
    return color_attr
end

end  # module PlottingHourlyResults
