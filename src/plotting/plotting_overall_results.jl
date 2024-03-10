module PlottingOverallResults

using Main.ProcessYaml, Main.SystemStructMess
using Main.Dirs: path

using DataFrames, PlotlyJS, YAML


export plot_overall_results

function plot_overall_results(system,array_results,scenario)
    overall_post_techs = get_techs_color_priority_overall_system(scenario)
    list_locations = get_list_locations(system.nodes)
    for i in 1:length(array_results)
        name = ""
        if i == 1
            name = "Electricity"
        else
            name = "Heat"
        end
        plot_overall_bar_charts(array_results[i],overall_post_techs,name, list_locations,scenario)
    end
end

function get_techs_color_priority_overall_system(scenario)
    preliminary_technologies = YAML.load(open(joinpath(path, "..", "data", "data_mess", "techs_$scenario.yaml")))
    techs = ProcessYaml.get_techs_techgroups(preliminary_technologies)[1]
    tech_res = ProcessYaml.create_struct_tech(techs)
    overall_post_techs = pre_to_post_vector_techs(tech_res)
    return overall_post_techs
end

function pre_to_post_vector_techs(tech_pre)
    techs = Array{Tech_post,1}(undef,length(tech_pre))
    for i in 1:length(tech_pre)
        if isnothing(tech_pre[i].priority)
            techs[i] = Tech_post(tech_pre[i].name,tech_pre[i].essentials.color,0)
        else
            techs[i] = Tech_post(tech_pre[i].name,tech_pre[i].essentials.color,tech_pre[i].priority)
        end
    end
    return techs
end

function get_list_locations(locations)
    list_locations = Array{String,1}(undef,0)
    for i in 1:length(locations)
        if locations[i].techs == 0
        else
            push!(list_locations,locations[i].name)
        end
    end
    return list_locations
end



function plot_overall_bar_charts(results,attr_array,name,list_location,scenario)
    data = generate_data_total_chart(results,attr_array,list_location)
    layout = Layout(;xaxis_title = "Locations",
                     yaxis_title = "%",
                     title = name*" Production",
                     barmode = "relative")
    p = plot(data,layout)
    if isnothing(p)
    else
        filename = name*"_"*scenario
        savefig(p, joinpath(path, "..", "plots","overall_results_$filename.html"))
        savefig(p, joinpath(path, "..", "plots","overall_results_$filename.jpeg"))
    end
end

function generate_data_total_chart(df,attr_tech, list_location)
    data = Array{GenericTrace,1}(undef,0)

    for i in names(df)
        color_attr =  get_color_attr_overall(df,i,attr_tech)
        trace = bar(;x = list_location,
                     y = df[!,Symbol(i)],
                     marker=attr(color=color_attr),
                     name = i)
        push!(data, trace)
    end
    return data
end


function get_color_attr_overall(df,col_name,system_attr)
    color_attr = ""
    for i in 1:length(system_attr)
        for i in 1:length(system_attr)
            if col_name == system_attr[i].name
                color_attr = system_attr[i].color
            elseif occursin("import",col_name)
                color_attr = "#B0B0B0"
            elseif occursin("export",col_name)
                tech = split(col_name,"_")[2]
                if tech == system_attr[i].name
                    color_attr = system_attr[i].color*"80"
                end
            end
        end
    end
    return color_attr
end

end  # module PlottingOverallResults
